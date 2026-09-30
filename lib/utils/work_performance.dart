import 'package:flutter/foundation.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class WorkPerformance {
  final double completion;
  final double onTime;
  final double delayed;

  const WorkPerformance({
    required this.completion,
    required this.onTime,
    required this.delayed,
  });

  static const zero = WorkPerformance(completion: 0, onTime: 0, delayed: 0);

  static WorkPerformance fromLists(List goals, List tasks) {
    var total = 0;
    var completed = 0;
    var onTime = 0;
    var delayed = 0;

    void take(dynamic raw) {
      if (raw is! Map) return;
      final item = Map<String, dynamic>.from(raw);
      total++;
      if (!isCompletedWork(item)) return;
      completed++;
      if (isCompletedLate(item)) {
        delayed++;
      } else {
        onTime++;
      }
    }

    for (final goal in goals) {
      take(goal);
    }
    for (final task in tasks) {
      take(task);
    }

    double share(int part, int whole) {
      if (whole == 0) return 0;
      return (part / whole) * 100;
    }

    return WorkPerformance(
      completion: share(completed, total),
      onTime: share(onTime, completed),
      delayed: share(delayed, completed),
    );
  }
}

class TaskTiming {
  final double? onTime;
  final double? delayed;

  const TaskTiming({this.onTime, this.delayed});

  static const empty = TaskTiming();

  static TaskTiming fromTasks(List tasks, {int? year}) {
    final items = [
      for (final task in tasks)
        if (task is Map && _inYear(Map<String, dynamic>.from(task), year))
          task,
    ];
    if (items.isEmpty) return empty;
    final score = WorkPerformance.fromLists(const [], items);
    return TaskTiming(onTime: score.onTime, delayed: score.delayed);
  }

  static Future<TaskTiming> load({
    int? userId,
    String? department,
    int? year,
  }) async {
    try {
      final report = await ReportsService.getFullReport(
        userId: userId,
        department: department,
      );
      final tasks = report["tasks"];
      if (tasks is! List) return empty;
      return fromTasks(tasks, year: year);
    } catch (error) {
      debugPrint('Task timing: $error');
      return empty;
    }
  }

  static Future<TaskTiming> loadDepartments(
    List<String> departments, {
    int? year,
  }) async {
    final tasks = <dynamic>[];
    for (final department in departments) {
      try {
        final report = await ReportsService.getFullReport(
          department: department,
        );
        final list = report["tasks"];
        if (list is List) tasks.addAll(list);
      } catch (error) {
        debugPrint('Task timing: $error');
      }
    }
    return fromTasks(tasks, year: year);
  }
}

bool _inYear(Map<String, dynamic> item, int? year) {
  if (year == null) return true;
  final due = _parseDate(item['dueDate'] ?? item['due_Date'] ?? item['DueDate']);
  final completed = _parseDate(
    item['completed_Date'] ?? item['completedDate'] ?? item['CompletedDate'],
  );
  final date = due ?? completed;
  if (date == null) return true;
  return date.year == year;
}

bool isCompletedWork(Map<String, dynamic> item) {
  final status = AppHelpers.normalize(
    (item['status'] ?? item['Status'] ?? '').toString(),
  );
  return status == 'completed';
}

bool isCompletedLate(Map<String, dynamic> item) {
  final completed = _dateOnly(
    _parseDate(
      item['completed_Date'] ?? item['completedDate'] ?? item['CompletedDate'],
    ),
  );
  final due = _dateOnly(
    _parseDate(item['dueDate'] ?? item['due_Date'] ?? item['DueDate']),
  );
  if (completed == null || due == null) return false;
  return completed.isAfter(due);
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.startsWith('0001-01-01')) return null;
  return DateTime.tryParse(text);
}

DateTime? _dateOnly(DateTime? value) {
  if (value == null) return null;
  return DateTime(value.year, value.month, value.day);
}
