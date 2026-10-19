int? readPersonId(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    final id = raw.round();
    return id > 0 ? id : null;
  }
  if (raw is Map) {
    final nested = raw["user"] ?? raw["User"];
    final source = nested is Map ? nested : raw;
    for (final key in [
      "userId",
      "UserId",
      "staffId",
      "StaffId",
      "employeeId",
      "EmployeeId",
      "uid",
      "Uid",
      "id",
      "Id",
    ]) {
      final id = readPersonId(source[key]);
      if (id != null) return id;
    }
    return null;
  }
  final text = raw.toString().trim();
  if (text.isEmpty || text.toLowerCase() == "null") return null;
  final head = text.contains("-") ? text.split("-").first.trim() : text;
  final id = int.tryParse(head);
  return id != null && id > 0 ? id : null;
}

Set<int> personIdsFrom(dynamic raw) {
  final ids = <int>{};
  if (raw is List) {
    for (final item in raw) {
      final id = readPersonId(item);
      if (id != null) ids.add(id);
    }
    return ids;
  }
  final id = readPersonId(raw);
  if (id != null) ids.add(id);
  return ids;
}

/// People assigned to the yearly goal itself.
/// Falls back to the goal's own assignees, and leaves out the assigner
/// unless they are listed in the yearly assignment.
Set<int> yearlyAssigneeIds(Map goal) {
  final explicit = <int>{};
  for (final key in const [
    "yearlyAssignedUserIds",
    "YearlyAssignedUserIds",
    "yearlyAssignedUsers",
    "YearlyAssignedUsers",
  ]) {
    explicit.addAll(personIdsFrom(goal[key]));
  }
  if (explicit.isNotEmpty) return explicit;
  return goalAssigneeIds(goal);
}

Set<int> goalAssigneeIds(Map goal) {
  final ids = <int>{};
  for (final key in const [
    "assignedUserIds",
    "AssignedUserIds",
    "assignedUsers",
    "AssignedUsers",
    "assignedTo",
    "AssignedTo",
    "assignments",
    "goalAssignments",
  ]) {
    ids.addAll(personIdsFrom(goal[key]));
  }
  return ids;
}

int? goalAssignerId(Map goal) {
  for (final key in const [
    "createdById",
    "CreatedById",
    "assignById",
    "assignedById",
    "createdBy",
    "CreatedBy",
  ]) {
    final id = readPersonId(goal[key]);
    if (id != null) return id;
  }
  return null;
}

/// Yearly goal is visible to the users assigned on that yearly goal.
/// [listedForUser] shows a yearly goal from that user's own list when the
/// payload has no assignee ids yet.
bool showYearlyGoalTo(
  Map goal,
  int userId, {
  bool listedForUser = false,
}) {
  final assignees = yearlyAssigneeIds(goal);
  if (assignees.isNotEmpty) return assignees.contains(userId);
  return listedForUser;
}

/// A monthly goal is visible when [userId] is assigned on that month.
/// [listedForUser] keeps a month that came from that user's own goal list
/// when the month has no assignee payload.
bool showMonthGoalTo(
  Map goal,
  int userId, {
  bool listedForUser = false,
}) {
  final assignees = goalAssigneeIds(goal);
  if (assignees.isNotEmpty) return assignees.contains(userId);
  return listedForUser;
}

bool isYearlyGoal(Map goal) {
  final type = (goal["goalType"] ?? goal["GoalType"] ?? "")
      .toString()
      .trim()
      .toLowerCase();
  if (type == "yearly") return true;
  if (type == "monthly") return false;
  final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
  return months is List && months.isNotEmpty;
}
