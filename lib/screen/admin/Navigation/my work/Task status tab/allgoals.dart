import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

class Allgoals extends StatefulWidget {
  final String searchQuery;
  final TaskFilterModel? filter;
  final String goalType;
  final bool onlyMine;
  final Function(String, bool)? onDelete;

  const Allgoals({
    super.key,
    required this.searchQuery,
    this.filter,
    this.goalType = "All",
    this.onlyMine = false,
    this.onDelete,
  });

  @override
  State<Allgoals> createState() => _AllgoalsState();
}

class _AllgoalsState extends State<Allgoals> {
  List<_GoalNode> goals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGoals(showLoader: true);
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
    return mine.map((raw) {
      final goal = _normalizeGoal(raw);
      _keepLoginUserTasks(goal, byCode, userId);
      return goal;
    }).where((goal) => goal.isNotEmpty).toList();
  }

  Future<void> loadGoals({bool showLoader = false}) async {
    try {
      if (showLoader && mounted) setState(() => isLoading = true);
      final data = await _fetchGoals();
      if (!mounted) return;
      setState(() {
        goals = _buildGoalTree(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<_GoalNode> get filteredGoals {
    String normalize(String value) {
      return value.toLowerCase().replaceAll(" ", "").replaceAll("_", "");
    }

    bool matches(Map<String, dynamic> goal) {
      if (widget.searchQuery.isNotEmpty &&
          !(goal["title"] ?? "").toString().toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          )) {
        return false;
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

      if (widget.filter?.department != null &&
          (goal["department"] ?? "").toString().toLowerCase() !=
              widget.filter!.department!.toLowerCase()) {
        return false;
      }

      return true;
    }

    final result = <_GoalNode>[];
    for (final node in goals) {
      final isYearly = _goalType(node.goal) == 'yearly';
      if (widget.goalType == 'Yearly' && !isYearly) continue;
      if (widget.goalType == 'Monthly' && isYearly) continue;

      final monthMatches = node.months.where(matches).toList();
      if (isYearly) {
        final showParent = matches(node.goal);
        if (!showParent && monthMatches.isEmpty) continue;
        final months = showParent ? node.months : monthMatches;
        result.add(_GoalNode(_withMonths(node.goal, months), months));
      } else if (matches(node.goal)) {
        result.add(node);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
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
        _keepQuantity(kept, existing);
        kept["monthlyGoals"] = _mergeMonths(
          _monthList(kept),
          _monthList(existing),
        );
        map[key] = kept;
      } else {
        existing["parentGoalId"] ??= goal["parentGoalId"];
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
