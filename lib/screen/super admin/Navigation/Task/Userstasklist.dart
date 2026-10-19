import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/my work/Task status tab/allgoals.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class UsersTasklist extends StatefulWidget {
  const UsersTasklist({super.key});

  @override
  State<UsersTasklist> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<UsersTasklist> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  final TaskFilterModel filter = TaskFilterModel();
  final SuperAdminService _departmentService = SuperAdminService();

  String goalType = 'All';
  List<String> departments = [];
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final names = <String>{};
    try {
      final data = await _departmentService.getDepartments();
      for (final item in data) {
        final name = item.departmentName.trim();
        if (name.isNotEmpty) names.add(name);
      }
    } catch (e) {
      debugPrint('Failed to load departments: $e');
    }
    try {
      final users = await SuperAdminService.getAllUsers();
      for (final user in users) {
        final name = user.department.trim();
        if (name.isNotEmpty) names.add(name);
      }
    } catch (e) {
      debugPrint('Failed to load user departments: $e');
    }
    if (!mounted) return;
    setState(() {
      departments = names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  void _pickGoalType(String value) {
    setState(() => goalType = value);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !AppLayout.isMobile(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isWeb ? WebTheme.canvasOf(context) : null,
      endDrawer: _filterDrawer(context),
      appBar: isWeb
          ? null
          : AppBar(
              title: const Text('Company goal and task list'),
            ),
      body: Padding(
        padding: isWeb ? AppLayout.pagePadding(context) : const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWeb)
                  Text(
                    'Company goal and task list',
                    style: TextStyle(
                      fontSize: AppLayout.isDesktop(context) ? 22 : 18,
                      fontWeight: FontWeight.w800,
                      color: WebTheme.inkOf(context),
                    ),
                  ),
                if (isWeb) const SizedBox(height: 12),
                _searchRow(context),
                const SizedBox(height: 12),
                Expanded(
                  child: Allgoals(
                    searchQuery: searchController.text,
                    filter: filter,
                    goalType: goalType,
                    showLooseTasks: true,
                    onDelete: (msg, isError) {
                      showTopMessage(msg, isError: isError);
                    },
                  ),
                ),
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 8 : -120,
                left: 0,
                right: 0,
                duration: const Duration(milliseconds: 300),
                child: Msgsnackbar(
                  context,
                  message: _topMessage!,
                  isError: _isErrorMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _searchRow(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search goals and tasks',
        hintStyle: TextStyle(fontSize: 13, color: WebTheme.mutedOf(context)),
        prefixIcon: Icon(Icons.search, size: 18, color: WebTheme.mutedOf(context)),
        suffixIcon: IconButton(
          tooltip: 'Filter',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: Badge(
            isLabelVisible:
                goalType != 'All' ||
                (filter.department != null && filter.department!.isNotEmpty),
            smallSize: 8,
            child: Icon(Icons.filter_list, color: WebTheme.brand),
          ),
        ),
        filled: true,
        fillColor: WebTheme.surfaceOf(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: WebTheme.brand),
        ),
      ),
    );
  }

  Widget _filterDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: WebTheme.surfaceOf(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            for (final option in const ['All', 'Yearly', 'Monthly'])
              ListTile(
                leading: Icon(
                  goalType == option
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: WebTheme.brand,
                ),
                title: Text(
                  option == 'All'
                      ? 'All'
                      : option == 'Yearly'
                      ? 'Yearly goals'
                      : 'Monthly goals',
                ),
                selected: goalType == option,
                onTap: () => _pickGoalType(option),
              ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Department',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.inkOf(context),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      filter.department == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: WebTheme.brand,
                    ),
                    title: const Text('All departments'),
                    selected: filter.department == null,
                    onTap: () => setState(() => filter.department = null),
                  ),
                  for (final name in departments)
                    ListTile(
                      leading: Icon(
                        filter.department == name
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: WebTheme.brand,
                      ),
                      title: Text(name),
                      selected: filter.department == name,
                      onTap: () => setState(() => filter.department = name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
