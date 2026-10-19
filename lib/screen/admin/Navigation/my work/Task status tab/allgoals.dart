import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/admintask_list.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/goal_assignment.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/goal_task_enrich.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

class Allgoals extends StatefulWidget {
  final String searchQuery;
  final TaskFilterModel? filter;
  final String goalType;
  final bool onlyMine;
  final bool boardStyle;
  final bool expandYearlyInline;
  final bool showLooseTasks;
  final Function(String, bool)? onDelete;

  const Allgoals({
    super.key,
    required this.searchQuery,
    this.filter,
    this.goalType = "All",
    this.onlyMine = false,
    this.boardStyle = false,
    this.expandYearlyInline = false,
    this.showLooseTasks = false,
    this.onDelete,
  });

  @override
  State<Allgoals> createState() => _AllgoalsState();
}

class _AllgoalsState extends State<Allgoals> {
  List<_GoalNode> goals = [];
  List<Map<String, dynamic>> looseTasks = [];
  Map<int, String> _departmentByUser = {};
  bool isLoading = true;
  DataRefreshNotifier? _refresh;
  DateTime? _seenGoalRefresh;
  DateTime? _seenTaskRefresh;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    loadGoals(showLoader: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<DataRefreshNotifier>();
    if (!identical(_refresh, next)) {
      _refresh?.removeListener(_onDataRefresh);
      _refresh = next;
      _seenGoalRefresh = next.lastGoalRefresh;
      _seenTaskRefresh = next.lastTaskRefresh;
      next.addListener(_onDataRefresh);
    }
  }

  void _onDataRefresh() {
    final refresh = _refresh;
    if (refresh == null || !mounted) return;
    final goalAt = refresh.lastGoalRefresh;
    final taskAt = refresh.lastTaskRefresh;
    if (goalAt == _seenGoalRefresh && taskAt == _seenTaskRefresh) return;
    _seenGoalRefresh = goalAt;
    _seenTaskRefresh = taskAt;
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) loadGoals();
    });
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _refresh?.removeListener(_onDataRefresh);
    super.dispose();
  }

  Future<List<dynamic>> _fetchGoals() async {
    if (widget.onlyMine) return _fetchMyGoals();
    final chunks = <List<dynamic>>[];

    List<dynamic> withTasks = [];
    try {
      withTasks = await SuperAdminService.getGoals();
      chunks.add(withTasks);
    } catch (e) {
      debugPrint(e.toString());
    }

    try {
      chunks.add(await SuperAdminService.getGoalsname());
    } catch (e) {
      debugPrint(e.toString());
    }

    final token = await AuthService.getToken();
    if (token != null) {
      final userId = int.tryParse(JwtHelper.getuid(token)?.toString() ?? '');
      final role = JwtHelper.getRole(token);
      final department = (JwtHelper.getDepartment(token) ?? '').trim();
      final isDirector =
          role == AppRoles.director || (role ?? '').toLowerCase() == 'director';

      if (userId != null) {
        try {
          chunks.add(await AdminService.getusergoalbyid(userId));
        } catch (e) {
          debugPrint(e.toString());
        }
      }

      if (!isDirector && department.isNotEmpty) {
        try {
          chunks.add(await AdminService.getGoalsByDepartment(department));
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }

    final merged = _mergeGoalLists(chunks);
    _applySavedQuantities(merged, _quantityByCode(withTasks));
    looseTasks = await _attachRelatedTasks(
      merged,
      withTasks: withTasks,
      fetchUserTasks: withTasks.isEmpty,
      fetchCompanyTasks: widget.showLooseTasks,
    );
    return merged;
  }

  Future<List<dynamic>> _fetchMyGoals() async {
    final token = await AuthService.getToken();
    if (token == null) return [];
    final userId = int.tryParse(JwtHelper.getuid(token)?.toString() ?? "");
    if (userId == null) return [];

    List<dynamic> mine = [];
    try {
      mine = await AdminService.getusergoalbyid(userId);
    } catch (e) {
      debugPrint(e.toString());
    }

    List<dynamic> detailed = [];
    try {
      detailed = await SuperAdminService.getGoals();
    } catch (e) {
      debugPrint(e.toString());
    }

    final byCode = _quantityByCode(detailed);
    final merged = _mergeGoalLists([mine, detailed]);
    final goals = _goalsVisibleTo(
      merged,
      userId,
      listedMonthKeys: _listedMonthKeys(mine),
      listedYearlyKeys: _listedYearlyKeys(mine),
    );
    for (final goal in goals) {
      _keepLoginUserTasks(goal, byCode, userId);
    }

    await _attachRelatedTasks(
      goals,
      withTasks: detailed,
      userId: userId,
      fetchUserTasks: true,
    );
    return goals;
  }

  Future<List<Map<String, dynamic>>> _attachRelatedTasks(
    List goals, {
    List<dynamic> withTasks = const [],
    int? userId,
    bool fetchUserTasks = false,
    bool fetchCompanyTasks = false,
  }) async {
    final flat = <Map<String, dynamic>>[];

    void collect(dynamic raw) {
      if (raw is! Map) return;
      final nested = raw["tasks"] ?? raw["Tasks"];
      if (nested is List) {
        for (final task in nested) {
          if (task is Map) flat.add(Map<String, dynamic>.from(task));
        }
      }
      final months = raw["monthlyGoals"] ?? raw["MonthlyGoals"];
      if (months is List) {
        for (final month in months) {
          collect(month);
        }
      }
    }

    for (final goal in withTasks) {
      collect(goal);
    }

    if (fetchUserTasks) {
      int? id = userId;
      if (id == null) {
        final token = await AuthService.getToken();
        if (token != null) {
          id = int.tryParse(JwtHelper.getuid(token)?.toString() ?? '');
        }
      }
      if (id != null) {
        try {
          flat.addAll(await AdminService.getAdminTasks(id));
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    }

    if (fetchCompanyTasks) {
      try {
        final all = await SuperAdminService.getAllTasks();
        final raw =
            all["tasks"] ??
            all["Tasks"] ??
            all["result"] ??
            all["Result"] ??
            all["data"] ??
            all["Data"];
        if (raw is List) {
          for (final item in raw) {
            if (item is Map) flat.add(Map<String, dynamic>.from(item));
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    if (flat.isEmpty) return [];
    return attachTasksToGoals(goals, flat);
  }

  Future<void> _loadDepartmentDirectory() async {
    try {
      final users = await SuperAdminService.getAllUsers();
      final directory = <int, String>{};
      for (final user in users) {
        final department = user.department.trim();
        if (user.userId <= 0 || department.isEmpty) continue;
        directory[user.userId] = department;
      }
      _departmentByUser = directory;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadGoals({bool showLoader = false}) async {
    try {
      if (showLoader && mounted) setState(() => isLoading = true);
      final directory = _loadDepartmentDirectory();
      final data = await _fetchGoals();
      await directory;
      if (!mounted) return;
      final tree = _buildGoalTree(data);
      await Future.wait(tree.map((node) => enrichGoalTaskQuantities(node.goal)));
      if (!mounted) return;
      setState(() {
        goals = tree;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String? get _selectedDepartment {
    final value = widget.filter?.department?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  bool _textMatch(Map<String, dynamic> goal) {
    String normalize(String value) {
      return value.toLowerCase().replaceAll(" ", "").replaceAll("_", "");
    }

    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final title = (goal["title"] ?? "").toString().toLowerCase();
      final tasks = goal["tasks"];
      var taskHit = false;
      if (tasks is List) {
        for (final task in tasks) {
          if (task is! Map) continue;
          final name = (task["task"] ?? task["title"] ?? task["Task"] ?? "")
              .toString()
              .toLowerCase();
          if (name.contains(query)) {
            taskHit = true;
            break;
          }
        }
      }
      if (!title.contains(query) && !taskHit) return false;
    }

    if (widget.filter?.status != null && widget.filter!.status!.isNotEmpty) {
      final goalStatus = normalize((goal["status"] ?? "").toString());
      final filterStatus = normalize(widget.filter!.status!);
      if (goalStatus != filterStatus) return false;
    }

    if (widget.filter?.priority != null &&
        (goal["priority"] ?? "").toString().toLowerCase() !=
            widget.filter!.priority!.toLowerCase()) {
      return false;
    }

    return true;
  }

  bool _inSelectedDepartment(Map goal, {Set<String> inherited = const {}}) {
    final selected = _selectedDepartment;
    if (selected == null) return true;
    final names = {...inherited, ..._goalDepartments(goal, _departmentByUser)};
    return names.any(
      (name) => DivisionConfig.isAllowedDepartment(name, [selected]),
    );
  }

  List<_GoalNode> get filteredGoals {
    final result = <_GoalNode>[];
    for (final node in goals) {
      final isYearly = node.months.isNotEmpty || isYearlyGoal(node.goal);
      if (widget.goalType == 'Yearly' && !isYearly) continue;

      if (!isYearly) {
        if (_textMatch(node.goal) && _inSelectedDepartment(node.goal)) {
          result.add(node);
        }
        continue;
      }

      final parentText = _textMatch(node.goal);
      final parentDepartments = _goalDepartments(node.goal, _departmentByUser);
      final candidateMonths = parentText && widget.goalType != 'Monthly'
          ? node.months
          : node.months.where(_textMatch).toList();
      final visibleMonths = <Map<String, dynamic>>[];
      for (final month in candidateMonths) {
        final monthDepartments = _goalDepartments(month, _departmentByUser);
        final inherited =
            monthDepartments.isEmpty ? parentDepartments : const <String>{};
        if (_inSelectedDepartment(month, inherited: inherited)) {
          visibleMonths.add(month);
        }
      }

      if (widget.goalType == 'Monthly') {
        for (final month in visibleMonths) {
          result.add(_GoalNode(month));
        }
        continue;
      }

      final parentInDepartment = _inSelectedDepartment(node.goal);
      if (visibleMonths.isEmpty && (!parentText || !parentInDepartment)) {
        continue;
      }
      result.add(_GoalNode(_withMonths(node.goal, visibleMonths), visibleMonths));
    }
    return result;
  }

  List<Map<String, dynamic>> get listedTasks {
    if (!widget.showLooseTasks) return [];
    final query = widget.searchQuery.trim().toLowerCase();
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    void take(dynamic raw, Set<String> inherited) {
      if (raw is! Map) return;
      final task = Map<String, dynamic>.from(raw);
      if (!_inSelectedDepartment(task, inherited: inherited)) return;
      if (query.isNotEmpty) {
        final name = (task['task'] ?? task['title'] ?? task['Task'] ?? '')
            .toString()
            .toLowerCase();
        final code = (task['taskCode'] ?? task['TaskCode'] ?? '')
            .toString()
            .toLowerCase();
        if (!name.contains(query) && !code.contains(query)) return;
      }
      final code = (task['taskCode'] ?? task['TaskCode'] ?? '').toString().trim();
      final title = (task['task'] ?? task['title'] ?? task['Task'] ?? '')
          .toString();
      final key = code.isEmpty ? title : code.toLowerCase();
      if (!seen.add(key)) return;
      result.add(task);
    }

    void walk(Map<String, dynamic> goal, Set<String> inherited) {
      final own = _goalDepartments(goal, _departmentByUser);
      final department = own.isEmpty ? inherited : own;
      final tasks = goal['tasks'] ?? goal['Tasks'];
      if (tasks is List) {
        for (final item in tasks) {
          take(item, department);
        }
      }
      final months = goal['monthlyGoals'] ?? goal['MonthlyGoals'];
      if (months is List) {
        for (final month in months) {
          if (month is Map) {
            walk(Map<String, dynamic>.from(month), department);
          }
        }
      }
    }

    for (final node in filteredGoals) {
      walk(node.goal, const {});
    }
    if (widget.goalType == 'All') {
      for (final task in looseTasks) {
        take(task, const {});
      }
    }
    return result;
  }

  Widget _goalCard(Map<String, dynamic> goal) {
    final goalCode = _goalCode(goal);
    return GoalCard(
      key: ValueKey(goalCode.isEmpty ? goal["title"] : goalCode),
      goal: goal,
      onDelete: widget.onDelete,
      onRefresh: () => loadGoals(),
      expandMonthsInline: widget.expandYearlyInline,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    if (widget.boardStyle) {
      if (filteredGoals.isEmpty) {
        return Center(
          child: Text(
            widget.goalType == 'Yearly'
                ? "No yearly goals found"
                : widget.goalType == 'Monthly'
                    ? "No monthly goals found"
                    : "No goals found",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        itemCount: filteredGoals.length,
        itemBuilder: (context, index) => _goalCard(filteredGoals[index].goal),
      );
    }

    if (widget.expandYearlyInline || widget.showLooseTasks) {
      final goals = filteredGoals;
      final tasks = listedTasks;
      if (goals.isEmpty && tasks.isEmpty) {
        return Center(
          child: Text(
            widget.goalType == 'Yearly'
                ? "No yearly goals found"
                : widget.goalType == 'Monthly'
                ? "No monthly goals found"
                : "No goals found",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.goalType == 'Yearly'
                    ? "No yearly goals found"
                    : widget.goalType == 'Monthly'
                    ? "No monthly goals found"
                    : "No goals found",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
          else
            AdaptiveGoalCards(
              shrinkWrap: true,
              itemCount: goals.length,
              itemBuilder: (context, index) => _goalCard(goals[index].goal),
            ),
          if (widget.showLooseTasks) ...[
            const SizedBox(height: 20),
            Text(
              "Tasks : ${tasks.length}",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              Text(
                "No tasks found",
                style: Theme.of(context).textTheme.titleLarge,
              )
            else
              Alltasklist(
                tasks: tasks,
                searchQuery: '',
                onTaskDataUpdated: () => loadGoals(),
              ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: filteredGoals.isEmpty
              ? Center(
                  child: Text(
                    widget.goalType == 'Yearly'
                        ? "No yearly goals found"
                        : widget.goalType == 'Monthly'
                            ? "No monthly goals found"
                            : "No goals found",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : AdaptiveGoalCards(
                  itemCount: filteredGoals.length,
                  itemBuilder: (context, index) {
                    return _goalCard(filteredGoals[index].goal);
                  },
                ),
        ),
      ],
    );
  }
}

class _GoalNode {
  final Map<String, dynamic> goal;
  final List<Map<String, dynamic>> months;

  _GoalNode(this.goal, [List<Map<String, dynamic>>? months])
      : months = months ?? [];
}

Map<String, Map<String, dynamic>> _quantityByCode(List<dynamic> goals) {
  final saved = <String, Map<String, dynamic>>{};

  void take(dynamic raw) {
    if (raw is! Map) return;
    final goal = _asGoalMap(raw);
    final code = _goalCode(goal);
    if (code.isNotEmpty) saved[code] = goal;
    final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
    if (months is List) {
      for (final month in months) {
        take(month);
      }
    }
  }

  for (final goal in goals) {
    take(goal);
  }
  return saved;
}

void _applySavedQuantities(
  List<dynamic> goals,
  Map<String, Map<String, dynamic>> saved,
) {
  for (final raw in goals) {
    if (raw is! Map<String, dynamic>) continue;
    final source = saved[_goalCode(raw)];
    if (source != null) {
      final target = readGoalInt(source, const [
        "targetQuantity",
        "TargetQuantity",
      ]);
      final done = readGoalInt(source, const [
        "completedQuantity",
        "CompletedQuantity",
      ]);
      if (target != null) raw["targetQuantity"] = target;
      if (done != null) raw["completedQuantity"] = done;
    }
    final months = raw["monthlyGoals"];
    if (months is List) _applySavedQuantities(months, saved);
  }
}

Map<String, dynamic> _asGoalMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

Map<String, dynamic> _normalizeGoal(dynamic raw) {
  final goal = _asGoalMap(raw);
  if (goal.isEmpty) return goal;

  goal["id"] = goal["id"] ?? goal["Id"];
  goal["title"] = goal["title"] ?? goal["Title"] ?? "";
  goal["goalCode"] = goal["goalCode"] ?? goal["GoalCode"] ?? "";
  goal["goalType"] = goal["goalType"] ?? goal["GoalType"] ?? "";
  goal["status"] = goal["status"] ?? goal["Status"] ?? "";
  goal["priority"] = goal["priority"] ?? goal["Priority"] ?? "";
  goal["department"] =
      (goal["department"] ??
              goal["Department"] ??
              goal["departmentName"] ??
              goal["DepartmentName"] ??
              "")
          .toString();
  goal["createdByName"] = goal["createdByName"] ?? goal["assignBy"] ?? "";
  goal["parentGoalId"] = goal["parentGoalId"] ?? goal["ParentGoalId"];
  goal["startDate"] = goal["startDate"]?.toString();
  goal["dueDate"] = goal["dueDate"]?.toString();
  goal["targetQuantity"] =
      goal["targetQuantity"] ?? goal["TargetQuantity"] ?? 0;
  goal["completedQuantity"] =
      goal["completedQuantity"] ?? goal["CompletedQuantity"] ?? 0;

  if (goal["tasks"] is! List) {
    goal["tasks"] = [];
  }

  final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
  if (months is List) {
    goal["monthlyGoals"] = months
        .map(_normalizeGoal)
        .where((item) => item.isNotEmpty)
        .map(_asMonthlyGoal)
        .toList();
  } else {
    goal["monthlyGoals"] = <Map<String, dynamic>>[];
  }

  return goal;
}

Map<String, dynamic> _asMonthlyGoal(Map<String, dynamic> month) {
  final copy = Map<String, dynamic>.from(month);
  copy["goalType"] = "Monthly";
  copy["monthlyGoals"] = <Map<String, dynamic>>[];
  if (copy["tasks"] is! List) copy["tasks"] = [];
  return copy;
}

Map<String, dynamic> _withMonths(
  Map<String, dynamic> yearly,
  List<Map<String, dynamic>> months,
) {
  final copy = Map<String, dynamic>.from(yearly);
  copy["monthlyGoals"] = months.map(_asMonthlyGoal).toList();
  return copy;
}

bool _taskIsForUser(Map task, int userId) {
  final people = taskAssignees(task);
  if (people.isEmpty) return true;
  return people.any(
    (person) => int.tryParse(memberUserId(person)) == userId,
  );
}

void _keepLoginUserTasks(
  Map<String, dynamic> goal,
  Map<String, Map<String, dynamic>> detailed,
  int userId,
) {
  final source = detailed[_goalCode(goal)];
  var tasks = goal["tasks"];
  if ((tasks is! List || tasks.isEmpty) && source != null) {
    tasks = source["tasks"];
  }
  if (tasks is List) {
    goal["tasks"] = tasks
        .whereType<Map>()
        .map((task) => Map<String, dynamic>.from(task))
        .where((task) => _taskIsForUser(task, userId))
        .toList();
  } else {
    goal["tasks"] = <Map<String, dynamic>>[];
  }

  if (source != null && goalTarget(goal) <= 0) {
    final target = readGoalInt(source, const [
      "targetQuantity",
      "TargetQuantity",
    ]);
    if (target != null) goal["targetQuantity"] = target;
  }

  final months = goal["monthlyGoals"];
  if (months is List) {
    for (final month in months) {
      if (month is Map<String, dynamic>) {
        _keepLoginUserTasks(month, detailed, userId);
      }
    }
  }
}

String _goalCode(Map<String, dynamic> goal) {
  return (goal["goalCode"] ?? goal["GoalCode"] ?? "").toString().trim();
}

String _goalId(Map<String, dynamic> goal) {
  return (goal["id"] ?? goal["Id"] ?? "").toString().trim();
}

String _parentGoalId(Map<String, dynamic> goal) {
  return (goal["parentGoalId"] ?? goal["ParentGoalId"] ?? "")
      .toString()
      .trim();
}

String _goalType(Map<String, dynamic> goal) {
  return (goal["goalType"] ?? goal["GoalType"] ?? "").toString().toLowerCase();
}

const _goalPeopleKeys = [
  "yearlyAssignedUsers",
  "YearlyAssignedUsers",
  "yearlyAssignedUserIds",
  "YearlyAssignedUserIds",
  "assignedUserIds",
  "AssignedUserIds",
  "assignedUsers",
  "AssignedUsers",
  "assignedTo",
  "AssignedTo",
  "assignments",
  "goalAssignments",
];

/// Departments stored on the goal, or taken from the people assigned to it.
Set<String> _goalDepartments(Map goal, Map<int, String> byUser) {
  final names = <String>{};

  void addName(String raw) {
    final text = raw.trim();
    final lower = text.toLowerCase();
    if (text.isEmpty || lower == "null" || lower == "n/a") return;
    names.add(text);
  }

  void addPerson(dynamic raw) {
    if (raw is List) {
      for (final item in raw) {
        addPerson(item);
      }
      return;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in const [
        "department",
        "Department",
        "departmentName",
        "DepartmentName",
        "dept",
        "Dept",
      ]) {
        final value = map[key];
        if (value != null) addName(value.toString());
      }
      final id = readPersonId(map);
      final known = id == null ? null : byUser[id];
      if (known != null) addName(known);
      return;
    }
    final id = readPersonId(raw);
    final known = id == null ? null : byUser[id];
    if (known != null) addName(known);
  }

  for (final key in const [
    "department",
    "Department",
    "departmentName",
    "DepartmentName",
    "dept",
    "Dept",
  ]) {
    final value = goal[key];
    if (value is String) addName(value);
    if (value is List || value is Map) addPerson(value);
  }
  for (final key in _goalPeopleKeys) {
    addPerson(goal[key]);
  }
  final tasks = goal["tasks"] ?? goal["Tasks"];
  if (tasks is List) {
    for (final task in tasks) {
      if (task is! Map) continue;
      for (final key in const [
        "department",
        "Department",
        "departmentName",
        "DepartmentName",
      ]) {
        final value = task[key];
        if (value != null) addName(value.toString());
      }
      addPerson(
        task["assignedTo"] ??
            task["AssignedTo"] ??
            task["assignedUsers"] ??
            task["AssignedUsers"],
      );
    }
  }
  return names;
}

String _goalKey(Map<String, dynamic> goal) {
  final code = _goalCode(goal);
  if (code.isNotEmpty) return "code:$code";
  final id = _goalId(goal);
  if (id.isNotEmpty && id != "null") return "id:$id";
  return "title:${goal["title"]}";
}

int _taskCount(Map<String, dynamic> goal) {
  final tasks = goal["tasks"];
  return tasks is List ? tasks.length : 0;
}

int _monthCount(Map<String, dynamic> goal) {
  final months = goal["monthlyGoals"];
  return months is List ? months.length : 0;
}

const _assignmentKeys = [
  "yearlyAssignedUserIds",
  "YearlyAssignedUserIds",
  "yearlyAssignedUsers",
  "YearlyAssignedUsers",
  "assignedUserIds",
  "AssignedUserIds",
  "assignedUsers",
  "AssignedUsers",
  "assignedTo",
  "AssignedTo",
  "createdBy",
  "CreatedBy",
  "createdById",
  "CreatedById",
  "createdByName",
  "assignBy",
];

void _keepAssignment(Map<String, dynamic> into, Map<String, dynamic> from) {
  for (final key in _assignmentKeys) {
    final current = into[key];
    final empty = current == null ||
        (current is String &&
            (current.trim().isEmpty || current.trim().toLowerCase() == "n/a")) ||
        (current is List && current.isEmpty);
    if (!empty) continue;
    final incoming = from[key];
    if (incoming == null) continue;
    if (incoming is String && incoming.trim().isEmpty) continue;
    if (incoming is List && incoming.isEmpty) continue;
    into[key] = incoming;
  }
}

void _keepQuantity(Map<String, dynamic> into, Map<String, dynamic> from) {
  if (goalTarget(into) <= 0 && goalTarget(from) > 0) {
    into["targetQuantity"] = goalTarget(from);
  }
  if (goalDone(from) > goalDone(into)) {
    into["completedQuantity"] = goalDone(from);
  }
  if (_taskCount(into) == 0 && _taskCount(from) > 0) {
    into["tasks"] = from["tasks"];
  }
}

List<Map<String, dynamic>> _monthList(Map<String, dynamic> goal) {
  final months = goal["monthlyGoals"];
  if (months is! List) return [];
  return months.whereType<Map<String, dynamic>>().toList();
}

List<Map<String, dynamic>> _mergeMonths(
  List<Map<String, dynamic>> primary,
  List<Map<String, dynamic>> extra,
) {
  final map = <String, Map<String, dynamic>>{};
  for (final month in primary) {
    map[_goalKey(month)] = Map<String, dynamic>.from(month);
  }
  for (final month in extra) {
    final copy = Map<String, dynamic>.from(month);
    final key = _goalKey(copy);
    final existing = map[key];
    if (existing == null) {
      map[key] = copy;
      continue;
    }
    _keepQuantity(existing, copy);
  }
  return map.values.toList();
}

List<dynamic> _mergeGoalLists(List<List<dynamic>> chunks) {
  final map = <String, Map<String, dynamic>>{};
  for (final chunk in chunks) {
    for (final raw in chunk) {
      final goal = _normalizeGoal(raw);
      if (goal.isEmpty) continue;
      final key = _goalKey(goal);
      final existing = map[key];
      if (existing == null) {
        map[key] = goal;
        continue;
      }
      if (_monthCount(goal) > _monthCount(existing) ||
          (_monthCount(goal) == _monthCount(existing) &&
              _taskCount(goal) > _taskCount(existing))) {
        final kept = {
          ...goal,
          "parentGoalId": goal["parentGoalId"] ?? existing["parentGoalId"],
        };
        _keepAssignment(kept, existing);
        _keepQuantity(kept, existing);
        kept["monthlyGoals"] = _mergeMonths(
          _monthList(kept),
          _monthList(existing),
        );
        map[key] = kept;
      } else {
        existing["parentGoalId"] ??= goal["parentGoalId"];
        _keepAssignment(existing, goal);
        existing["monthlyGoals"] = _mergeMonths(
          _monthList(existing),
          _monthList(goal),
        );
        _keepQuantity(existing, goal);
      }
    }
  }
  return map.values.toList();
}

List<Map<String, dynamic>> goalsForCards(List<dynamic> raw) {
  return _buildGoalTree(raw).map((node) => node.goal).toList();
}

Set<String> _listedMonthKeys(List<dynamic> raw) {
  final keys = <String>{};

  void take(dynamic item) {
    final goal = _normalizeGoal(item);
    if (goal.isEmpty) return;
    if (!isYearlyGoal(goal)) {
      keys.add(_goalKey(goal));
      return;
    }
    final months = goal["monthlyGoals"];
    if (months is! List) return;
    for (final month in months) {
      take(month);
    }
  }

  for (final item in raw) {
    take(item);
  }
  return keys;
}

Set<String> _listedYearlyKeys(List<dynamic> raw) {
  final keys = <String>{};
  for (final item in raw) {
    final goal = _normalizeGoal(item);
    if (goal.isEmpty || !isYearlyGoal(goal)) continue;
    keys.add(_goalKey(goal));
  }
  return keys;
}

/// Yearly assignees get the yearly goal and every month under it.
/// Other people get only the months assigned to them, without the yearly goal.
List<Map<String, dynamic>> _goalsVisibleTo(
  List<dynamic> raw,
  int userId, {
  Set<String> listedMonthKeys = const {},
  Set<String> listedYearlyKeys = const {},
}) {
  final goals = <Map<String, dynamic>>[];
  final seen = <String>{};
  final normalized = raw
      .map(_normalizeGoal)
      .where((goal) => goal.isNotEmpty)
      .toList();
  final yearlyById = <String, Map<String, dynamic>>{};

  for (final goal in normalized) {
    if (!isYearlyGoal(goal)) continue;
    final id = _goalId(goal);
    if (id.isEmpty || id == "null") continue;
    yearlyById.putIfAbsent(id, () => goal);
  }

  bool yearlyVisible(Map<String, dynamic> goal) {
    return showYearlyGoalTo(
      goal,
      userId,
      listedForUser: listedYearlyKeys.contains(_goalKey(goal)),
    );
  }

  void add(Map<String, dynamic> goal) {
    if (goal.isEmpty) return;
    if (!seen.add(_goalKey(goal))) return;
    goals.add(goal);
  }

  void attachMonth(Map<String, dynamic> yearly, Map<String, dynamic> month) {
    final card = _asMonthlyGoal(_normalizeGoal(month));
    if (card.isEmpty) return;
    final months = yearly["monthlyGoals"];
    final list = months is List
        ? months.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final key = _goalKey(card);
    if (list.any((item) => _goalKey(item) == key)) return;
    list.add(card);
    yearly["monthlyGoals"] = list;
  }

  for (final goal in normalized) {
    if (isYearlyGoal(goal)) continue;
    final parent = yearlyById[_parentGoalId(goal)];
    if (parent == null || !yearlyVisible(parent)) continue;
    attachMonth(parent, goal);
  }

  for (final goal in normalized) {
    if (isYearlyGoal(goal)) {
      if (!yearlyVisible(goal)) {
        final months = goal["monthlyGoals"];
        if (months is! List) continue;
        for (final month in months) {
          if (month is! Map) continue;
          final card = _asMonthlyGoal(_normalizeGoal(month));
          if (showMonthGoalTo(
            card,
            userId,
            listedForUser: listedMonthKeys.contains(_goalKey(card)),
          )) {
            add(card);
          }
        }
        continue;
      }
      goal["goalType"] = "Yearly";
      add(goal);
      continue;
    }

    final parent = yearlyById[_parentGoalId(goal)];
    if (parent != null && yearlyVisible(parent)) continue;
    if (showMonthGoalTo(
      goal,
      userId,
      listedForUser: listedMonthKeys.contains(_goalKey(goal)),
    )) {
      add(_asMonthlyGoal(goal));
    }
  }
  return goals;
}

List<Map<String, dynamic>> goalsVisibleToUser(
  List<dynamic> raw, {
  required int userId,
  List<dynamic> listedForUser = const [],
}) {
  return _goalsVisibleTo(
    raw,
    userId,
    listedMonthKeys: _listedMonthKeys(listedForUser),
    listedYearlyKeys: _listedYearlyKeys(listedForUser),
  );
}

String taskGoalCode(Map task) {
  return (task["goalCode"] ?? task["GoalCode"] ?? task["goal_code"] ?? "")
      .toString()
      .trim();
}

String taskCodeOf(Map task) {
  return (task["taskCode"] ?? task["TaskCode"] ?? "").toString().trim();
}

/// Nest flat tasks under matching goals (and monthly goals) by [goalCode].
/// Returns tasks that still have no related goal.
List<Map<String, dynamic>> attachTasksToGoals(
  List goals,
  List flatTasks,
) {
  final byGoalCode = <String, List<Map<String, dynamic>>>{};
  final orphans = <Map<String, dynamic>>[];

  for (final raw in flatTasks) {
    if (raw is! Map) continue;
    final task = Map<String, dynamic>.from(raw);
    final code = taskGoalCode(task);
    if (code.isEmpty || code.toLowerCase() == "null") {
      orphans.add(task);
      continue;
    }
    byGoalCode.putIfAbsent(code.toLowerCase(), () => []).add(task);
  }

  void mergeInto(Map<String, dynamic> goal) {
    final code = _goalCode(goal).toLowerCase();
    final incoming = code.isEmpty
        ? const <Map<String, dynamic>>[]
        : (byGoalCode.remove(code) ?? const []);

    final existing = <Map<String, dynamic>>[];
    final seen = <String>{};
    void take(dynamic item) {
      if (item is! Map) return;
      final copy = Map<String, dynamic>.from(item);
      final key = taskCodeOf(copy);
      if (key.isNotEmpty && !seen.add(key)) return;
      if (key.isEmpty) seen.add("row:${existing.length}");
      existing.add(copy);
    }

    final current = goal["tasks"];
    if (current is List) {
      for (final item in current) {
        take(item);
      }
    }
    for (final item in incoming) {
      take(item);
    }
    goal["tasks"] = existing;

    final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
    if (months is List) {
      for (var i = 0; i < months.length; i++) {
        final month = months[i];
        if (month is! Map) continue;
        final monthMap = month is Map<String, dynamic>
            ? month
            : Map<String, dynamic>.from(month);
        mergeInto(monthMap);
        months[i] = monthMap;
      }
    }
  }

  for (final goal in goals) {
    if (goal is Map<String, dynamic>) {
      mergeInto(goal);
    } else if (goal is Map) {
      mergeInto(Map<String, dynamic>.from(goal));
    }
  }

  for (final leftover in byGoalCode.values) {
    orphans.addAll(leftover);
  }
  return orphans;
}

List<_GoalNode> _buildGoalTree(List<dynamic> raw) {
  final goals = raw.map(_normalizeGoal).where((item) => item.isNotEmpty).toList();
  final byKey = <String, Map<String, dynamic>>{
    for (final goal in goals) _goalKey(goal): goal,
  };

  void remember(Map<String, dynamic> goal) {
    final key = _goalKey(goal);
    byKey.putIfAbsent(key, () => goal);
  }

  for (final goal in [...goals]) {
    final nested = goal["monthlyGoals"];
    if (nested is! List) continue;
    for (final month in nested) {
      if (month is Map<String, dynamic> && month.isNotEmpty) {
        remember(_asMonthlyGoal(month));
      }
    }
  }

  final yearly = byKey.values
      .where((goal) =>
          _goalType(goal) == "yearly" || _monthCount(goal) > 0)
      .toList();
  final yearlyIds = yearly.map(_goalId).where((id) => id.isNotEmpty && id != "null").toSet();

  final children = <String, List<Map<String, dynamic>>>{};
  final standalone = <Map<String, dynamic>>[];
  final nestedKeys = <String>{};

  for (final goal in byKey.values) {
    if (_goalType(goal) == "yearly") continue;
    final parentId = _parentGoalId(goal);
    final hasYearlyParent =
        parentId.isNotEmpty && parentId != "null" && yearlyIds.contains(parentId);
    if (hasYearlyParent) {
      children.putIfAbsent(parentId, () => []).add(_asMonthlyGoal(goal));
      nestedKeys.add(_goalKey(goal));
    } else {
      standalone.add(goal);
    }
  }

  final nodes = <_GoalNode>[];
  for (final yearlyGoal in yearly) {
    final months = <Map<String, dynamic>>[];

    void addMonth(Map<String, dynamic> month) {
      final card = _asMonthlyGoal(month);
      final key = _goalKey(card);
      final index = months.indexWhere((item) => _goalKey(item) == key);
      if (index >= 0) {
        _keepQuantity(months[index], card);
        return;
      }
      months.add(card);
      nestedKeys.add(key);
    }

    final nested = yearlyGoal["monthlyGoals"];
    if (nested is List) {
      for (final month in nested) {
        if (month is Map<String, dynamic>) addMonth(month);
      }
    }
    for (final month in children[_goalId(yearlyGoal)] ?? const []) {
      addMonth(month);
    }

    final card = _withMonths(yearlyGoal, months);
    nodes.add(_GoalNode(card, months));
  }

  for (final month in standalone) {
    if (nestedKeys.contains(_goalKey(month))) continue;
    nodes.add(_GoalNode(month));
  }

  return nodes;
}
