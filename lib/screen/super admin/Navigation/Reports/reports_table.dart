import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/report_export.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_assignment.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class ReportsTable extends StatefulWidget {
  final int? userId;
  final String? department;

  const ReportsTable({super.key, this.userId, this.department});

  @override
  State<ReportsTable> createState() => _DeadlineReportsTabState();
}

class _DeadlineReportsTabState extends State<ReportsTable> {
  String selectedType = "Goals";
  String selectedView = "Work";
  String? selectedLeaveView = "Leave";
  bool _isLoading = false;
  List<dynamic> allTasks = [];
  List<dynamic> filteredTasks = [];

  List<dynamic> allGoals = [];
  List<dynamic> filteredGoals = [];
  List<dynamic> allLeaves = [];
  List<dynamic> allPermissions = [];
  List<dynamic> allOvertimes = [];
  List<dynamic> allCompensations = [];
  List<dynamic> filteredLeaves = [];
  List<dynamic> filteredPermissions = [];
  List<dynamic> filteredOvertimes = [];
  List<dynamic> filteredCompensations = [];
  List<Map<String, dynamic>> reportUsers = [];
  String? selectedStatus;
  String? selectedPriority;
  String? selectedOverdue;
  String? selectedDepartment;
  String? selectedLeaveStatus;
  String? selectedPermissionStatus;
  String? selectedOvertimeStatus;
  String? selectedCompensationStatus;
  String? selectedLeaveType;
  List<String> departmentOptions = [];
  DateTime? selectedLeaveDate;

  DateTime? selectedPermissionDate;
  DateTime? dueFrom;
  DateTime? dueTo;
  DateTime? completedFrom;
  DateTime? completedTo;
  String workDateBy = "Due Date";

  bool isLoading = true;
  String? loadError;
  final ScrollController _headerX = ScrollController();
  final ScrollController _bodyX = ScrollController();
  final ScrollController _bodyY = ScrollController();
  var _lockScroll = false;

  @override
  void initState() {
    super.initState();
    _headerX.addListener(() => _mirrorScroll(_headerX, _bodyX));
    _bodyX.addListener(() => _mirrorScroll(_bodyX, _headerX));
    fetchTasks();
    _loadDepartments();
  }

  void _mirrorScroll(ScrollController from, ScrollController to) {
    if (_lockScroll || !from.hasClients || !to.hasClients) return;
    final max = to.position.maxScrollExtent;
    final next = from.offset.clamp(0.0, max);
    if ((to.offset - next).abs() < 0.5) return;
    _lockScroll = true;
    to.jumpTo(next);
    _lockScroll = false;
  }

  @override
  void dispose() {
    _headerX.dispose();
    _bodyX.dispose();
    _bodyY.dispose();
    super.dispose();
  }

  Future<void> fetchTasks() async {
    try {
      final result = await ReportsService.getFullReport(
        userId: widget.userId,
        department: widget.department,
      );
      final tasks = List<dynamic>.from(result["tasks"] ?? []);
      final goals = List<dynamic>.from(result["goals"] ?? []);
      await _attachAssigneeNames(goals, tasks);
      _nestMonths(goals);
      _syncYearlyGoalStatus(goals);
      final visibleGoals = _visibleGoals(goals);

      if (!mounted) return;
      setState(() {
        reportUsers = (result["users"] as List? ?? [])
            .whereType<Map>()
            .map((user) => Map<String, dynamic>.from(user))
            .toList();
        allTasks = tasks;
        filteredTasks = List<dynamic>.from(allTasks);
        allGoals = visibleGoals;
        filteredGoals = List<dynamic>.from(allGoals);
        allLeaves = List<dynamic>.from(result["leaveList"] ?? []);
        filteredLeaves = List<dynamic>.from(allLeaves);
        allPermissions = List<dynamic>.from(result["permissionList"] ?? []);
        filteredPermissions = List<dynamic>.from(allPermissions);
        allOvertimes = List<dynamic>.from(result["overtimeList"] ?? []);
        filteredOvertimes = List<dynamic>.from(allOvertimes);
        allCompensations = List<dynamic>.from(result["compensationList"] ?? []);
        filteredCompensations = List<dynamic>.from(allCompensations);
        _rememberDepartments();
        loadError = null;
        isLoading = false;
      });
      applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadError = "Could not load the report";
        isLoading = false;
      });
    }
  }

  Future<void> _attachAssigneeNames(
    List<dynamic> goals,
    List<dynamic> tasks,
  ) async {
    try {
      final detailed = await SuperAdminService.getGoals();
      final goalsByCode = <String, Map>{};
      final tasksByCode = <String, Map>{};

      void indexGoal(Map goal) {
        final code = (goal["goalCode"] ?? goal["GoalCode"] ?? "").toString();
        if (code.isNotEmpty) goalsByCode[code] = goal;
        final nested = goal["tasks"];
        if (nested is List) {
          for (final task in nested) {
            if (task is! Map) continue;
            final taskCode = (task["taskCode"] ?? task["TaskCode"] ?? "")
                .toString();
            if (taskCode.isNotEmpty) tasksByCode[taskCode] = task;
          }
        }
        final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
        if (months is List) {
          for (final month in months) {
            if (month is Map) indexGoal(month);
          }
        }
      }

      for (final item in detailed) {
        if (item is Map) indexGoal(item);
      }

      void apply(Map target, Map source) {
        for (final key in [
          "assignedUsers",
          "AssignedUsers",
          "assignedTo",
          "AssignedTo",
          "assignTo",
          "quantity",
          "Quantity",
          "targetQuantity",
          "TargetQuantity",
          "completedQuantity",
          "CompletedQuantity",
          "pendingQuantity",
          "PendingQuantity",
          "performanceType",
          "PerformanceType",
          "quantitySplits",
          "QuantitySplits",
          "yearlyAssignedUserIds",
          "YearlyAssignedUserIds",
          "yearlyAssignedUsers",
          "YearlyAssignedUsers",
          "assignedUserIds",
          "AssignedUserIds",
          "parentGoalId",
          "ParentGoalId",
          "goalType",
          "GoalType",
          "monthlyGoals",
          "MonthlyGoals",
          "goalId",
        ]) {
          final value = source[key];
          if (value == null) continue;
          if (value is List && value.isEmpty) continue;
          if (value is String && value.trim().isEmpty) continue;
          target[key] = value;
        }
      }

      void enrich(Map goal) {
        final code = (goal["goalCode"] ?? goal["GoalCode"] ?? "").toString();
        final source = goalsByCode[code];
        if (source != null) apply(goal, source);
        final nested = goal["tasks"];
        if (nested is List) {
          for (final task in nested) {
            if (task is! Map) continue;
            final taskCode = (task["taskCode"] ?? task["TaskCode"] ?? "")
                .toString();
            final taskSource = tasksByCode[taskCode];
            if (taskSource != null) apply(task, taskSource);
          }
        }
        final months = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
        if (months is List) {
          for (final month in months) {
            if (month is Map) enrich(month);
          }
        }
      }

      for (final goal in goals) {
        if (goal is Map) enrich(goal);
      }

      for (final task in tasks) {
        if (task is! Map) continue;
        final taskCode = (task["taskCode"] ?? task["TaskCode"] ?? "")
            .toString();
        final taskSource = tasksByCode[taskCode];
        if (taskSource != null) apply(task, taskSource);
      }
    } catch (e) {
      debugPrint("Assigned names were not loaded: $e");
    }

    await _fillMissingTaskNames(goals, tasks);
  }

  Future<void> _fillMissingTaskNames(
    List<dynamic> goals,
    List<dynamic> tasks,
  ) async {
    final pending = <String, List<Map>>{};

    void collect(dynamic task) {
      if (task is! Map) return;
      if (_namesFrom(task).isNotEmpty) return;
      final code = (task["taskCode"] ?? task["TaskCode"] ?? "").toString();
      if (code.isEmpty) return;
      pending.putIfAbsent(code, () => []).add(task);
    }

    for (final task in tasks) {
      collect(task);
    }
    for (final goal in goals) {
      if (goal is! Map) continue;
      final nested = goal["tasks"];
      if (nested is! List) continue;
      for (final task in nested) {
        collect(task);
      }
    }

    final codes = pending.keys.toList();
    const batchSize = 6;
    for (var start = 0; start < codes.length; start += batchSize) {
      final end = start + batchSize > codes.length
          ? codes.length
          : start + batchSize;
      await Future.wait(codes.sublist(start, end).map((code) async {
        try {
          final details = await SuperAdminService.getTaskByCode(code);
          final people = details["assignedTo"] ?? details["AssignedTo"];
          if (people is! List || people.isEmpty) return;
          for (final task in pending[code]!) {
            task["assignedTo"] = people;
          }
        } catch (e) {
          debugPrint("Task assignees $code: $e");
        }
      }));
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final names = await ReportsService.getAllDepartments();
      if (!mounted) return;
      setState(() {
        departmentOptions = {
          ...departmentOptions,
          for (final name in names)
            if (name.trim().isNotEmpty) name.trim(),
        }.toList()
          ..sort();
      });
    } catch (_) {}
  }

  void _rememberDepartments() {
    final names = departmentOptions.toSet();
    for (final user in reportUsers) {
      final name = _readDepartment(user);
      if (name.isNotEmpty) names.add(name);
    }
    departmentOptions = names.toList()..sort();
  }

  String _readDepartment(Map item) {
    for (final key in const [
      'department',
      'Department',
      'departmentName',
      'DepartmentName',
      'dept',
      'Dept',
    ]) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  String _departmentByUserId(String id) {
    final wanted = id.trim();
    if (wanted.isEmpty) return '';
    for (final user in reportUsers) {
      final userId = (user['userId'] ?? user['UserId'] ?? user['id'] ?? user['Id'] ?? '')
          .toString()
          .trim();
      if (userId != wanted) continue;
      return _readDepartment(user);
    }
    return '';
  }

  String _departmentByUserName(String name) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return '';
    for (final user in reportUsers) {
      final userName = (user['name'] ?? user['Name'] ?? user['userName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (userName != wanted) continue;
      return _readDepartment(user);
    }
    return '';
  }

  String _itemDepartment(dynamic item) {
    if (item is! Map) return '';
    final direct = _readDepartment(item);
    if (direct.isNotEmpty) return direct;

    final ids = <String>{};
    void collectId(dynamic raw) {
      if (raw == null || raw is bool) return;
      if (raw is num || raw is String) {
        final text = raw.toString().trim();
        if (text.isNotEmpty && text != 'null' && int.tryParse(text) != null) {
          ids.add(text);
        }
        return;
      }
      if (raw is Map) {
        final nested = _readDepartment(raw);
        if (nested.isNotEmpty) {
          ids.add('dept:$nested');
          return;
        }
        collectId(raw['userId'] ?? raw['UserId'] ?? raw['id'] ?? raw['Id']);
        return;
      }
      if (raw is List) {
        for (final entry in raw) {
          collectId(entry);
        }
      }
    }

    collectId(item['userId'] ?? item['UserId'] ?? item['staffId'] ?? item['employeeId']);
    collectId(
      item['assignedTo'] ?? item['AssignedTo'] ?? item['assignTo'] ?? item['users'] ?? item['Users'],
    );

    for (final id in ids) {
      if (id.startsWith('dept:')) return id.substring(5);
      final fromUser = _departmentByUserId(id);
      if (fromUser.isNotEmpty) return fromUser;
    }

    for (final name in _namesFrom(item)) {
      final fromName = _departmentByUserName(name);
      if (fromName.isNotEmpty) return fromName;
    }
    return '';
  }

  bool _matchesDepartment(dynamic item) {
    final wanted = selectedDepartment?.trim();
    if (wanted == null || wanted.isEmpty) return true;
    return _itemDepartment(item).toLowerCase() == wanted.toLowerCase();
  }

  bool _responseScopedToUser() {
    final userId = widget.userId;
    if (userId == null) return false;
    if (reportUsers.length > 1) return false;
    if (reportUsers.isEmpty) return true;
    final id = readPersonId(reportUsers.first);
    return id == null || id == userId;
  }

  bool _matchesSelectedUser(dynamic item) {
    final userId = widget.userId;
    if (userId == null || _responseScopedToUser()) return true;
    if (item is! Map) return false;
    final map = Map<String, dynamic>.from(item);
    if (personIdsFrom(map).contains(userId)) return true;
    if (goalAssigneeIds(map).contains(userId)) return true;
    for (final key in const [
      'assignedTo',
      'AssignedTo',
      'assignTo',
      'users',
      'Users',
    ]) {
      if (personIdsFrom(map[key]).contains(userId)) return true;
    }
    final wanted = _userNameById(userId.toString()).trim().toLowerCase();
    if (wanted.isEmpty) return false;
    if (_namesFrom(map).any((name) => name.toLowerCase() == wanted)) {
      return true;
    }
    for (final key in const [
      'staffName',
      'StaffName',
      'userName',
      'employeeName',
      'name',
      'Name',
    ]) {
      final value = (map[key] ?? '').toString().trim().toLowerCase();
      if (value == wanted) return true;
      if (value.contains('-') && value.split('-').last.trim() == wanted) {
        return true;
      }
    }
    return false;
  }

  DataCell _departmentCell(dynamic item) {
    final name = _itemDepartment(item);
    return DataCell(Text(name.isEmpty ? '-' : name, style: _tableStyle));
  }

  bool _sameStatus(dynamic raw, String? selected) {
    if (selected == null) return true;
    return TaskUtils.parseStatus((raw ?? '').toString()) ==
        TaskUtils.parseStatus(selected);
  }

  void applyFilters() {
    setState(() {
      filteredTasks = allTasks.where((task) {
        if (!_matchesSelectedUser(task)) return false;
        if (!_matchesDepartment(task)) return false;

        if (selectedStatus != null &&
            !_sameStatus(task["status"], selectedStatus)) {
          return false;
        }

        if (selectedPriority != null &&
            (task["priority"] ?? "").toLowerCase() !=
                selectedPriority!.toLowerCase()) {
          return false;
        }

        if (selectedOverdue != null) {
          bool overdueValue = selectedOverdue == "Yes";
          if ((task["isOverdue"] ?? false) != overdueValue) {
            return false;
          }
        }

        if (!_matchesWorkDate(task)) return false;

        return true;
      }).toList();

      filteredGoals = allGoals.where((goal) {
        if (!_matchesSelectedUser(goal)) return false;
        if (!_matchesDepartment(goal)) return false;

        if (selectedStatus != null &&
            !_sameStatus(goal["status"], selectedStatus)) {
          return false;
        }

        if (selectedPriority != null &&
            (goal["priority"] ?? "").toLowerCase() !=
                selectedPriority!.toLowerCase()) {
          return false;
        }

        if (selectedOverdue != null) {
          bool overdueValue = selectedOverdue == "Yes";
          if ((goal["isOverdue"] ?? false) != overdueValue) {
            return false;
          }
        }

        if (!_matchesWorkDate(goal)) return false;

        return true;
      }).toList();

      // ---------------- LEAVE FILTER ----------------
      filteredLeaves = allLeaves.where((leave) {
        if (!_matchesSelectedUser(leave)) return false;
        if (!_matchesDepartment(leave)) return false;

        if (selectedLeaveStatus != null &&
            (leave["status"] ?? "").toLowerCase() !=
                selectedLeaveStatus!.toLowerCase())
          return false;

        if (selectedLeaveType != null &&
            (leave["type"] ?? "").toLowerCase() !=
                selectedLeaveType!.toLowerCase())
          return false;

        if (selectedLeaveDate != null) {
          final leaveDate = leave["fromDate"];
          if (leaveDate == null) return false;

          final date = DateTime.parse(leaveDate.toString());
          if (date.year != selectedLeaveDate!.year ||
              date.month != selectedLeaveDate!.month ||
              date.day != selectedLeaveDate!.day) {
            return false;
          }
        }

        return true;
      }).toList();

      // ---------------- PERMISSION FILTER ----------------
      filteredPermissions = allPermissions.where((p) {
        if (!_matchesSelectedUser(p)) return false;
        if (!_matchesDepartment(p)) return false;

        if (selectedPermissionStatus != null &&
            (p["status"] ?? "").toString().toLowerCase() !=
                selectedPermissionStatus!.toLowerCase()) {
          return false;
        }

        final filterDate = selectedPermissionDate ?? selectedLeaveDate;
        if (filterDate != null) {
          final rawDate = p["date"];
          if (rawDate == null) return false;
          final date = DateTime.tryParse(rawDate.toString());
          if (date == null) return false;

          if (date.year != filterDate.year ||
              date.month != filterDate.month ||
              date.day != filterDate.day) {
            return false;
          }
        }
        return true;
      }).toList();

      filteredOvertimes = allOvertimes.where((item) {
        if (!_matchesSelectedUser(item)) return false;
        if (!_matchesDepartment(item)) return false;
        if (selectedOvertimeStatus != null &&
            _overtimeStatus(item).toLowerCase() !=
                selectedOvertimeStatus!.toLowerCase()) {
          return false;
        }
        if (selectedLeaveDate != null &&
            !_sameDay(item["date"], selectedLeaveDate!)) {
          return false;
        }
        return true;
      }).toList();

      filteredCompensations = allCompensations.where((item) {
        if (!_matchesSelectedUser(item)) return false;
        if (!_matchesDepartment(item)) return false;
        if (selectedCompensationStatus != null &&
            !_matchesCompensationStatus(item, selectedCompensationStatus!)) {
          return false;
        }
        if (selectedLeaveDate != null &&
            !_sameDay(item["workDate"] ?? item["date"], selectedLeaveDate!)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  bool _sameDay(dynamic raw, DateTime day) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return false;
    return date.year == day.year && date.month == day.month && date.day == day.day;
  }

  bool _matchesCompensationStatus(dynamic item, String wanted) {
    final status = _compensationStatus(item).toLowerCase();
    if (wanted.toLowerCase() == 'rejected') return status.contains('reject');
    return status == wanted.toLowerCase();
  }

  bool _matchesWorkDate(dynamic item) {
    final from = workDateBy == "Completed Date" ? completedFrom : dueFrom;
    final to = workDateBy == "Completed Date" ? completedTo : dueTo;
    if (from == null && to == null) return true;
    if (item is! Map) return false;
    final raw = workDateBy == "Completed Date"
        ? (item["completedDate"] ?? item["completed_Date"])
        : (item["dueDate"] ?? item["due_Date"]);
    final day = _parseDay(raw);
    if (day == null) return false;
    if (from != null && day.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && day.isAfter(DateTime(to.year, to.month, to.day))) {
      return false;
    }
    return true;
  }

  DateTime? _parseDay(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.startsWith("0001-01-01")) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  bool _isQuantityTask(dynamic task) {
    if (task is! Map) return false;
    final map = Map<String, dynamic>.from(task);
    final type = (map["performanceType"] ?? map["PerformanceType"] ?? "")
        .toString()
        .toLowerCase();
    if (type == "qty" || type == "quantity") return true;
    if (taskAssignedQty(map) > 0) return true;
    return (readGoalInt(map, const [
          "targetQuantity",
          "TargetQuantity",
        ]) ??
        0) >
        0;
  }

  ({int target, int done}) _qtyTotals(Map item) {
    var target = taskAssignedQty(item);
    if (target <= 0) target = goalTarget(item);
    var done = taskAchievedQty(item);
    if (done <= 0) done = goalDone(item);

    final tasks = item["tasks"] ?? item["Tasks"];
    if (tasks is List && (target <= 0 || done <= 0)) {
      var taskTarget = 0;
      var taskDone = 0;
      for (final task in tasks) {
        if (task is! Map) continue;
        final map = Map<String, dynamic>.from(task);
        final assigned = taskAssignedQty(map);
        taskTarget += assigned > 0 ? assigned : goalTarget(map);
        final achieved = taskAchievedQty(map);
        taskDone += achieved > 0 ? achieved : goalDone(map);
      }
      if (target <= 0) target = taskTarget;
      if (done <= 0) done = taskDone;
    }
    return (target: target, done: done);
  }

  String _qtyText(dynamic task, {required bool completed}) {
    if (task is! Map) return "-";
    final map = Map<String, dynamic>.from(task);
    if (!_isQuantityTask(map) && _qtyTotals(map).target <= 0 && _qtyTotals(map).done <= 0) {
      return "-";
    }
    final totals = _qtyTotals(map);
    if (totals.target <= 0 && totals.done <= 0) return "-";
    return (completed ? totals.done : totals.target).toString();
  }

  List<({String name, dynamic item})> _goalTaskEntries(dynamic goal) {
    final items = <dynamic>[];
    void add(dynamic raw) {
      if (raw is List) items.addAll(raw);
    }

    if (goal is Map) {
      add(goal["tasks"]);
    }

    final lines = <({String name, dynamic item})>[];
    final seen = <String>{};
    for (final item in items) {
      final name = item is String
          ? item
          : item is Map
          ? (item["task"] ?? item["title"] ?? "").toString()
          : item.toString();
      if (name.trim().isEmpty) continue;
      final key = name.toLowerCase();
      if (!seen.add(key)) continue;
      lines.add((name: "${lines.length + 1}. $name", item: item));
    }
    return lines;
  }

  String _pendingText(dynamic task) {
    final target = int.tryParse(_qtyText(task, completed: false)) ?? 0;
    final done = int.tryParse(_qtyText(task, completed: true)) ?? 0;
    if (_qtyText(task, completed: false) == "-" && _qtyText(task, completed: true) == "-") {
      return "-";
    }
    final pending = target - done;
    return (pending < 0 ? 0 : pending).toString();
  }

  ({String name, String target, String done, String pending}) _qtyRow(
    String name,
    dynamic item,
  ) {
    return (
      name: name,
      target: _qtyText(item, completed: false),
      done: _qtyText(item, completed: true),
      pending: _pendingText(item),
    );
  }

  List<({String name, String target, String done, String pending})>
  _goalQtyRows(dynamic goal) {
    final rows = <({String name, String target, String done, String pending})>[];
    if (goal is Map && isYearlyGoal(Map<String, dynamic>.from(goal))) {
      final months = _monthsOf(Map<String, dynamic>.from(goal));
      if (months.isNotEmpty) {
        var target = 0;
        var done = 0;
        var counted = false;
        for (final month in months) {
          final title = (month["title"] ?? month["goal"] ?? "Month").toString();
          rows.add(_qtyRow(title, month));
          final totals = _qtyTotals(month);
          if (totals.target > 0 || totals.done > 0) {
            counted = true;
            target += totals.target;
            done += totals.done;
          }
        }
        final pending = target - done;
        rows.insert(0, (
          name: "Goal",
          target: counted ? target.toString() : _qtyText(goal, completed: false),
          done: counted ? done.toString() : _qtyText(goal, completed: true),
          pending: counted
              ? (pending < 0 ? 0 : pending).toString()
              : _pendingText(goal),
        ));
        return rows;
      }
    }

    if (goal is Map && (_isQuantityTask(goal) || _qtyTotals(Map<String, dynamic>.from(goal)).target > 0)) {
      rows.add(_qtyRow("Goal", goal));
    }
    for (final entry in _goalTaskEntries(goal)) {
      rows.add(_qtyRow(entry.name, entry.item));
    }
    if (rows.isEmpty) {
      rows.add((name: "-", target: "-", done: "-", pending: "-"));
    }
    return rows;
  }

  TextStyle get _tableStyle => TextStyle(
    fontSize: 11,
    height: 1.2,
    color: WebTheme.inkOf(context),
    fontWeight: FontWeight.w500,
  );

  Widget _alignedLines(
    List<String> lines, {
    required double width,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    final style = _tableStyle.copyWith(fontWeight: weight, color: color);
    final line = WebTheme.lineOf(context).withValues(alpha: 0.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) Container(height: 1, width: width, color: line),
          SizedBox(
            height: 36,
            width: width,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lines[i],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String get _activeTable {
    if (selectedView == "Work") return selectedType;
    return selectedLeaveView ?? "Leave";
  }

  void _selectTable(String type) {
    setState(() {
      if (type == "Goals" || type == "Tasks") {
        selectedView = "Work";
        selectedType = type;
      } else {
        selectedView = "Leave";
        selectedLeaveView = type;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lockScroll = true;
      for (final controller in [_headerX, _bodyX, _bodyY]) {
        if (controller.hasClients) controller.jumpTo(0);
      }
      _lockScroll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !AppLayout.isMobile(context);
    return Scaffold(
      backgroundColor: isWeb ? WebTheme.canvasOf(context) : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Reports Table"),
        actions: [
          PopupMenuButton<String>(
            tooltip: "Download",
            icon: const Icon(Icons.download_rounded),
            color: WebTheme.brand,
            onSelected: _downloadReport,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "pdf",
                child: _DownloadChoice(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "PDF",
                ),
              ),
              PopupMenuItem(
                value: "excel",
                child: _DownloadChoice(
                  icon: Icons.table_view_rounded,
                  label: "Excel",
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: WebTheme.canvasOf(context),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, modalSetState) {
                      return buildFilterSheet(modalSetState);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : Padding(
              padding: AppLayout.pagePadding(context),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in const [
                      "Goals",
                      "Tasks",
                      "Leave",
                      "Permission",
                      "Overtime",
                      "Compensation",
                    ])
                      ChoiceChip(
                        label: Text(type),
                        selected: _activeTable == type,
                        showCheckmark: false,
                        backgroundColor: WebTheme.canvasOf(context),
                        selectedColor: WebTheme.brand,
                        side: BorderSide(
                          color: _activeTable == type
                              ? WebTheme.brand
                              : WebTheme.lineOf(context),
                        ),
                        labelStyle: TextStyle(
                          color: _activeTable == type
                              ? Colors.white
                              : WebTheme.mutedOf(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        onSelected: (_) => _selectTable(type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                /// 🔹 FILTER CHIPS SECTION - FOR GOALS/TASKS
                if (selectedView == "Work" &&
                    (selectedDepartment != null ||
                        selectedStatus != null ||
                        selectedPriority != null ||
                        selectedOverdue != null ||
                        _activeDateSet))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (selectedDepartment != null)
                          _buildFilterChip("Department: $selectedDepartment", () {
                            setState(() {
                              selectedDepartment = null;
                              applyFilters();
                            });
                          }),
                        if (selectedStatus != null)
                          _buildFilterChip("Status: $selectedStatus", () {
                            setState(() {
                              selectedStatus = null;
                              applyFilters();
                            });
                          }),
                        if (selectedPriority != null)
                          _buildFilterChip("Priority: $selectedPriority", () {
                            setState(() {
                              selectedPriority = null;
                              applyFilters();
                            });
                          }),
                        if (selectedOverdue != null)
                          _buildFilterChip("Overdue: $selectedOverdue", () {
                            setState(() {
                              selectedOverdue = null;
                              applyFilters();
                            });
                          }),
                        if (_activeDateSet)
                          _buildFilterChip(_dateRangeLabel(), () {
                            setState(() {
                              if (workDateBy == "Completed Date") {
                                completedFrom = null;
                                completedTo = null;
                              } else {
                                dueFrom = null;
                                dueTo = null;
                              }
                              applyFilters();
                            });
                          }),
                      ],
                    ),
                  ),

                if (selectedView == "Leave" &&
                    (selectedDepartment != null ||
                        selectedLeaveType != null ||
                        selectedLeaveStatus != null ||
                        selectedPermissionStatus != null ||
                        selectedOvertimeStatus != null ||
                        selectedCompensationStatus != null ||
                        selectedLeaveDate != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (selectedDepartment != null)
                          _buildFilterChip("Department: $selectedDepartment", () {
                            setState(() {
                              selectedDepartment = null;
                              applyFilters();
                            });
                          }),
                        if (selectedLeaveType != null)
                          _buildFilterChip(
                            "Leave Type: $selectedLeaveType",
                            () {
                              setState(() {
                                selectedLeaveType = null;
                                applyFilters();
                              });
                            },
                          ),
                        if (selectedLeaveStatus != null)
                          _buildFilterChip("Status: $selectedLeaveStatus", () {
                            setState(() {
                              selectedLeaveStatus = null;
                              applyFilters();
                            });
                          }),
                        if (selectedPermissionStatus != null)
                          _buildFilterChip(
                            "Status: $selectedPermissionStatus",
                            () {
                              setState(() {
                                selectedPermissionStatus = null;
                                applyFilters();
                              });
                            },
                          ),
                        if (selectedOvertimeStatus != null)
                          _buildFilterChip(
                            "Status: $selectedOvertimeStatus",
                            () {
                              setState(() {
                                selectedOvertimeStatus = null;
                                applyFilters();
                              });
                            },
                          ),
                        if (selectedCompensationStatus != null)
                          _buildFilterChip(
                            "Status: $selectedCompensationStatus",
                            () {
                              setState(() {
                                selectedCompensationStatus = null;
                                applyFilters();
                              });
                            },
                          ),
                        if (selectedLeaveDate != null)
                          _buildFilterChip(
                            "Date: ${AppHelpers.formatDate(selectedLeaveDate!.toString())}",
                            () {
                              setState(() {
                                selectedLeaveDate = null;
                                applyFilters();
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      final currentList = selectedView == "Work"
                          ? (selectedType == "Tasks"
                                ? filteredTasks
                                : filteredGoals)
                          : _attendanceList();
                      if (loadError != null && currentList.isEmpty) {
                        return const AppLoadError();
                      }
                      if (currentList.isEmpty) {
                        return Center(
                          child: Text(
                            "No data available",
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        );
                      }
                      final table = selectedView == "Work"
                          ? (selectedType == "Tasks"
                                ? _buildTaskTable()
                                : _buildGoalTable())
                          : _attendanceTable();
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: WebTheme.surfaceOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WebTheme.lineOf(context)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: table,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            ),
    );
  }

  Widget _pinnedTable({
    required List<DataColumn> columns,
    required List<DataRow> rows,
    double dataRowMinHeight = 48,
    double dataRowMaxHeight = double.infinity,
  }) {
    const headingHeight = 40.0;
    Widget sheet({required bool header}) {
      return DataTable(
        showCheckboxColumn: false,
        headingRowHeight: header ? headingHeight : 0,
        headingRowColor: WidgetStateProperty.all(WebTheme.brandSoftOf(context)),
        headingTextStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: WebTheme.brandOf(context),
        ),
        dataTextStyle: _tableStyle,
        border: TableBorder(
          verticalInside: BorderSide(
            color: WebTheme.isDark(context)
                ? const Color(0xFFD1D5DB)
                : const Color(0xFF374151),
            width: 1.4,
          ),
          horizontalInside: BorderSide(
            color: WebTheme.isDark(context)
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
        ),
        dataRowMinHeight: header ? 0 : dataRowMinHeight,
        dataRowMaxHeight: header ? 0 : dataRowMaxHeight,
        horizontalMargin: 10,
        columnSpacing: 14,
        columns: columns,
        rows: rows,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          controller: _headerX,
          scrollDirection: Axis.horizontal,
          child: sheet(header: true),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _bodyX,
                thumbVisibility: true,
                notificationPredicate: (notice) =>
                    notice.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _bodyX,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Scrollbar(
                      controller: _bodyY,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _bodyY,
                        child: sheet(header: false),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<dynamic> _attendanceList() {
    switch (selectedLeaveView) {
      case "Permission":
        return filteredPermissions;
      case "Overtime":
        return filteredOvertimes;
      case "Compensation":
        return filteredCompensations;
      default:
        return filteredLeaves;
    }
  }

  Widget _attendanceTable() {
    switch (selectedLeaveView) {
      case "Permission":
        return _buildPermissionTable();
      case "Overtime":
        return _buildOvertimeTable();
      case "Compensation":
        return _buildCompensationTable();
      default:
        return _buildLeaveTable();
    }
  }

  String _staffName(dynamic item) {
    if (item is! Map) return "-";
    for (final key in const ["staffName", "name", "employeeName"]) {
      final value = (item[key] ?? "").toString().trim();
      if (value.isNotEmpty && value.toLowerCase() != "null") return value;
    }
    final id = item["employeeId"] ?? item["staffId"] ?? item["uid"];
    final name = _userNameById("${id ?? ""}").trim();
    return name.isEmpty ? "-" : name;
  }

  String _overtimeStatus(dynamic item) {
    final manager = (item is Map ? item["managerStatus"] : "")
        .toString()
        .trim();
    final staff = (item is Map ? item["staffStatus"] : "").toString().trim();
    if (manager.toLowerCase() == "approved") return "Approved";
    if (manager.toLowerCase() == "rejected" ||
        staff.toLowerCase() == "rejected") {
      return "Rejected";
    }
    if (staff.toLowerCase() == "accepted") return "Accepted";
    return "Pending";
  }

  String _compensationStatus(dynamic item) {
    final raw = (item is Map ? item["status"] : "").toString().trim();
    switch (raw.toLowerCase()) {
      case "approved":
        return "Approved";
      case "accepted":
        return "Accepted";
      case "staffrejected":
        return "Staff Rejected";
      case "managerrejected":
        return "Manager Rejected";
      case "rejected":
        return "Rejected";
      default:
        return raw.isEmpty ? "Pending" : raw;
    }
  }

  String _requestRemarks(dynamic item) {
    if (item is! Map) return "-";
    String text(dynamic value) {
      final raw = (value ?? "").toString().trim();
      return raw.isEmpty || raw.toLowerCase() == "null" ? "" : raw;
    }

    final staff = text(item["staffResponseReason"] ?? item["staffRemarks"]);
    final manager = text(
      item["managerResponseReason"] ?? item["managerRemarks"],
    );
    final parts = <String>[];
    if (staff.isNotEmpty) parts.add("Staff: $staff");
    if (manager.isNotEmpty) parts.add("Manager: $manager");
    return parts.isEmpty ? "-" : parts.join(" · ");
  }

  bool _compensationUsed(dynamic item) {
    if (item is! Map) return false;
    final value = item["isCompensationUsed"];
    if (value == true) return true;
    return value?.toString().toLowerCase() == "true";
  }

  String _workTypeLabel(dynamic value) {
    switch ((value ?? "").toString()) {
      case "WeeklyOff":
        return "Weekly Off";
      case "PublicHoliday":
        return "Public Holiday";
      case "CompanyHoliday":
        return "Company Holiday";
      default:
        final text = (value ?? "").toString().trim();
        return text.isEmpty ? "-" : text;
    }
  }

  String _timeRange(dynamic from, dynamic to) {
    return "${TimeUtils.formatTime12(from, empty: "-")} - ${TimeUtils.formatTime12(to, empty: "-")}";
  }

  DataCell _statusCell(String status) {
    final value = status.toLowerCase();
    final color = value == "approved"
        ? Colors.green
        : value == "accepted"
        ? Colors.blue
        : value.contains("reject")
        ? Colors.red
        : Colors.orange;
    return DataCell(
      Text(
        status,
        style: _tableStyle.copyWith(color: color),
      ),
    );
  }

  Widget _buildOvertimeTable() {
    return _pinnedTable(
      columns: const [
        DataColumn(label: Text("Department")),
        DataColumn(label: Text("Staff")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("Time")),
        DataColumn(label: Text("Hours")),
        DataColumn(label: Text("Reason")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Remarks")),
      ],
      rows: filteredOvertimes.map((item) {
        return DataRow(
          cells: [
            _departmentCell(item),
            DataCell(Text(_staffName(item), style: _tableStyle)),
            DataCell(Text(_cellDate(item["date"]), style: _tableStyle)),
            DataCell(
              Text(
                _timeRange(item["fromTime"], item["toTime"]),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                _hoursLabel(item["totalHours"]),
                style: _tableStyle,
              ),
            ),
            DataCell(Text((item["reason"] ?? "").toString(), style: _tableStyle)),
            _statusCell(_overtimeStatus(item)),
            DataCell(Text(_requestRemarks(item), style: _tableStyle)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCompensationTable() {
    return _pinnedTable(
      columns: const [
        DataColumn(label: Text("Department")),
        DataColumn(label: Text("Staff")),
        DataColumn(label: Text("Work Date")),
        DataColumn(label: Text("Work Type")),
        DataColumn(label: Text("Time")),
        DataColumn(label: Text("Hours")),
        DataColumn(label: Text("Reason")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Remarks")),
        DataColumn(label: Text("Used")),
      ],
      rows: filteredCompensations.map((item) {
        return DataRow(
          cells: [
            _departmentCell(item),
            DataCell(Text(_staffName(item), style: _tableStyle)),
            DataCell(
              Text(
                _cellDate(item["workDate"] ?? item["date"]),
                style: _tableStyle,
              ),
            ),
            DataCell(Text(_workTypeLabel(item["workType"]), style: _tableStyle)),
            DataCell(
              Text(
                _timeRange(item["startTime"], item["endTime"]),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                _hoursLabel(item["expectedHours"] ?? item["totalHours"]),
                style: _tableStyle,
              ),
            ),
            DataCell(Text((item["reason"] ?? "").toString(), style: _tableStyle)),
            _statusCell(_compensationStatus(item)),
            DataCell(Text(_requestRemarks(item), style: _tableStyle)),
            DataCell(Text(_compensationUsed(item) ? "Yes" : "No", style: _tableStyle)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLeaveTable() {
    return _pinnedTable(
      columns: const [
        DataColumn(label: Text("Department")),
        DataColumn(label: Text("Leave Category")),
        DataColumn(label: Text("Leave Type")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("Reason")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Approved Date")),
        DataColumn(label: Text("Reject Reason")),
        DataColumn(label: Text("Compensation Date")),
      ],
      rows: filteredLeaves.map((item) {
        return DataRow(
          cells: [
            _departmentCell(item),
            DataCell(
              Text(
                item["leavecategory"] ?? "-",
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                item["type"] ?? "-",
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                AppHelpers.formatDate(item["fromDate"] ?? "-"),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                item["reason"] ?? "",
                style: _tableStyle,
              ),
            ),

            DataCell(
              Text(
                item["status"] ?? "",
                style: _tableStyle.copyWith(
                  color: item["status"] == "Approved"
                      ? Colors.green
                      : item["status"] == "Rejected"
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ),
            DataCell(
              Text(
                AppHelpers.formatDate(item["approvedate"] ?? "-"),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                item["rejreason"] ?? "-",
                style: _tableStyle,
              ),
            ),

            DataCell(
              Text(
                AppHelpers.formatDate(item["compensationDate"] ?? "-"),
                style: _tableStyle,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPermissionTable() {
    return _pinnedTable(
      columns: const [
        DataColumn(label: Text("Department")),
        DataColumn(label: Text("Reason")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("From Time")),
        DataColumn(label: Text("To Time")),
        DataColumn(label: Text("Total Hours")),
        DataColumn(label: Text("Submitted Date")),
        DataColumn(label: Text("Status")),
      ],
      rows: filteredPermissions.map((item) {
        return DataRow(
          cells: [
            _departmentCell(item),
            DataCell(
              Text(
                item["reason"] ?? "",
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                AppHelpers.formatDate(item["date"] ?? "-"),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                item["fromTime"] ?? "-",
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                item["toTime"] ?? "-",
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                _hoursLabel(item["totalHours"] ?? item["totalhours"]),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                _cellDate(item["submittedDate"] ?? item["submdate"]),
                style: _tableStyle,
              ),
            ),
            DataCell(
              Text(
                item["status"] ?? "",
                style: _tableStyle.copyWith(
                  color: item["status"] == "Approved"
                      ? Colors.green
                      : item["status"] == "Rejected"
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTaskTable() {
    return _pinnedTable(
      columns: const [
        DataColumn(label: Text("Sl.No")),
        DataColumn(label: Text("Task")),
        DataColumn(label: Text("Assigned To")),
        DataColumn(label: Text("Department")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Priority")),
        DataColumn(label: Text("Points")),
        DataColumn(label: Text("Target Qty")),
        DataColumn(label: Text("Completed Qty")),
        DataColumn(label: Text("Due Date")),
        DataColumn(label: Text("Completed Date")),
        DataColumn(label: Text("Overdue")),
      ],
      rows: [
        for (var index = 0; index < filteredTasks.length; index++)
          _taskRow(filteredTasks[index], index),
      ],
    );
  }

  DataRow _taskRow(dynamic task, int index) {
    final dueDate = _cellDate(task["dueDate"] ?? task["due_Date"]);
    final completedDate = _cellDate(
      task["completedDate"] ?? task["completed_Date"],
    );

    return DataRow(
      onSelectChanged: (_) => _openTask(task),
      cells: [
        DataCell(
          Text("${index + 1}", style: _tableStyle),
        ),
        DataCell(
          Text(
            (task["task"] ?? "-").toString(),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            _assigneeLabel(task),
            style: _tableStyle,
          ),
        ),
        _departmentCell(task),
        DataCell(
          Text(
            task["status"] ?? "-",
            style: TextStyle(
              color: TaskUtils.getStatusColor(
                TaskUtils.parseStatus(task["status"] ?? ""),
              ),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        DataCell(
          Text(
            task["priority"] ?? "-",
            style: TextStyle(
              color: TaskUtils.getPriorityColor(task["priority"]),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        DataCell(
          Text(
            (task["points"] ?? 0).toString(),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            _qtyText(task, completed: false),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            _qtyText(task, completed: true),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(dueDate, style: _tableStyle),
        ),
        DataCell(
          Text(
            completedDate,
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            task["isOverdue"] == true ? "Yes" : "No",
            style: TextStyle(
              color: task["isOverdue"] == true ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTable() {
    return _pinnedTable(
      dataRowMinHeight: 60,
      dataRowMaxHeight: double.infinity,
      columns: const [
        DataColumn(label: Text("Sl.No")),
        DataColumn(label: Text("Goal")),
        DataColumn(label: Text("Goal Type")),
        DataColumn(label: Text("Assigned To")),
        DataColumn(label: Text("Department")),
        DataColumn(label: Text("Tasks")),
        DataColumn(label: Text("Target Qty")),
        DataColumn(label: Text("Completed Qty")),
        DataColumn(label: Text("Pending Qty")),
        DataColumn(label: Text("Status")),
        DataColumn(label: Text("Priority")),
        DataColumn(label: Text("Due Date")),
        DataColumn(label: Text("Completed Date")),
        DataColumn(label: Text("Progress")),
        DataColumn(label: Text("Points")),
        DataColumn(label: Text("Overdue")),
      ],
      rows: [
        for (var index = 0; index < filteredGoals.length; index++)
          _goalRow(filteredGoals[index], index),
      ],
    );
  }

  DataRow _goalRow(dynamic goal, int index) {
    final goalType = (goal["goalType"] ?? goal["GoalType"] ?? "-").toString();

    return DataRow(
      onSelectChanged: (_) => _openGoal(goal),
      cells: [
        DataCell(
          Text("${index + 1}", style: _tableStyle),
        ),
        DataCell(
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              (goal["title"] ?? "").toString(),
              style: _tableStyle,
            ),
          ),
        ),
        DataCell(
          Text(
            goalType.isEmpty ? "-" : goalType,
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            _assigneeLabel(goal),
            style: _tableStyle,
          ),
        ),
        _departmentCell(goal),
        DataCell(
          _alignedLines(
            [for (final row in _goalQtyRows(goal)) row.name],
            width: 180,
            weight: FontWeight.w700,
          ),
        ),
        DataCell(
          _alignedLines(
            [for (final row in _goalQtyRows(goal)) row.target],
            width: 72,
          ),
        ),
        DataCell(
          _alignedLines(
            [for (final row in _goalQtyRows(goal)) row.done],
            width: 88,
            weight: FontWeight.w700,
            color: WebTheme.brand,
          ),
        ),
        DataCell(
          _alignedLines(
            [for (final row in _goalQtyRows(goal)) row.pending],
            width: 80,
          ),
        ),
        DataCell(
          Text(
            goal["status"] ?? "-",
            style: TextStyle(
              color: TaskUtils.getStatusColor(
                TaskUtils.parseStatus(goal["status"] ?? ""),
              ),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        DataCell(
          Text(
            goal["priority"] ?? "",
            style: TextStyle(
              color: TaskUtils.getPriorityColor(goal["priority"]),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        DataCell(
          Text(
            _cellDate(goal["dueDate"] ?? goal["due_Date"]),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            _cellDate(goal["completedDate"] ?? goal["completed_Date"]),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            _percentLabel(goal["progress"]),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            (goal["points"] ?? 0).toString(),
            style: _tableStyle,
          ),
        ),
        DataCell(
          Text(
            goal["isOverdue"] == true ? "Yes" : "No",
            style: TextStyle(
              color: goal["isOverdue"] == true ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  void _openTask(dynamic task) {
    final code = (task["taskCode"] ?? task["TaskCode"] ?? "").toString();
    if (code.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetails(taskCode: code)),
    );
  }

  void _openGoal(dynamic goal) {
    final cardGoal = goal is Map<String, dynamic>
        ? Map<String, dynamic>.from(goal)
        : Map<String, dynamic>.from(goal as Map);
    cardGoal["goalpoints"] = cardGoal["goalpoints"] ?? cardGoal["points"] ?? 0;
    cardGoal["completed_Date"] =
        cardGoal["completed_Date"] ?? cardGoal["completedDate"];
    cardGoal["tasks"] = _cardTasks(cardGoal["tasks"]);

    final months = _monthlyChildren(cardGoal);
    cardGoal["monthlyGoals"] = months;

    final names = _assigneeNames(cardGoal);
    if (names.isNotEmpty) {
      cardGoal["assignedUsers"] = [
        for (final name in names) {"name": name},
      ];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text((cardGoal["title"] ?? "Goal").toString()),
          ),
          body: SingleChildScrollView(
            padding: AppLayout.pagePadding(context),
            child: GoalCard(goal: cardGoal),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _cardTasks(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((task) {
      final copy = Map<String, dynamic>.from(task);
      copy["dueDate"] = copy["dueDate"] ?? copy["due_Date"];
      copy["task"] = copy["task"] ?? copy["title"] ?? "";
      final names = _namesFrom(copy);
      if (names.isEmpty && reportUsers.length == 1) {
        final only = (reportUsers.first["name"] ?? reportUsers.first["Name"] ?? "")
            .toString()
            .trim();
        if (only.isNotEmpty) names.add(only);
      }
      if (names.isNotEmpty) {
        copy["assignedTo"] = [
          for (final name in names) {"name": name},
        ];
      }
      return copy;
    }).toList();
  }

  void _nestMonths(List<dynamic> goals) {
    final yearlyById = <String, Map>{};
    for (final item in goals) {
      if (item is! Map || !isYearlyGoal(Map<String, dynamic>.from(item))) {
        continue;
      }
      final id = _idOf(item["goalId"] ?? item["id"] ?? item["Id"]);
      if (id.isNotEmpty) yearlyById[id] = item;
    }

    for (final item in goals) {
      if (item is! Map || isYearlyGoal(Map<String, dynamic>.from(item))) {
        continue;
      }
      final parentId = _idOf(item["parentGoalId"] ?? item["ParentGoalId"]);
      final parent = yearlyById[parentId];
      if (parent == null) continue;
      final months = parent["monthlyGoals"] ?? parent["MonthlyGoals"];
      final list = months is List ? List<dynamic>.from(months) : <dynamic>[];
      final code = (item["goalCode"] ?? item["GoalCode"] ?? "").toString();
      final exists = list.any((month) {
        if (month is! Map || code.isEmpty) return false;
        return (month["goalCode"] ?? month["GoalCode"] ?? "").toString() == code;
      });
      if (!exists) list.add(item);
      parent["monthlyGoals"] = list;
    }
  }

  void _syncYearlyGoalStatus(List<dynamic> goals) {
    for (final item in goals) {
      if (item is! Map || !isYearlyGoal(Map<String, dynamic>.from(item))) {
        continue;
      }
      final next = _yearlyGoalStatus(Map<String, dynamic>.from(item));
      if (next.isEmpty) continue;
      item["status"] = next;
    }
  }

  String _yearlyGoalStatus(Map goal) {
    bool completed(Map item) {
      final status = (item["status"] ?? item["Status"] ?? "")
          .toString()
          .trim()
          .toLowerCase();
      if (status == "completed") return true;
      final progress = item["progress"] ?? item["Progress"];
      if (progress is num && progress >= 100) return true;
      final progressText = progress?.toString().replaceAll("%", "").trim() ?? "";
      final progressValue = double.tryParse(progressText);
      if (progressValue != null && progressValue >= 100) return true;
      final done = item["completedDate"] ?? item["completed_Date"];
      final text = done?.toString().trim() ?? "";
      return text.isNotEmpty && text != "null" && text != "-";
    }

    final months = _monthsOf(goal);
    if (months.isNotEmpty && months.every(completed)) return "Completed";
    if (completed(goal)) return "Completed";
    if (months.any(completed)) return "InProgress";
    final stored = (goal["status"] ?? goal["Status"] ?? "").toString().trim();
    return stored;
  }

  List<Map<String, dynamic>> _monthsOf(Map yearly) {
    final months = <Map<String, dynamic>>[];
    final seen = <String>{};
    void add(dynamic raw) {
      if (raw is! Map) return;
      final month = Map<String, dynamic>.from(raw);
      if (isYearlyGoal(month)) return;
      final key = (month["goalCode"] ?? month["GoalCode"] ?? month["title"] ?? "")
          .toString();
      if (key.isNotEmpty && !seen.add(key)) return;
      months.add(month);
    }

    final nested = yearly["monthlyGoals"] ?? yearly["MonthlyGoals"];
    if (nested is List) {
      for (final month in nested) {
        add(month);
      }
    }
    for (final month in _monthlyChildren(yearly)) {
      add(month);
    }
    return months;
  }

  List<dynamic> _visibleGoals(List<dynamic> goals) {
    final userId = widget.userId;
    if (userId == null || _responseScopedToUser()) return goals;

    final yearlyIds = <String>{};
    for (final item in goals) {
      if (item is! Map || !isYearlyGoal(Map<String, dynamic>.from(item))) {
        continue;
      }
      if (!showYearlyGoalTo(Map<String, dynamic>.from(item), userId)) continue;
      final id = _idOf(item["goalId"] ?? item["id"] ?? item["Id"]);
      if (id.isNotEmpty) yearlyIds.add(id);
    }

    final visible = <dynamic>[];
    final seen = <String>{};
    for (final item in goals) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final key = (map["goalCode"] ?? map["GoalCode"] ?? map["title"] ?? "")
          .toString();
      if (isYearlyGoal(map)) {
        if (!showYearlyGoalTo(map, userId)) {
          for (final month in _monthsOf(map)) {
            if (!showMonthGoalTo(month, userId)) continue;
            final monthKey =
                (month["goalCode"] ?? month["GoalCode"] ?? month["title"] ?? "")
                    .toString();
            if (monthKey.isNotEmpty && !seen.add(monthKey)) continue;
            visible.add(month);
          }
        } else if (key.isEmpty || seen.add(key)) {
          visible.add(item);
        }
        continue;
      }

      final parentId = _idOf(map["parentGoalId"] ?? map["ParentGoalId"]);
      if (parentId.isNotEmpty && yearlyIds.contains(parentId)) continue;
      if (!showMonthGoalTo(map, userId, listedForUser: goalAssigneeIds(map).isEmpty)) {
        continue;
      }
      if (key.isNotEmpty && !seen.add(key)) continue;
      visible.add(item);
    }
    return visible;
  }

  List<Map<String, dynamic>> _monthlyChildren(Map yearly) {
    final parentId = _idOf(yearly["goalId"] ?? yearly["id"] ?? yearly["Id"]);
    if (parentId.isEmpty) return [];

    final months = <Map<String, dynamic>>[];
    for (final item in allGoals) {
      if (item is! Map) continue;
      final parent = _idOf(item["parentGoalId"] ?? item["ParentGoalId"]);
      if (parent != parentId) continue;
      final month = Map<String, dynamic>.from(item);
      month["goalType"] = (month["goalType"] ?? "Monthly").toString();
      month["goalpoints"] = month["goalpoints"] ?? month["points"] ?? 0;
      month["tasks"] = _cardTasks(month["tasks"]);
      month["monthlyGoals"] = <Map<String, dynamic>>[];
      months.add(month);
    }
    return months;
  }

  bool _isYearly(Map goal) {
    return (goal["goalType"] ?? goal["GoalType"] ?? "")
        .toString()
        .toLowerCase() ==
        "yearly";
  }

  String _idOf(dynamic value) {
    if (value == null) return "";
    final text = value.toString().trim();
    if (text.isEmpty || text == "null") return "";
    return text;
  }

  String _assigneeLabel(dynamic item) {
    final names = _assigneeNames(item);
    if (names.isEmpty) return "-";
    return names.join(", ");
  }

  List<String> _assigneeNames(dynamic item) {
    final names = _namesFrom(item);
    if (names.isEmpty && reportUsers.length == 1) {
      _addName(
        names,
        (reportUsers.first["name"] ?? reportUsers.first["Name"] ?? "")
            .toString(),
      );
    }
    if (names.isEmpty && widget.userId != null) {
      _addName(names, _userNameById(widget.userId.toString()));
    }
    return names;
  }

  List<String> _namesFrom(dynamic item) {
    final names = <String>[];

    void read(dynamic raw) {
      if (raw == null || raw is num || raw is bool) return;
      if (raw is String) {
        if (int.tryParse(raw.trim()) != null) return;
        for (final part in raw.split(",")) {
          _addName(names, part);
        }
        return;
      }
      if (raw is Map) {
        final named = (raw["name"] ?? raw["Name"] ?? raw["userName"] ?? "")
            .toString();
        if (named.trim().isNotEmpty) {
          _addName(names, named);
          return;
        }
        final id = (raw["userId"] ?? raw["UserId"] ?? raw["id"] ?? "")
            .toString();
        _addName(names, _userNameById(id));
        return;
      }
      if (raw is List) {
        for (final entry in raw) {
          read(entry);
        }
      }
    }

    if (item is Map) {
      read(item["assignedUsers"] ?? item["AssignedUsers"]);
      read(item["assignedTo"] ?? item["AssignedTo"] ?? item["assignTo"]);
      read(item["members"] ?? item["Members"]);
    }
    return names;
  }

  void _addName(List<String> names, String raw) {
    final name = AppHelpers.extractName(raw).trim();
    if (name.isEmpty || name.toLowerCase() == "n/a") return;
    if (int.tryParse(name) != null) return;
    final exists = names.any(
      (current) => current.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) names.add(name);
  }

  String _userNameById(String rawId) {
    final id = rawId.split("-").first.trim();
    if (id.isEmpty) return "";
    for (final user in reportUsers) {
      final userId = (user["userId"] ?? user["UserId"] ?? "").toString();
      if (userId == id) {
        return (user["name"] ?? user["Name"] ?? "").toString();
      }
    }
    return "";
  }

  bool get _activeDateSet {
    if (workDateBy == "Completed Date") {
      return completedFrom != null || completedTo != null;
    }
    return dueFrom != null || dueTo != null;
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      backgroundColor: WebTheme.brand,
      side: BorderSide.none,
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
      onDeleted: onDelete,
    );
  }

  String _cellDate(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    if (text.isEmpty || text.startsWith("0001-01-01")) return "-";
    return AppHelpers.formatDate(text);
  }

  String _hoursLabel(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    if (text.isEmpty) return "-";
    return "$text hrs";
  }

  String _percentLabel(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? "") ?? 0;
    return "${number.toStringAsFixed(0)}%";
  }

  String _dateRangeLabel() {
    final from = workDateBy == "Completed Date" ? completedFrom : dueFrom;
    final to = workDateBy == "Completed Date" ? completedTo : dueTo;
    final fromText = from == null ? "Any" : TimeUtils.formatDate(from);
    final toText = to == null ? "Any" : TimeUtils.formatDate(to);
    return "$workDateBy: $fromText - $toText";
  }

  Future<void> _pickWorkBound({
    required bool completed,
    required bool isStart,
    required void Function(void Function()) modalSetState,
  }) async {
    final current = completed
        ? (isStart ? completedFrom : completedTo)
        : (isStart ? dueFrom : dueTo);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    modalSetState(() {
      if (completed) {
        if (isStart) {
          completedFrom = picked;
        } else {
          completedTo = picked;
        }
        if (completedFrom != null &&
            completedTo != null &&
            completedFrom!.isAfter(completedTo!)) {
          final swap = completedFrom;
          completedFrom = completedTo;
          completedTo = swap;
        }
      } else {
        if (isStart) {
          dueFrom = picked;
        } else {
          dueTo = picked;
        }
        if (dueFrom != null && dueTo != null && dueFrom!.isAfter(dueTo!)) {
          final swap = dueFrom;
          dueFrom = dueTo;
          dueTo = swap;
        }
      }
      workDateBy = completed ? "Completed Date" : "Due Date";
    });
    applyFilters();
  }

  Future<void> _downloadReport(String kind) async {
    final headers = _exportHeaders();
    final rows = _exportRows();
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No rows to download")),
      );
      return;
    }
    final title = "${_activeTable} Report";
    try {
      final path = kind == "excel"
          ? await ReportExport.saveExcel(
              title: title,
              headers: headers,
              rows: rows,
            )
          : await ReportExport.savePdf(
              title: title,
              headers: headers,
              rows: rows,
            );
      if (!mounted || path.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind == "excel" ? "Excel saved. Open it from your Files app." : "Saved to $path",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save the file")),
      );
    }
  }

  List<String> _exportHeaders() {
    switch (_activeTable) {
      case "Tasks":
        return const [
          "Sl.No",
          "Task",
          "Assigned To",
          "Department",
          "Status",
          "Priority",
          "Points",
          "Target Qty",
          "Completed Qty",
          "Due Date",
          "Completed Date",
          "Overdue",
        ];
      case "Leave":
        return const [
          "Department",
          "Leave Category",
          "Leave Type",
          "Date",
          "Reason",
          "Status",
          "Approved Date",
          "Reject Reason",
          "Compensation Date",
        ];
      case "Permission":
        return const [
          "Department",
          "Reason",
          "Date",
          "From Time",
          "To Time",
          "Total Hours",
          "Submitted Date",
          "Status",
        ];
      case "Overtime":
        return const [
          "Department",
          "Staff",
          "Date",
          "Time",
          "Hours",
          "Reason",
          "Status",
          "Remarks",
        ];
      case "Compensation":
        return const [
          "Department",
          "Staff",
          "Work Date",
          "Work Type",
          "Time",
          "Hours",
          "Reason",
          "Status",
          "Remarks",
          "Used",
        ];
      default:
        return const [
          "Sl.No",
          "Goal",
          "Goal Type",
          "Assigned To",
          "Department",
          "Tasks",
          "Target Qty",
          "Completed Qty",
          "Pending Qty",
          "Status",
          "Priority",
          "Due Date",
          "Completed Date",
          "Progress",
          "Points",
          "Overdue",
        ];
    }
  }

  List<List<String>> _exportRows() {
    switch (_activeTable) {
      case "Tasks":
        return [
          for (var index = 0; index < filteredTasks.length; index++)
            [
              "${index + 1}",
              (filteredTasks[index]["task"] ?? "-").toString(),
              _assigneeLabel(filteredTasks[index]),
              _itemDepartment(filteredTasks[index]).isEmpty
                  ? "-"
                  : _itemDepartment(filteredTasks[index]),
              (filteredTasks[index]["status"] ?? "-").toString(),
              (filteredTasks[index]["priority"] ?? "-").toString(),
              (filteredTasks[index]["points"] ?? 0).toString(),
              _qtyText(filteredTasks[index], completed: false),
              _qtyText(filteredTasks[index], completed: true),
              _cellDate(
                filteredTasks[index]["dueDate"] ??
                    filteredTasks[index]["due_Date"],
              ),
              _cellDate(
                filteredTasks[index]["completedDate"] ??
                    filteredTasks[index]["completed_Date"],
              ),
              filteredTasks[index]["isOverdue"] == true ? "Yes" : "No",
            ],
        ];
      case "Leave":
        return [
          for (final item in filteredLeaves)
            [
              _itemDepartment(item).isEmpty ? "-" : _itemDepartment(item),
              (item["leavecategory"] ?? "-").toString(),
              (item["type"] ?? "-").toString(),
              AppHelpers.formatDate(item["fromDate"] ?? "-"),
              (item["reason"] ?? "").toString(),
              (item["status"] ?? "").toString(),
              AppHelpers.formatDate(item["approvedate"] ?? "-"),
              (item["rejreason"] ?? "-").toString(),
              AppHelpers.formatDate(item["compensationDate"] ?? "-"),
            ],
        ];
      case "Permission":
        return [
          for (final item in filteredPermissions)
            [
              _itemDepartment(item).isEmpty ? "-" : _itemDepartment(item),
              (item["reason"] ?? "").toString(),
              AppHelpers.formatDate(item["date"] ?? "-"),
              (item["fromTime"] ?? "-").toString(),
              (item["toTime"] ?? "-").toString(),
              _hoursLabel(item["totalHours"] ?? item["totalhours"]),
              _cellDate(item["submittedDate"] ?? item["submdate"]),
              (item["status"] ?? "").toString(),
            ],
        ];
      case "Overtime":
        return [
          for (final item in filteredOvertimes)
            [
              _itemDepartment(item).isEmpty ? "-" : _itemDepartment(item),
              _staffName(item),
              _cellDate(item["date"]),
              _timeRange(item["fromTime"], item["toTime"]),
              _hoursLabel(item["totalHours"]),
              (item["reason"] ?? "").toString(),
              _overtimeStatus(item),
              _requestRemarks(item),
            ],
        ];
      case "Compensation":
        return [
          for (final item in filteredCompensations)
            [
              _itemDepartment(item).isEmpty ? "-" : _itemDepartment(item),
              _staffName(item),
              _cellDate(item["workDate"] ?? item["date"]),
              _workTypeLabel(item["workType"]),
              _timeRange(item["startTime"], item["endTime"]),
              _hoursLabel(item["expectedHours"] ?? item["totalHours"]),
              (item["reason"] ?? "").toString(),
              _compensationStatus(item),
              _requestRemarks(item),
              _compensationUsed(item) ? "Yes" : "No",
            ],
        ];
      default:
        return [
          for (var index = 0; index < filteredGoals.length; index++)
            [
              "${index + 1}",
              (filteredGoals[index]["title"] ?? "").toString(),
              (filteredGoals[index]["goalType"] ??
                      filteredGoals[index]["GoalType"] ??
                      "-")
                  .toString(),
              _assigneeLabel(filteredGoals[index]),
              _itemDepartment(filteredGoals[index]).isEmpty
                  ? "-"
                  : _itemDepartment(filteredGoals[index]),
              _goalQtyRows(filteredGoals[index])
                  .map((row) => row.name)
                  .join("\n"),
              _goalQtyRows(filteredGoals[index])
                  .map((row) => row.target)
                  .join("\n"),
              _goalQtyRows(filteredGoals[index])
                  .map((row) => row.done)
                  .join("\n"),
              _goalQtyRows(filteredGoals[index])
                  .map((row) => row.pending)
                  .join("\n"),
              (filteredGoals[index]["status"] ?? "-").toString(),
              (filteredGoals[index]["priority"] ?? "").toString(),
              _cellDate(
                filteredGoals[index]["dueDate"] ??
                    filteredGoals[index]["due_Date"],
              ),
              _cellDate(
                filteredGoals[index]["completedDate"] ??
                    filteredGoals[index]["completed_Date"],
              ),
              _percentLabel(filteredGoals[index]["progress"]),
              (filteredGoals[index]["points"] ?? 0).toString(),
              filteredGoals[index]["isOverdue"] == true ? "Yes" : "No",
            ],
        ];
    }
  }

  Widget buildFilterSheet(void Function(void Function()) modalSetState) {
    final ink = WebTheme.inkOf(context);
    final muted = WebTheme.mutedOf(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: WebTheme.canvasOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              "Filters",
              style: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Choose what to show in the table",
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (widget.department == null && widget.userId == null)
              _filterCard(
                "Department",
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: departmentOptions.contains(selectedDepartment)
                        ? selectedDepartment
                        : null,
                    hint: Text("All departments", style: TextStyle(color: muted)),
                    dropdownColor: WebTheme.surfaceOf(context),
                    style: TextStyle(color: ink, fontSize: 14),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          "All departments",
                          style: TextStyle(color: ink),
                        ),
                      ),
                      for (final name in departmentOptions)
                        DropdownMenuItem<String?>(
                          value: name,
                          child: Text(name, style: TextStyle(color: ink)),
                        ),
                    ],
                    onChanged: (value) {
                      modalSetState(() => selectedDepartment = value);
                      applyFilters();
                    },
                  ),
                ),
              ),
            if (selectedView == "Work") ...[
              _filterCard(
                "Status",
                _buildChoiceChips(
                  values: const [
                    "Not started",
                    "In progress",
                    "Paused",
                    "Pending",
                    "Completed",
                  ],
                  selectedValue: selectedStatus,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedStatus = selectedStatus == value ? null : value;
                    applyFilters();
                  },
                ),
              ),
              _filterCard(
                "Priority",
                _buildChoiceChips(
                  values: const ["Normal", "Medium", "High"],
                  selectedValue: selectedPriority,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedPriority = selectedPriority == value ? null : value;
                    applyFilters();
                  },
                ),
              ),
              _filterCard(
                "Overdue",
                _buildChoiceChips(
                  values: const ["Yes", "No"],
                  selectedValue: selectedOverdue,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedOverdue = selectedOverdue == value ? null : value;
                    applyFilters();
                  },
                ),
              ),
              _dateRangeCard(
                title: "Due date",
                selected: workDateBy == "Due Date",
                from: dueFrom,
                to: dueTo,
                onSelect: () {
                  modalSetState(() => workDateBy = "Due Date");
                  applyFilters();
                },
                onFrom: () => _pickWorkBound(
                  completed: false,
                  isStart: true,
                  modalSetState: modalSetState,
                ),
                onTo: () => _pickWorkBound(
                  completed: false,
                  isStart: false,
                  modalSetState: modalSetState,
                ),
              ),
              _dateRangeCard(
                title: "Completed date",
                selected: workDateBy == "Completed Date",
                from: completedFrom,
                to: completedTo,
                onSelect: () {
                  modalSetState(() => workDateBy = "Completed Date");
                  applyFilters();
                },
                onFrom: () => _pickWorkBound(
                  completed: true,
                  isStart: true,
                  modalSetState: modalSetState,
                ),
                onTo: () => _pickWorkBound(
                  completed: true,
                  isStart: false,
                  modalSetState: modalSetState,
                ),
              ),
            ],
            if (selectedView == "Leave") ...[
              _filterCard(
                "Type",
                _buildChoiceChips(
                  values: const [
                    "Leave",
                    "Permission",
                    "Overtime",
                    "Compensation",
                  ],
                  selectedValue: selectedLeaveView,
                  modalSetState: modalSetState,
                  onSelected: (value) {
                    selectedLeaveView = selectedLeaveView == value
                        ? "Leave"
                        : value;
                    applyFilters();
                  },
                ),
              ),
              if (selectedLeaveView == "Leave") ...[
                _filterCard(
                  "Leave Type",
                  _buildChoiceChips(
                    values: const ["Full Day", "First Half", "Second Half"],
                    selectedValue: selectedLeaveType,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedLeaveType = selectedLeaveType == value
                          ? null
                          : value;
                      applyFilters();
                    },
                  ),
                ),
                _filterCard(
                  "Status",
                  _buildChoiceChips(
                    values: const ["Pending", "Approved", "Rejected"],
                    selectedValue: selectedLeaveStatus,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedLeaveStatus = selectedLeaveStatus == value
                          ? null
                          : value;
                      applyFilters();
                    },
                  ),
                ),
              ],
              if (selectedLeaveView == "Permission")
                _filterCard(
                  "Status",
                  _buildChoiceChips(
                    values: const ["Pending", "Approved", "Rejected"],
                    selectedValue: selectedPermissionStatus,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedPermissionStatus =
                          selectedPermissionStatus == value ? null : value;
                      applyFilters();
                    },
                  ),
                ),
              if (selectedLeaveView == "Overtime")
                _filterCard(
                  "Status",
                  _buildChoiceChips(
                    values: const ["Pending", "Accepted", "Approved", "Rejected"],
                    selectedValue: selectedOvertimeStatus,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedOvertimeStatus = selectedOvertimeStatus == value
                          ? null
                          : value;
                      applyFilters();
                    },
                  ),
                ),
              if (selectedLeaveView == "Compensation")
                _filterCard(
                  "Status",
                  _buildChoiceChips(
                    values: const ["Pending", "Accepted", "Approved", "Rejected"],
                    selectedValue: selectedCompensationStatus,
                    modalSetState: modalSetState,
                    onSelected: (value) {
                      selectedCompensationStatus =
                          selectedCompensationStatus == value ? null : value;
                      applyFilters();
                    },
                  ),
                ),
              _filterCard(
                "Date",
                Row(
                  children: [
                    _rangeDateButton(
                  caption: "Date",
                  selected: true,
                  value: selectedLeaveDate != null
                      ? AppHelpers.formatDate(
                          selectedLeaveDate!.toIso8601String(),
                        )
                      : "Pick date",
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedLeaveDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked == null) return;
                    modalSetState(() {
                      selectedLeaveDate = selectedLeaveDate == picked
                          ? null
                          : picked;
                      selectedPermissionDate = selectedLeaveDate;
                    });
                    applyFilters();
                  },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: "Clear Filters",
                isLoading: _isLoading,
                onPressed: () {
                  modalSetState(() {
                    selectedStatus = null;
                    selectedPriority = null;
                    selectedOverdue = null;
                    selectedDepartment = null;
                    dueFrom = null;
                    dueTo = null;
                    completedFrom = null;
                    completedTo = null;
                    workDateBy = "Due Date";
                    selectedLeaveType = null;
                    selectedLeaveStatus = null;
                    selectedPermissionStatus = null;
                    selectedOvertimeStatus = null;
                    selectedCompensationStatus = null;
                    selectedLeaveDate = null;
                    selectedPermissionDate = null;
                    selectedLeaveView = null;
                  });
                  applyFilters();
                },
                color: WebTheme.brand,
                txtcolor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: WebTheme.inkOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _dateRangeCard({
    required String title,
    required bool selected,
    required DateTime? from,
    required DateTime? to,
    required VoidCallback onSelect,
    required VoidCallback onFrom,
    required VoidCallback onTo,
  }) {
    final border = selected ? WebTheme.brand : WebTheme.lineOf(context);
    final titleColor = selected ? WebTheme.brand : WebTheme.mutedOf(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: selected
            ? WebTheme.brandSoftOf(context)
            : WebTheme.canvasOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: selected ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onSelect,
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: titleColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _rangeDateButton(
                caption: "From",
                value: from == null ? "Pick date" : TimeUtils.formatDate(from),
                selected: selected,
                onTap: onFrom,
              ),
              const SizedBox(width: 8),
              _rangeDateButton(
                caption: "To",
                value: to == null ? "Pick date" : TimeUtils.formatDate(to),
                selected: selected,
                onTap: onTo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeDateButton({
    required String caption,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final tone = selected ? WebTheme.brand : WebTheme.mutedOf(context);
    return Expanded(
      child: Material(
        color: selected
            ? WebTheme.surfaceOf(context)
            : WebTheme.canvasOf(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? WebTheme.brand : WebTheme.lineOf(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: TextStyle(
                    color: WebTheme.mutedOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: tone, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: tone,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> values,
    required String? selectedValue,
    required void Function(void Function()) modalSetState,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = selectedValue == value;
        return Material(
          color: isSelected ? WebTheme.brand : WebTheme.canvasOf(context),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              modalSetState(() {
                onSelected(value);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? WebTheme.brand : WebTheme.lineOf(context),
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: isSelected ? Colors.white : WebTheme.mutedOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DownloadChoice extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DownloadChoice({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
