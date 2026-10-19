import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/allgoals.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/completedtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/pendingtask.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/progresstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class Mywork extends StatefulWidget {
  const Mywork({super.key});

  @override
  State<Mywork> createState() => _MyworkState();
}

class _MyworkState extends State<Mywork> {
  int _goalsRefreshKey = 0;
  final Map<String, String> _taskStatus = {};
  int? adminId;
  bool isLoading = true;
  bool isSearching = false;
  bool _filterOpen = false;
  String _goalType = "All";
  final TextEditingController searchController = TextEditingController();
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadAdminId();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAdminId() async {
    try {
      final id = await getAdminIdFromToken();

      if (!mounted) return;

      setState(() {
        adminId = id;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<int> getAdminIdFromToken() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final decodedToken = JwtDecoder.decode(token);

    return int.parse(decodedToken['UserId'].toString());
  }

  Widget _goalTypeChip(String label) {
    final selected = _goalType == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? WebTheme.brand : WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _goalType = label;
            _filterOpen = false;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? WebTheme.brand : WebTheme.lineOf(context),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : WebTheme.brandOf(context),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _taskCode(Map task) {
    return (task['taskCode'] ?? task['TaskCode'] ?? '').toString();
  }

  String _statusOf(Map task) {
    final saved = _taskStatus[_taskCode(task)];
    if (saved != null && saved.isNotEmpty) return saved;
    if (adminId == null) return '';
    return AppHelpers.normalize(viewerTaskStatus(task, adminId!));
  }

  Future<void> _onTaskStatus(Map<String, dynamic> task) async {
    final code = _taskCode(task);
    if (code.isEmpty || adminId == null) return;
    setState(() {
      _taskStatus[code] = AppHelpers.normalize(viewerTaskStatus(task, adminId!));
    });
  }

  void showTopMessage(String message, {bool isError = true}) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading || adminId == null) {
      return const Center(child: RotatingFlower());
    }

    if (AppLayout.isMobile(context)) {
      return _mobilePage();
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.lineOf(context)),
    );

    return Stack(
      children: [
        Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'My Works',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: WebTheme.inkOf(context),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await openFormPage(
                        context,
                        Createtask(assignedToIds: [adminId!]),
                        maxWidth: 880,
                      );
                      if (result == true && mounted) {
                        setState(() => _goalsRefreshKey++);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Goal/Task'),
                    style: FilledButton.styleFrom(
                      backgroundColor: WebTheme.brand,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _goalTypeChip('All'),
                          _goalTypeChip('Yearly'),
                          _goalTypeChip('Monthly'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: WebTheme.mutedOf(context),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: WebTheme.mutedOf(context),
                        ),
                        filled: true,
                        fillColor: WebTheme.surfaceOf(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: BorderSide(color: WebTheme.brandOf(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _WorkBoard(
                  key: ValueKey(_goalsRefreshKey),
                  adminId: adminId!,
                  goalType: _goalType,
                  searchQuery: searchController.text,
                  statusOf: _statusOf,
                  onTaskStatus: _onTaskStatus,
                  onDelete: (msg, isError) {
                    showTopMessage(msg, isError: isError);
                  },
                ),
              ),
            ],
          ),
        ),
        if (_topMessage != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showTopMessage ? 8 : -120,
            left: 16,
            right: 16,
            child: Msgsnackbar(
              context,
              message: _topMessage!,
              isError: _isErrorMessage,
            ),
          ),
      ],
    );
  }

  Widget _mobilePage() {
    return DefaultTabController(
      length: 4,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondary,
                child: SafeArea(
                  bottom: false,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    indicatorColor: Colors.white,
                    dividerColor: Colors.white24,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.78),
                    labelStyle: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                    unselectedLabelStyle: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.12),
                    ),
                    tabs: const [
                      Tab(text: 'ALL'),
                      Tab(text: 'Pending/Pause'),
                      Tab(text: 'In Process'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: isSearching
                                    ? TextField(
                                        controller: searchController,
                                        decoration: const InputDecoration(
                                          hintText: "Search Goal",
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      )
                                    : Text(
                                        "My Goals",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.displaySmall,
                                      ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  isSearching ? Icons.close : Icons.search,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isSearching = !isSearching;
                                    searchController.clear();
                                  });
                                },
                              ),
                              IconButton(
                                tooltip: _filterOpen
                                    ? "Close filter"
                                    : "Filter: $_goalType",
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _filterOpen ? Icons.close : Icons.filter_list,
                                ),
                                onPressed: () {
                                  setState(() => _filterOpen = !_filterOpen);
                                },
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final result = await openFormPage(
                                    context,
                                    Createtask(assignedToIds: [adminId!]),
                                    maxWidth: 880,
                                  );
                                  if (result == true && mounted) {
                                    setState(() => _goalsRefreshKey++);
                                  }
                                },
                                child: Chip(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  label: const Text(
                                    "Add Goal/Task",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_filterOpen)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _goalTypeChip("All"),
                                  _goalTypeChip("Yearly"),
                                  _goalTypeChip("Monthly"),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Allgoals(
                              key: ValueKey(_goalsRefreshKey),
                              searchQuery: searchController.text,
                              goalType: _goalType,
                              onlyMine: true,
                              onDelete: (msg, isError) {
                                showTopMessage(msg, isError: isError);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    PendingTab(
                      adminId: adminId!,
                      statusOf: _statusOf,
                      onStatusSaved: _onTaskStatus,
                    ),
                    InProcessTab(
                      adminId: adminId!,
                      statusOf: _statusOf,
                      onStatusSaved: _onTaskStatus,
                    ),
                    CompletedTab(
                      adminId: adminId!,
                      statusOf: _statusOf,
                      onStatusSaved: _onTaskStatus,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _showTopMessage ? 40 : -120,
              left: 16,
              right: 16,
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

class _BoardColumn {
  final String title;
  final List<Map<String, dynamic>> tasks;

  const _BoardColumn({
    required this.title,
    required this.tasks,
  });
}

class _WorkBoard extends StatefulWidget {
  final int adminId;
  final String goalType;
  final String searchQuery;
  final String Function(Map task) statusOf;
  final Future<void> Function(Map<String, dynamic> task) onTaskStatus;
  final void Function(String message, bool isError)? onDelete;

  const _WorkBoard({
    super.key,
    required this.adminId,
    required this.goalType,
    required this.searchQuery,
    required this.statusOf,
    required this.onTaskStatus,
    this.onDelete,
  });

  @override
  State<_WorkBoard> createState() => _WorkBoardState();
}

class _WorkBoardState extends State<_WorkBoard> {
  late Future<List<Map<String, dynamic>>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = AdminService.getAdminTasks(widget.adminId);
  }

  String _bucket(Map<String, dynamic> task) {
    final status = widget.statusOf(task);
    switch (status) {
      case 'inprogress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  bool _matchesSearch(Map<String, dynamic> task) {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final name = (task['task'] ?? task['Task'] ?? '').toString().toLowerCase();
    final code = (task['taskCode'] ?? task['TaskCode'] ?? '')
        .toString()
        .toLowerCase();
    return name.contains(query) || code.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final failed = snapshot.hasError;
        final columns = waiting || failed
            ? _columns(const [])
            : _columns(snapshot.data ?? []);
        final sections = <Widget>[
          _goalColumn(context),
          for (var i = 0; i < columns.length; i++)
            _taskColumn(
              context,
              columns[i],
              waiting: waiting,
              failed: failed && i == 0,
            ),
        ];
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: WebTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: WebTheme.lineOf(context),
                  ),
                sections[i],
              ],
            ],
          ),
        );
      },
    );
  }

  List<_BoardColumn> _columns(List<Map<String, dynamic>> source) {
    final grouped = <String, List<Map<String, dynamic>>>{
      'Pending': [],
      'In Progress': [],
      'Completed': [],
    };
    for (final task in source.where(_matchesSearch)) {
      grouped[_bucket(task)]!.add(task);
    }
    return [
      _BoardColumn(
        title: 'Pending',
        tasks: grouped['Pending']!,
      ),
      _BoardColumn(
        title: 'In Progress',
        tasks: grouped['In Progress']!,
      ),
      _BoardColumn(
        title: 'Completed',
        tasks: grouped['Completed']!,
      ),
    ];
  }

  Widget _goalColumn(BuildContext context) {
    return _columnShell(
      title: 'All',
      accent: WebTheme.brand,
      countLabel: '',
      child: Allgoals(
        searchQuery: widget.searchQuery,
        goalType: widget.goalType,
        onlyMine: true,
        boardStyle: true,
        onDelete: widget.onDelete,
      ),
    );
  }

  Widget _taskColumn(
    BuildContext context,
    _BoardColumn column, {
    required bool waiting,
    required bool failed,
  }) {
    final Widget body;
    if (waiting) {
      body = const Center(child: RotatingFlower(size: 28));
    } else if (failed) {
      body = const AppLoadError();
    } else if (column.tasks.isEmpty) {
      body = Center(
        child: Text(
          'No tasks',
          style: TextStyle(
            color: WebTheme.mutedOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      body = ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              itemCount: column.tasks.length,
              itemBuilder: (context, index) {
                final task = column.tasks[index];
                return Taskstatus(
                  task: task,
                  onStatusSaved: (task) async {
                    widget.onTaskStatus(task);
                  },
                  onTap: () {
                    final code =
                        (task['taskCode'] ?? task['TaskCode'] ?? '').toString();
                    if (code.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetails(taskCode: code),
                      ),
                    );
                  },
                );
              },
            );
    }
    return _columnShell(
      title: column.title,
      accent: WebTheme.brand,
      countLabel: waiting ? '' : '${column.tasks.length}',
      child: body,
    );
  }

  Widget _columnShell({
    required String title,
    required Color accent,
    required String countLabel,
    required Widget child,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: accent,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (countLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      countLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
