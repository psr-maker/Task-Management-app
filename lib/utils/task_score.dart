import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/time_utils.dart';

const int taskScoreMax = 90;

/// Same rules as the API `CalculateTaskScore`.
int calculateTaskScore({
  required DateTime dueDate,
  DateTime? completedDate,
  String? priority,
  Duration? endTime,
  required DateTime startDate,
  int? targetQuantity,
  int? completedQuantity,
}) {
  if (completedDate == null) return 0;

  final timeScore = _timeScore(
    dueDate: dueDate,
    completedDate: completedDate,
    endTime: endTime,
    startDate: startDate,
  );

  final priorityBonus = switch (priority?.toLowerCase()) {
    'high' => 5,
    'medium' => 3,
    _ => 0,
  };

  var normalScore = (timeScore + priorityBonus).clamp(50, taskScoreMax);

  if (targetQuantity == null) return normalScore;
  if (completedQuantity == null) return 0;

  final target = targetQuantity;
  if (target <= 0) return normalScore;

  var completed = completedQuantity;
  if (completed < 0) completed = 0;
  if (completed >= target) return normalScore;

  final quantityScore = _roundAwayFromZero(normalScore * (completed / target));
  return quantityScore.clamp(0, taskScoreMax);
}

int? taskSystemScore(Map task, {int? userId}) {
  final due = TimeUtils.tryParse(
    task['dueDate'] ?? task['due_Date'] ?? task['DueDate'],
  );
  final start = TimeUtils.tryParse(
    task['startDate'] ??
        task['start_date'] ??
        task['StartDate'] ??
        task['assignedAt'] ??
        task['createdAt'],
  );
  if (due == null || start == null) return null;

  final completed = TimeUtils.tryParse(
    task['completedDate'] ??
        task['completed_date'] ??
        task['CompletedDate'] ??
        task['completed_Date'],
  );

  int? target;
  int? done;
  final type = (task['performanceType'] ?? task['PerformanceType'] ?? '')
      .toString()
      .toLowerCase();
  final memberTarget = userId == null ? null : memberShareQuantity(task, userId);
  final memberDone = userId == null ? null : memberShareCompleted(task, userId);
  if (memberTarget != null) {
    target = memberTarget;
    done = memberDone ?? 0;
  } else if (type == 'qty' ||
      readGoalInt(task, const [
            'targetQuantity',
            'TargetQuantity',
            'quantity',
            'Quantity',
          ]) !=
          null) {
    target = readGoalInt(task, const [
      'targetQuantity',
      'TargetQuantity',
      'quantity',
      'Quantity',
    ]);
    done = readGoalInt(task, const [
      'completedQuantity',
      'CompletedQuantity',
      'achievedQuantity',
      'AchievedQuantity',
    ]);
  }

  return calculateTaskScore(
    dueDate: due,
    completedDate: completed,
    priority: (task['priority'] ?? task['Priority'])?.toString(),
    endTime: _endTime(
      task['endTime'] ?? task['EndTime'],
    ),
    startDate: start,
    targetQuantity: target,
    completedQuantity: done,
  );
}

int _timeScore({
  required DateTime dueDate,
  required DateTime completedDate,
  required Duration? endTime,
  required DateTime startDate,
}) {
  final sameDay = _isSameDate(startDate, dueDate) &&
      _isSameDate(completedDate, dueDate);

  if (endTime != null) {
    final dueDateTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).add(endTime);
    final difference = completedDate.difference(dueDateTime);
    if (difference < Duration.zero) return 90;
    if (difference == Duration.zero) return 85;
    final lateHours = (difference.inMicroseconds / Duration.microsecondsPerHour)
        .ceil();
    return (85 - (lateHours * 5)).clamp(50, 90);
  }

  if (sameDay) return 90;

  final lateDays = DateTime(completedDate.year, completedDate.month, completedDate.day)
      .difference(DateTime(dueDate.year, dueDate.month, dueDate.day))
      .inDays;
  if (lateDays < 0) return 90;
  if (lateDays == 0) return 85;
  if (lateDays == 1) return 80;
  if (lateDays == 2) return 75;
  if (lateDays == 3) return 70;
  if (lateDays == 4) return 65;
  if (lateDays == 5) return 60;
  if (lateDays == 6) return 55;
  return 50;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Duration? _endTime(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;

  final clock = text.toUpperCase();
  if (clock.endsWith('AM') || clock.endsWith('PM')) {
    final isPm = clock.endsWith('PM');
    final hm = clock.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
    if (hm.length < 2) return null;
    var hour = int.tryParse(hm[0].trim());
    final minute = int.tryParse(hm[1].trim());
    if (hour == null || minute == null) return null;
    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return Duration(hours: hour, minutes: minute);
  }

  final parsed = TimeUtils.tryParse(text);
  if (parsed != null && (text.contains('T') || text.contains('-'))) {
    return Duration(hours: parsed.hour, minutes: parsed.minute, seconds: parsed.second);
  }

  final parts = text.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0].trim());
  final minute = int.tryParse(parts[1].trim());
  final second = parts.length > 2 ? int.tryParse(parts[2].trim()) ?? 0 : 0;
  if (hour == null || minute == null) return null;
  return Duration(hours: hour, minutes: minute, seconds: second);
}

int _roundAwayFromZero(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  final negative = value < 0;
  final abs = value.abs();
  final base = abs.floor();
  final fraction = abs - base;
  final rounded = fraction >= 0.5 ? base + 1 : base;
  return negative ? -rounded : rounded;
}
