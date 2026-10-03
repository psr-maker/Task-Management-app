class GoalQuantityView {
  final int target;
  final int done;
  final int pending;

  const GoalQuantityView({
    required this.target,
    required this.done,
    required this.pending,
  });

  double get fraction {
    if (target <= 0) return 0;
    final value = done / target;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  int get percent => quantityPercent(done, target);
}

int? readGoalInt(Map goal, List<String> keys) {
  for (final key in keys) {
    final raw = goal[key];
    if (raw == null) continue;
    if (raw is num) return raw.round();
    final parsed = num.tryParse(raw.toString().trim());
    if (parsed != null) return parsed.round();
  }
  return null;
}

int goalTarget(Map goal) {
  return readGoalInt(goal, const [
        "targetQuantity",
        "TargetQuantity",
        "quantity",
        "Quantity",
      ]) ??
      0;
}

int goalDone(Map goal) {
  return readGoalInt(goal, const [
        "completedQuantity",
        "CompletedQuantity",
      ]) ??
      0;
}

int monthTargetTotal(Iterable<Map> months) {
  var total = 0;
  for (final month in months) {
    total += goalTarget(month);
  }
  return total;
}

int taskAssignedQty(Map task) {
  return readGoalInt(task, const [
        "quantity",
        "Quantity",
        "qty",
        "Qty",
        "taskQuantity",
        "TaskQuantity",
      ]) ??
      0;
}

int taskAchievedQty(Map task) {
  final fromShares = _shareTotal(task, const [
    "completedQuantity",
    "CompletedQuantity",
    "achievedQuantity",
    "AchievedQuantity",
  ]);
  final stored = readGoalInt(task, const [
        "completedQuantity",
        "CompletedQuantity",
        "achievedQuantity",
        "AchievedQuantity",
      ]) ??
      0;
  return fromShares > stored ? fromShares : stored;
}

List<dynamic> _shareMemberList(Map share) {
  final members = share["memberIds"] ??
      share["MemberIds"] ??
      share["assignedTo"] ??
      share["AssignedTo"] ??
      share["members"] ??
      share["Members"];
  if (members is List) return members;
  return const [];
}

int? shareMemberId(dynamic member) {
  if (member is Map) {
    final nested = member["user"] ?? member["User"];
    final source = nested is Map ? nested : member;
    return shareMemberId(
      source["userId"] ?? source["UserId"] ?? source["id"] ?? source["Id"],
    );
  }
  if (member == null) return null;
  final text = member.toString().trim();
  if (text.isEmpty || text == "null") return null;
  if (text.contains("-")) {
    return int.tryParse(text.split("-").first.trim());
  }
  return int.tryParse(text);
}

bool shareContainsUser(dynamic member, int userId) {
  return shareMemberId(member) == userId;
}

/// People on the same quantity share as [userId].
/// Null when this task is not split, or this user is not on a share.
Set<int>? quantityShareMemberIds(Map task, int userId) {
  final shares = task["quantitySplits"] ??
      task["QuantitySplits"] ??
      task["splits"];
  if (shares is List) {
    for (final share in shares) {
      if (share is! Map) continue;
      final members = _shareMemberList(share);
      if (!members.any((member) => shareContainsUser(member, userId))) {
        continue;
      }
      final ids = <int>{};
      for (final member in members) {
        final id = shareMemberId(member);
        if (id != null) ids.add(id);
      }
      if (ids.isNotEmpty) return ids;
    }
  }

  final people = task["assignedTo"] ?? task["AssignedTo"];
  if (people is! List) return null;
  Object? splitId;
  for (final person in people) {
    if (person is! Map || !shareContainsUser(person, userId)) continue;
    splitId = person["splitId"] ?? person["SplitId"];
    break;
  }
  if (splitId == null) return null;
  final ids = <int>{};
  for (final person in people) {
    if (person is! Map) continue;
    if ((person["splitId"] ?? person["SplitId"]) != splitId) continue;
    final id = shareMemberId(person);
    if (id != null) ids.add(id);
  }
  return ids.isEmpty ? null : ids;
}

int? memberShareQuantity(Map task, int userId) {
  final shares = task["quantitySplits"] ??
      task["QuantitySplits"] ??
      task["splits"];
  if (shares is! List) return null;
  for (final share in shares) {
    if (share is! Map) continue;
    final members = _shareMemberList(share);
    if (!members.any((member) => shareContainsUser(member, userId))) continue;
    return readGoalInt(share, const ["quantity", "Quantity"]);
  }
  return null;
}

String viewerTaskStatus(Map task, int userId) {
  final mine = memberUserStatus(task, userId);
  if (mine != null) return mine;
  final own = task["userStatus"] ?? task["UserStatus"];
  if (own != null && own.toString().trim().isNotEmpty) {
    return own.toString();
  }
  return (task["status"] ?? task["Status"] ?? "").toString();
}

String? memberUserStatus(Map task, int userId) {
  final people = task["assignedTo"] ?? task["AssignedTo"];
  if (people is! List) return null;
  for (final person in people) {
    if (person is! Map) continue;
    final id = int.tryParse("${person["userId"] ?? person["UserId"]}");
    if (id != userId) continue;
    final status = person["userStatus"] ?? person["UserStatus"];
    if (status == null) return null;
    final text = status.toString().trim();
    return text.isEmpty ? null : text;
  }
  return null;
}

bool allQuantitySharesCompleted(Map task) {
  final shares = task["quantitySplits"] ?? task["QuantitySplits"];
  final people = task["assignedTo"] ?? task["AssignedTo"];
  if (shares is! List || shares.isEmpty || people is! List) return false;
  for (final share in shares) {
    if (share is! Map) return false;
    final splitId = share["id"] ?? share["Id"];
    final members = people.where((person) {
      if (person is! Map) return false;
      final personSplit = person["splitId"] ?? person["SplitId"];
      return personSplit == splitId;
    });
    if (members.isEmpty) return false;
    final done = members.every((person) {
      final status = (person["userStatus"] ?? person["UserStatus"] ?? "")
          .toString()
          .toLowerCase();
      return status == "completed";
    });
    if (!done) return false;
  }
  return true;
}

int? memberShareCompleted(Map task, int userId) {
  final shares = task["quantitySplits"] ??
      task["QuantitySplits"] ??
      task["splits"];
  if (shares is! List) return null;
  for (final share in shares) {
    if (share is! Map) continue;
    final members = _shareMemberList(share);
    if (!members.any((member) => shareContainsUser(member, userId))) continue;
    return readGoalInt(share, const [
          "completedQuantity",
          "CompletedQuantity",
        ]) ??
        0;
  }
  return null;
}

int _shareTotal(Map task, List<String> keys) {
  final shares = task["quantitySplits"] ??
      task["QuantitySplits"] ??
      task["splits"] ??
      task["members"];
  if (shares is! List) return 0;
  var total = 0;
  for (final share in shares) {
    if (share is Map) {
      total += readGoalInt(share, keys) ?? 0;
    }
  }
  return total;
}

int tasksAchievedTotal(Iterable tasks) {
  var total = 0;
  for (final item in tasks) {
    if (item is Map) total += taskAchievedQty(item);
  }
  return total;
}

int monthAchieved(Map month) {
  final tasks = month["tasks"];
  final fromTasks = tasks is List ? tasksAchievedTotal(tasks) : 0;
  final stored = goalDone(month);
  return fromTasks > stored ? fromTasks : stored;
}

int monthDoneTotal(Iterable<Map> months) {
  var total = 0;
  for (final month in months) {
    total += monthAchieved(month);
  }
  return total;
}

int quantityPercent(int achieved, int target) {
  if (target <= 0) return 0;
  return ((achieved * 100) / target).round();
}

String formatQuantityPercent(int percent) {
  if (percent > 100) return "$percent% ↑";
  return "$percent%";
}

GoalQuantityView? goalQuantityView(
  Map goal, {
  Iterable<Map>? months,
  Iterable? tasks,
  bool preferMonthTotals = false,
}) {
  var target = goalTarget(goal);
  var done = goalDone(goal);
  final monthList = months ?? const <Map>[];

  if (tasks != null) {
    final fromTasks = tasksAchievedTotal(tasks);
    if (fromTasks > done) done = fromTasks;
  }

  if (preferMonthTotals && monthList.isNotEmpty) {
    final fromMonths = monthDoneTotal(monthList);
    if (fromMonths > done) done = fromMonths;
  }

  if (target <= 0) return null;
  final pending = target - done;
  return GoalQuantityView(
    target: target,
    done: done,
    pending: pending < 0 ? 0 : pending,
  );
}

String formatGoalQty(int value) {
  final negative = value < 0;
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}
