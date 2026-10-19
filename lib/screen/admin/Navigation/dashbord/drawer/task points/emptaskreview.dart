import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/request_workspace.dart';
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
import 'package:staff_work_track/utils/task_score.dart';

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
    List<UserModel> users = [];
    try {
      users = await SuperAdminService.getAllUsers();
    } catch (_) {}

    final tasks = await AdminService.getCompletedTaskPoints();
    final usersById = {for (final user in users) user.userId: user};
    if (mounted) {
      setState(() {
        _usersById = usersById;
      });
    }

    final token = await AuthService.getToken();
    final role = token == null ? "" : (JwtHelper.getRole(token) ?? "");
    if (!AppRoles.isDivisionHead(role)) return tasks;

    final departments = await _divisionDepartments(token, usersById);
    return tasks
        .where((task) => _isDivisionManager(task, usersById, departments))
        .toList();
  }

  Future<List<String>> _divisionDepartments(
    String? token,
    Map<int, UserModel> usersById,
  ) async {
    final names = <String>[];

    void add(String name) {
      final value = name.trim();
      if (value.isEmpty) return;
      if (names.any((item) => DivisionConfig.isAllowedDepartment(value, [item]))) {
        return;
      }
      names.add(value);
    }

    final own = token == null ? "" : (JwtHelper.getDepartment(token) ?? "");
    add(own);
    final userId = int.tryParse(
      token == null ? "" : (JwtHelper.getuid(token) ?? ""),
    );
    if (userId != null) add(usersById[userId]?.department ?? "");

    try {
      for (final name in await AdminService.getMySubDepartments()) {
        add(name);
      }
      if (own.trim().isNotEmpty) {
        for (final name in await AdminService.getMySubDepartments(
          headDepartment: own,
        )) {
          add(name);
        }
      }
    } catch (_) {}

    return names;
  }

  bool _isDivisionManager(
    Map<String, dynamic> task,
    Map<int, UserModel> usersById,
    List<String> departments,
  ) {
    final person = usersById[_staffIdOf(task) ?? -1];
    final role = person != null && person.role.trim().isNotEmpty
        ? person.role
        : _text(task, ["staffRole", "role", "Role"]);
    if (!AppRoles.isManager(role)) return false;
    if (departments.isEmpty) return true;
    final department = person != null && person.department.trim().isNotEmpty
        ? person.department
        : _departmentOf(task);
    if (department.isEmpty) return true;
    return DivisionConfig.isAllowedDepartment(department, departments);
  }

  int? _staffIdOf(Map<String, dynamic> task) {
    return int.tryParse("${task["staffId"] ?? ""}");
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

  void _openReview(Map<String, dynamic> task) {
    final staffId = int.tryParse('${task['staffId']}');
    if (staffId == null) return;
    final title = (task['task'] ?? '').toString();
    final name = (task['staffName'] ?? 'Unknown Staff').toString();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final width = AppLayout.dialogMaxWidth(dialogContext, preferred: 560);
        return Dialog(
          backgroundColor: WebTheme.surfaceOf(dialogContext),
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: WebTheme.lineOf(dialogContext)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.86,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submit review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: WebTheme.brand,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title.isEmpty ? 'Untitled task' : title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: WebTheme.inkOf(dialogContext),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: WebTheme.mutedOf(dialogContext),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(
                          Icons.close_rounded,
                          color: WebTheme.mutedOf(dialogContext),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: WebTheme.lineOf(dialogContext)),
                  const SizedBox(height: 16),
                  TaskPointDetail(
                    key: ValueKey('${task['taskCode']}_$staffId'),
                    taskName: title,
                    assignedTo: name,
                    taskId: task['taskCode'].toString(),
                    staffId: staffId,
                    framed: false,
                    systemPoints: _systemPoints(task, staffId),
                    finalPoints: task['finalPoints'],
                    isReviewed: _isReviewed(task),
                    delayJustified: task['isDelayJustified'] ?? false,
                    delayReason: task['delayReason'],
                    comment: task['comment'],
                    onShowMessage: (msg, {isError = true}) {
                      showTopMessage(msg, isError: isError);
                    },
                    onReviewSubmitted: () {
                      Navigator.pop(dialogContext);
                      _refreshTasks();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _webPerformance() {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final tasks = snapshot.data ?? [];
          final query = _search.text.trim().toLowerCase();
          final visible = tasks.where((task) {
            if (_filter == 'Pending' && _isReviewed(task)) return false;
            if (_filter == 'Submitted' && !_isReviewed(task)) return false;
            if (query.isEmpty) return true;
            final haystack =
                '${task['staffName'] ?? ''} ${task['task'] ?? ''} ${_membersLabel(task)}'
                    .toLowerCase();
            return haystack.contains(query);
          }).toList();
          final pendingCount = tasks.where((task) => !_isReviewed(task)).length;
          final showReview = _filter != 'Pending';
          return RequestWorkspace(
            title: 'Task Performance',
            subtitle: 'Review completed tasks and award points',
            loading: waiting && tasks.isEmpty,
            scrollable: true,
            plainStatus: true,
            emptyTitle: snapshot.hasError ? 'Could not load tasks' : 'No tasks in this view',
            emptyMessage: snapshot.hasError
                ? 'Try again in a moment.'
                : 'Completed tasks ready for review will appear here.',
            filters: const ['Pending', 'Submitted', 'All'],
            selectedFilter: _filter,
            onFilter: (value) => setState(() {
              _filter = value;
              expandedIndex = null;
            }),
            stats: [
              WorkspaceStat(label: 'Pending', value: '$pendingCount', icon: Icons.pending_actions_rounded, color: WebTheme.brand),
              WorkspaceStat(label: 'Submitted', value: '${tasks.length - pendingCount}', icon: Icons.task_alt_rounded, color: WebTheme.brand),
            ],
            columns: [
              'Name',
              'Task',
              'Due date',
              'Completed date',
              'Score',
              'Members',
              'Target qty',
              'Completed qty',
              'Pending qty',
              if (showReview) ...const [
                'Delay justified',
                'Reason',
                'Comment',
                'Manager points',
              ],
            ],
            records: [
              for (final task in visible)
                if (int.tryParse('${task['staffId']}') != null)
                  WorkspaceRecord(
                    status: _isReviewed(task) ? 'Submitted' : 'Pending',
                    onTap: _isReviewed(task) ? null : () => _openReview(task),
                    actions: _isReviewed(task)
                        ? const []
                        : [
                            workspaceAction(
                              'Review',
                              () => _openReview(task),
                              filled: true,
                            ),
                          ],
                    values: _taskRow(task, includeReview: showReview),
                  ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isMobile(context)) return _webPerformance();
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
        final query = _search.text.trim().toLowerCase();
        final visible = tasks.where((task) {
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

  List<String> _taskRow(
    Map<String, dynamic> task, {
    required bool includeReview,
  }) {
    final staffId = int.parse('${task['staffId']}');
    final reviewed = _isReviewed(task);
    final qty = _hasQuantity(task, staffId);
    String shown(dynamic value) {
      final text = (value ?? '').toString().trim();
      return text.isEmpty || text == 'null' ? '—' : text;
    }

    return [
      (task['staffName'] ?? 'Unknown Staff').toString(),
      ((task['task'] ?? '').toString().isEmpty
          ? 'Untitled task'
          : task['task']).toString(),
      AppHelpers.formatDate(task['dueDate']?.toString()),
      AppHelpers.formatDate(_completedDate(task)),
      '${_systemPoints(task, staffId)} / $taskScoreMax',
      _membersLabel(task),
      qty ? '${_targetQuantity(task, staffId)}' : '—',
      qty ? '${_completedQuantity(task, staffId)}' : '—',
      qty ? '${_pendingQuantity(task, staffId)}' : '—',
      if (includeReview) ...[
        reviewed ? ((task['isDelayJustified'] == true) ? 'Yes' : 'No') : '—',
        reviewed ? shown(task['delayReason']) : '—',
        reviewed ? shown(task['comment']) : '—',
        reviewed ? shown(task['finalPoints']) : '—',
      ],
    ];
  }

  String _membersLabel(Map<String, dynamic> task) {
    final people = task['assignedTo'] ?? task['AssignedTo'];
    if (people is List && people.isNotEmpty) {
      final names = people
          .map((person) {
            if (person is Map) {
              return (person['name'] ??
                      person['staffName'] ??
                      person['userName'] ??
                      '')
                  .toString();
            }
            return person.toString();
          })
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty && name.toLowerCase() != 'null')
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }
    return _memberCount(task);
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
                      ("Score", "${_systemPoints(task, staffId)} / $taskScoreMax"),
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
                  child: reviewed
                      ? _submittedDetails(task, ink, muted)
                      : TaskPointDetail(
                          key: ValueKey("${task["taskCode"]}_$staffId"),
                          taskName: title,
                          assignedTo: name,
                          taskId: task["taskCode"].toString(),
                          staffId: staffId,
                          systemPoints: _systemPoints(task, staffId),
                          finalPoints: task["finalPoints"],
                          isReviewed: false,
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

  Widget _submittedDetails(
    Map<String, dynamic> task,
    Color ink,
    Color muted,
  ) {
    String shown(dynamic value) {
      final text = (value ?? '').toString().trim();
      return text.isEmpty || text == 'null' ? '—' : text;
    }

    final rows = [
      ('Delay justified', task['isDelayJustified'] == true ? 'Yes' : 'No'),
      ('Reason', shown(task['delayReason'])),
      ('Comment', shown(task['comment'])),
      ('Manager points', shown(task['finalPoints'])),
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.brandSoftOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.$1,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _systemPoints(Map<String, dynamic> task, int staffId) {
    final calculated = taskSystemScore(task, userId: staffId);
    if (calculated != null) return calculated;
    final stored = task["systemPoints"];
    if (stored is num) return stored.round();
    return int.tryParse("$stored") ?? 0;
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
