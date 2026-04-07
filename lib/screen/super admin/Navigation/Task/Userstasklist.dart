import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/my work/Task status tab/allgoals.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class UsersTasklist extends StatefulWidget {
  const UsersTasklist({super.key});

  @override
  State<UsersTasklist> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<UsersTasklist> {
  bool isSearching = false;
  bool showFilter = false;

  final TextEditingController searchController = TextEditingController();
  final SuperAdminService _departmentService = SuperAdminService();

  TaskFilterModel filter = TaskFilterModel();

  List<String> departments = [];

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
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

  void _fetchDepartments() async {
    try {
      final data = await _departmentService.getDepartments();

      setState(() {
        departments = data
            .map<String>((d) => d.departmentName.toString())
            .toList();
      });
    } catch (e) {
      debugPrint("Failed to load departments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search goals...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() {}),
              )
            : const Text("All Users Goals"),

        actions: [
          /// SEARCH BUTTON
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
              });
            },
          ),

          /// FILTER BUTTON
          IconButton(
            icon: Icon(showFilter ? Icons.close : Icons.filter_list),
            onPressed: () {
              setState(() {
                showFilter = !showFilter;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              /// FILTER DROPDOWN
              if (showFilter) ...[
                TaskFilterDropdown(
                  filter: filter,
                  departments: departments,
                  onApply: () {
                    setState(() {
                      showFilter = false;
                    });
                  },
                  onClear: () {
                    filter.clear();
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
              ],

              /// GOALS SECTION
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Allgoals(
                          searchQuery: searchController.text,
                          filter: filter,
                          onDelete: (msg, isError) {
                            showTopMessage(msg, isError: isError);
                            _fetchDepartments();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 40 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
              ),
            ),
        ],
      ),
    );
  }
}
