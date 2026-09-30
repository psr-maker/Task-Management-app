import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/taskpoint.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class Taskpoints extends StatefulWidget {
  const Taskpoints({super.key});

  @override
  State<Taskpoints> createState() => _TaskpointsState();
}

class _TaskpointsState extends State<Taskpoints> {
  late Future<List<Map<String, dynamic>>> tasksFuture;
  int? expandedIndex;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  String _filter = "Pending";
  String _department = "All";
  String _role = "";
  List<String> _divisionDepartments = [];
  Map<int, UserModel> _usersById = {};
  bool _searchOpen = false;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    tasksFuture = _loadVisibleTasks();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  Future<void> _refreshTasks() async {
    setState(() {
      expandedIndex = null;
      tasksFuture = _loadVisibleTasks();
    });
    await tasksFuture;
  }

  Future<List<Map<String, dynamic>>> _loadVisibleTasks() async {
    final token = await AuthService.getToken();
    final role = token == null ? "" : (JwtHelper.getRole(token) ?? "");
    final userId = int.tryParse(
      token == null ? "" : (JwtHelper.getuid(token) ?? ""),
    );
    var myDepartment = token == null
        ? ""
        : (JwtHelper.getDepartment(token) ?? "").trim();

    List<UserModel> users = [];
    try {
      users = await SuperAdminService.getAllUsers();
    } catch (_) {}
    if (myDepartment.isEmpty && userId != null) {
      for (final user in users) {
        if (user.userId == userId && user.department.trim().isNotEmpty) {
          myDepartment = user.department.trim();
          break;
        }
      }
    }

    List<String> divisionDepartments = [];
    try {
      if (_isDirector(role)) {
        divisionDepartments = await _departmentsUnderDivisionHeads(users);
      } else {
        divisionDepartments = await AdminService.getMySubDepartments();
      }
    } catch (_) {}

    final tasks = await AdminService.getCompletedTaskPoints();
    final usersById = {for (final user in users) user.userId: user};
    if (mounted) {
      setState(() {
        _role = role;
        _divisionDepartments = divisionDepartments;
        _usersById = usersById;
      });
    }
    return tasks
        .where(
          (task) => _canSeeTask(
            task,
            role: role,
            userId: userId,
            myDepartment: myDepartment,
            divisionDepartments: divisionDepartments,
            usersById: usersById,
          ),
        )
        .toList();
  }

  int? _staffIdOf(Map<String, dynamic> task) {
    return int.tryParse("${task["staffId"] ?? ""}");
  }

  bool _canSeeTask(
    Map<String, dynamic> task, {
    required String role,
    required int? userId,
    required String myDepartment,
    required List<String> divisionDepartments,
    required Map<int, UserModel> usersById,
  }) {
    final staffId = _staffIdOf(task);
    if (staffId != null && staffId == userId) return false;
    final person = staffId == null ? null : usersById[staffId];
    final profileDepartment = person?.department.trim() ?? "";
    final department = profileDepartment.isNotEmpty
        ? profileDepartment
        : _departmentOf(task);
    final personRole = (person?.role ??
            _text(task, ["staffRole", "role", "Role"]))
        .toString();

    if (_isDirector(role)) {
      if (AppRoles.isDivisionHead(personRole)) return true;
      if (!AppRoles.isManager(personRole)) return false;
      if (department.trim().isEmpty) return false;
      return !DivisionConfig.isAllowedDepartment(
        department,
        divisionDepartments,
      );
    }

    if (AppRoles.isDivisionHead(role)) {
      if (!AppRoles.isManager(personRole)) return false;
      return DivisionConfig.isAllowedDepartment(
        department,
        divisionDepartments,
      );
    }

    if (myDepartment.isEmpty || department.isEmpty) return true;
    return DivisionConfig.isAllowedDepartment(department, [myDepartment]);
  }

  bool _isDirector(String role) {
    final value = role.trim().toLowerCase();
    return value == AppRoles.director || value == "director";
  }

  Future<List<String>> _departmentsUnderDivisionHeads(
    List<UserModel> users,
  ) async {
    return AdminService.getDivisionHeadDepartments(users);
  }

  String _text(Map<String, dynamic> task, List<String> keys) {
    for (final key in keys) {
      final value = task[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != "null") return text;
    }
    return "";
  }

  String _resolvedDepartment(Map<String, dynamic> task) {
    final onTask = _departmentOf(task);
    if (onTask.isNotEmpty) return onTask;
    final person = _usersById[_staffIdOf(task) ?? -1];
    return person?.department.trim() ?? "";
  }

  String _departmentOf(Map<String, dynamic> task) {
    return _text(task, ["department", "staffDepartment", "Department"]);
  }

  bool _isReviewed(Map<String, dynamic> task) => task["finalPoints"] != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: _searchOpen
            ? TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() => expandedIndex = null),
                decoration: const InputDecoration(
                  hintText: "Search name or task",
                  border: InputBorder.none,
                  isDense: true,
                ),
              )
            : WebPushedChrome.isWeb(context)
            ? null
            : const Text("Task Performance"),
        actions: [
          IconButton(
            tooltip: _searchOpen ? "Close search" : "Search",
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _search.clear();
                  expandedIndex = null;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          WebPushedChrome.body(
            context,
            title: "Task Performance",
            subtitle: "Review completed tasks and award points",
            panel: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
              child: _buildTaskList(),
            ),
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 20 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
                backgroundColor: _isErrorMessage
                    ? Colors.red
                    : Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }
        if (snapshot.hasError) {
          return AppLoadError(onRetry: _refreshTasks);
        }

        final tasks = snapshot.data ?? [];
        final divisionHead = AppRoles.isDivisionHead(_role);
        final departments = divisionHead
            ? _divisionDepartments
            : (tasks.map(_resolvedDepartment).where((name) => name.isNotEmpty).toSet().toList()
                ..sort());
        final query = _search.text.trim().toLowerCase();
        final visible = tasks.where((task) {
          if (_department != "All" &&
              !DivisionConfig.isAllowedDepartment(
                _resolvedDepartment(task),
                [_department],
              )) {
            return false;
          }
          if (_filter == "Pending" && _isReviewed(task)) return false;
          if (_filter == "Submitted" && !_isReviewed(task)) return false;
          if (query.isEmpty) return true;
          final haystack =
              "${task["staffName"] ?? ""} ${task["task"] ?? ""} ${_resolvedDepartment(task)}"
                  .toLowerCase();
          return haystack.contains(query);
        }).toList();
        final pendingCount = tasks.where((task) => !_isReviewed(task)).length;
        final submittedCount = tasks.length - pendingCount;

        return Column(
          children: [
            if ((divisionHead && departments.isNotEmpty) ||
                (!divisionHead && departments.length > 1)) ...[
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ["All", ...departments].map(_deptChip).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                _countChip("Pending", pendingCount, "Pending"),
                const SizedBox(width: 8),
                _countChip("Submitted", submittedCount, "Submitted"),
                const SizedBox(width: 8),
                _countChip("All", tasks.length, "All"),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyState(
                      icon: Icons.task_alt_outlined,
                      title: tasks.isEmpty
                          ? "No completed tasks yet"
                          : "Nothing matches this view",
                      message: tasks.isEmpty
                          ? "Completed tasks ready for review will appear here."
                          : "Try another search, department, or status.",
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshTasks,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: visible.length,
                        itemBuilder: (context, index) =>
                            _buildTaskCard(visible[index], index),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _countChip(String label, int count, String value) {
    final selected = _filter == value;
    final color = Theme.of(context).colorScheme.secondary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _filter = value;
          expandedIndex = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                "$count",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deptChip(String name) {
    final selected = _department == name;
    final color = Theme.of(context).colorScheme.secondary;
    final label = name == "All" ? "All" : name.replaceAll(" Department", "");
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _department = name;
          expandedIndex = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : const Color(0xFFD0D5D2),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final staffId = int.tryParse("${task["staffId"]}");
    if (staffId == null) return const SizedBox();

    final reviewed = _isReviewed(task);
    final expanded = expandedIndex == index;
    final name = (task["staffName"] ?? "Unknown Staff").toString();
    final title = (task["task"] ?? "").toString();
    final department = _resolvedDepartment(task);
    const green = Color.fromARGB(255, 25, 77, 38);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF173024) : Colors.white;
    final ink = isDark ? Colors.white : const Color(0xFF1C2B22);
    final muted = isDark ? const Color(0xFFB7C7BC) : const Color(0xFF66756C);

    return Column(
      children: [
        Material(
          color: cardColor,
          elevation: isDark ? 0 : 1,
          shadowColor: green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() {
              expandedIndex = expanded ? null : index;
            }),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C4A38)
                      : const Color(0xFFE3EBE6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: green,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: reviewed
                              ? const Color(0xFFE7F6EC)
                              : const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reviewed ? "${task["finalPoints"]}/100" : "Pending",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: reviewed
                                ? const Color(0xFF1B7A3A)
                                : const Color(0xFFB86E00),
                          ),
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title.isEmpty ? "Untitled task" : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _metaGrid(
                    ink: ink,
                    muted: muted,
                    items: [
                      ("Due date", AppHelpers.formatDate(task["dueDate"]?.toString())),
                      (
                        "Completed",
                        AppHelpers.formatDate(_completedDate(task)),
                      ),
                      ("Members", _memberCount(task)),
                      if (department.isNotEmpty)
                        (
                          "Department",
                          department.replaceAll(" Department", ""),
                        ),
                    ],
                  ),
                  if (_hasQuantity(task, staffId)) ...[
                    const SizedBox(height: 12),
                    _quantityRow(task, staffId, ink, muted),
                  ],
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskPointDetail(
                    key: ValueKey("${task["taskCode"]}_$staffId"),
                    taskName: title,
                    assignedTo: name,
                    taskId: task["taskCode"].toString(),
                    staffId: staffId,
                    systemPoints: task["systemPoints"] ?? 0,
                    finalPoints: task["finalPoints"],
                    isReviewed: reviewed,
                    delayJustified: task["isDelayJustified"] ?? false,
                    delayReason: task["delayReason"],
                    comment: task["comment"],
                    onShowMessage: (msg, {isError = true}) {
                      showTopMessage(msg, isError: isError);
                    },
                    onReviewSubmitted: _refreshTasks,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  String? _completedDate(Map<String, dynamic> task) {
    final value = _text(task, [
      "completedDate",
      "completed_date",
      "CompletedDate",
    ]);
    return value.isEmpty ? null : value;
  }

  String _memberCount(Map<String, dynamic> task) {
    final stored = task["totalMembers"] ?? task["TotalMembers"];
    if (stored != null && stored.toString().trim().isNotEmpty) {
      return stored.toString();
    }
    final people = task["assignedTo"] ?? task["AssignedTo"];
    if (people is List) return people.length.toString();
    return "0";
  }

  bool _hasQuantity(Map<String, dynamic> task, int staffId) {
    final type = _text(task, ["performanceType", "PerformanceType"])
        .toLowerCase();
    if (type == "qty") return true;
    return _targetQuantity(task, staffId) > 0;
  }

  int _targetQuantity(Map<String, dynamic> task, int staffId) {
    return memberShareQuantity(task, staffId) ??
        readGoalInt(task, const [
          "targetQuantity",
          "TargetQuantity",
          "quantity",
          "Quantity",
        ]) ??
        0;
  }

  int _completedQuantity(Map<String, dynamic> task, int staffId) {
    return memberShareCompleted(task, staffId) ??
        readGoalInt(task, const [
          "completedQuantity",
          "CompletedQuantity",
          "achievedQuantity",
          "AchievedQuantity",
        ]) ??
        0;
  }

  int _pendingQuantity(Map<String, dynamic> task, int staffId) {
    final memberTarget = memberShareQuantity(task, staffId);
    if (memberTarget != null) {
      final done = memberShareCompleted(task, staffId) ?? 0;
      final pending = memberTarget - done;
      return pending < 0 ? 0 : pending;
    }
    final stored = readGoalInt(task, const [
      "pendingQuantity",
      "PendingQuantity",
    ]);
    if (stored != null) return stored;
    final pending =
        _targetQuantity(task, staffId) - _completedQuantity(task, staffId);
    return pending < 0 ? 0 : pending;
  }

  Widget _metaGrid({
    required Color ink,
    required Color muted,
    required List<(String, String)> items,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        for (final item in items)
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _quantityRow(
    Map<String, dynamic> task,
    int staffId,
    Color ink,
    Color muted,
  ) {
    final items = [
      ("Target", _targetQuantity(task, staffId)),
      ("Completed", _completedQuantity(task, staffId)),
      ("Pending", _pendingQuantity(task, staffId)),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${items[i].$2}",
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
