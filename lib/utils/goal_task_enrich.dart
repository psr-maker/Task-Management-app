import 'package:flutter/foundation.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';

List<Map<String, dynamic>> collectGoalTasks(Map goal) {
  final result = <Map<String, dynamic>>[];

  void walk(Map goalMap) {
    final tasks = goalMap["tasks"];
    if (tasks is List) {
      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        if (task is Map<String, dynamic>) {
          result.add(task);
        } else if (task is Map) {
          final copy = Map<String, dynamic>.from(task);
          tasks[i] = copy;
          result.add(copy);
        }
      }
    }
    final months = goalMap["monthlyGoals"] ?? goalMap["MonthlyGoals"];
    if (months is List) {
      for (var i = 0; i < months.length; i++) {
        final month = months[i];
        if (month is! Map) continue;
        final monthMap = month is Map<String, dynamic>
            ? month
            : Map<String, dynamic>.from(month);
        if (!identical(month, monthMap)) months[i] = monthMap;
        walk(monthMap);
      }
    }
  }

  walk(goal);
  return result;
}

Map<String, dynamic> _asTaskMap(Map raw) {
  for (final key in ["task", "data", "result"]) {
    final nested = raw[key];
    if (nested is Map) return Map<String, dynamic>.from(nested);
  }
  return Map<String, dynamic>.from(raw);
}

/// Loads latest quantity / completed values for nested tasks, then syncs goal progress.
Future<bool> enrichGoalTaskQuantities(Map goal) async {
  final tasks = collectGoalTasks(goal);
  if (tasks.isEmpty) {
    syncGoalTreeProgress(goal);
    return false;
  }

  var changed = false;
  await Future.wait(tasks.map((task) async {
    final code =
        (task["taskCode"] ?? task["TaskCode"] ?? "").toString().trim();
    if (code.isEmpty) return;
    try {
      final details = _asTaskMap(await SuperAdminService.getTaskByCode(code));
      final done = readGoalInt(details, const [
        "completedQuantity",
        "CompletedQuantity",
        "achievedQuantity",
        "AchievedQuantity",
      ]);
      final qty = readGoalInt(details, const [
        "quantity",
        "Quantity",
        "qty",
        "Qty",
        "taskQuantity",
        "TaskQuantity",
      ]);
      final splits = details["quantitySplits"] ?? details["QuantitySplits"];
      final people = details["assignedTo"] ?? details["AssignedTo"];
      final status = details["status"] ?? details["Status"];
      final type = details["performanceType"] ?? details["PerformanceType"];

      if (done != null) {
        final current = readGoalInt(task, const [
          "completedQuantity",
          "CompletedQuantity",
          "achievedQuantity",
          "AchievedQuantity",
        ]);
        if (current != done) {
          task["completedQuantity"] = done;
          changed = true;
        }
      }
      if (qty != null && qty > 0 && taskAssignedQty(task) != qty) {
        task["quantity"] = qty;
        changed = true;
      }
      if (splits is List) {
        task["quantitySplits"] = splits;
        changed = true;
      }
      if (people is List) {
        task["assignedTo"] = people;
        changed = true;
      }
      if (status != null &&
          (task["status"]?.toString() ?? "") != status.toString()) {
        task["status"] = status;
        changed = true;
      }
      if (type != null) {
        task["performanceType"] = type;
        changed = true;
      }
    } catch (e) {
      debugPrint("Goal task quantity enrich failed: $e");
    }
  }));

  syncGoalTreeProgress(goal);
  return changed;
}

void syncGoalTreeProgress(Map goal) {
  final months = <Map>[];
  final raw = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
  if (raw is List) {
    for (final month in raw) {
      if (month is Map) months.add(month);
    }
  }
  final isYearly = (goal["goalType"] ?? goal["GoalType"] ?? "")
          .toString()
          .toLowerCase() ==
      "yearly" ||
      months.isNotEmpty;
  syncGoalProgress(
    goal,
    months: isYearly ? months : null,
    tasks: isYearly ? null : (goal["tasks"] is List ? goal["tasks"] : null),
    preferMonthTotals: isYearly,
  );
}
