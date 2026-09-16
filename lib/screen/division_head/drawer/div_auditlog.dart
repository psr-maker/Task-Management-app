import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/auditlog.dart';
import 'package:staff_work_track/Models/department.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/auditcard.dart';

class DivAuditLog extends StatefulWidget {
  final String department;

  const DivAuditLog({super.key, required this.department});

  @override
  State<DivAuditLog> createState() => _DivAuditLogState();
}

class _DivAuditLogState extends State<DivAuditLog> {
  bool isLoading = true;
  String selectedDepartment = "All";
  DateTimeRange? selectedRange;
  List<AuditLogModel> allLogs = [];
  Map<int, String> departmentNamesById = {};
  Map<String, UserModel> usersById = {};
  Map<String, String> taskNamesByCode = {};
  Map<String, String> goalNamesByCode = {};
  List<Role> roles = [];
  String? errorMessage;

  List<String> get childDepartments =>
      DivisionConfig.childDepartments(widget.department);

  List<String> get departmentChips {
    final chips = <String>["All"];
    final parent = widget.department.trim();
    if (parent.isNotEmpty) chips.add(parent);
    for (final dept in childDepartments) {
      if (!chips.any((item) => _isSameDepartment(dept, item))) {
        chips.add(dept);
      }
    }
    return chips;
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final logs = await SuperAdminService.getMyDepartmentAuditLogs();
      var departments = <Department>[];
      try {
        departments = await SuperAdminService().getDepartments();
      } catch (_) {}

      var users = <UserModel>[];
      try {
        users = await SuperAdminService.getAllUsers();
      } catch (_) {
        try {
          users = await AdminService.getEmployeesByDepartments([
            if (widget.department.trim().isNotEmpty) widget.department,
            ...childDepartments,
          ]);
        } catch (_) {}
      }

      var rolesList = <Role>[];
      try {
        rolesList = await SuperAdminService.getRoles();
      } catch (_) {}

      final taskNames = <String, String>{};
      final goalNames = <String, String>{};
      await _loadEntityNames(taskNames, goalNames);

      if (!mounted) return;

      final namesById = <int, String>{};
      for (final dept in departments) {
        if (dept.id != null && dept.departmentName.trim().isNotEmpty) {
          namesById[dept.id!] = dept.departmentName.trim();
        }
      }

      setState(() {
        allLogs = logs;
        departmentNamesById = namesById;
        usersById = {
          for (final user in users) user.userId.toString(): user,
        };
        taskNamesByCode = taskNames;
        goalNamesByCode = goalNames;
        roles = rolesList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  bool _isSameDepartment(String a, String b) {
    return DivisionConfig.isAllowedDepartment(a, [b]);
  }

  Future<void> _loadEntityNames(
    Map<String, String> tasks,
    Map<String, String> goals,
  ) async {
    try {
      _collectEntityNames(await SuperAdminService.getGoals(), tasks, goals);
    } catch (_) {}
    try {
      _collectEntityNames(await SuperAdminService.getGoalsname(), tasks, goals);
    } catch (_) {}
    try {
      _collectEntityNames(await SuperAdminService.getAllTasks(), tasks, goals);
    } catch (_) {}

    final departments = [
      if (widget.department.trim().isNotEmpty) widget.department,
      ...childDepartments,
    ];
    for (final dept in departments) {
      try {
        _collectEntityNames(
          await AdminService.getTasksByDepartment(dept),
          tasks,
          goals,
        );
      } catch (_) {}
      try {
        _collectEntityNames(
          await AdminService.getGoalsByDepartment(dept),
          tasks,
          goals,
        );
      } catch (_) {}
    }
  }

  void _collectEntityNames(
    dynamic data,
    Map<String, String> tasks,
    Map<String, String> goals,
  ) {
    if (data is List) {
      for (final item in data) {
        _collectEntityNames(item, tasks, goals);
      }
      return;
    }
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final taskCode =
        (map['taskCode'] ?? map['TaskCode'] ?? '').toString().trim();
    final taskName =
        (map['task'] ?? map['taskName'] ?? map['TaskName'] ?? '')
            .toString()
            .trim();
    if (taskCode.isNotEmpty && taskName.isNotEmpty) {
      tasks[taskCode] = taskName;
    }

    final goalCode =
        (map['goalCode'] ?? map['GoalCode'] ?? '').toString().trim();
    final goalName =
        (map['title'] ?? map['goalName'] ?? map['GoalName'] ?? '')
            .toString()
            .trim();
    if (goalCode.isNotEmpty && goalName.isNotEmpty) {
      goals[goalCode] = goalName;
    }

    for (final key in const [
      'tasks',
      'Tasks',
      'goals',
      'Goals',
      'data',
      'Data',
      'result',
      'Result',
    ]) {
      if (map[key] != null) {
        _collectEntityNames(map[key], tasks, goals);
      }
    }
  }

  bool _isCodeId(String value) {
    final text = value.trim();
    if (text.isEmpty) return true;
    if (int.tryParse(text) != null) return true;
    return RegExp(r'^[tgTG]\d+$').hasMatch(text);
  }

  String? _lookupName(Map<String, String> names, String? key) {
    if (key == null) return null;
    final value = key.trim();
    if (value.isEmpty) return null;
    final direct = names[value];
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    final lower = value.toLowerCase();
    for (final entry in names.entries) {
      if (entry.key.toLowerCase() == lower && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    return null;
  }

  String _nameFromChanges(
    AuditLogGroupModel log, {
    required List<String> fields,
  }) {
    for (final change in log.changes) {
      final field = (change.fieldChanged ?? '').toLowerCase();
      if (!fields.any((item) => field.contains(item))) continue;
      final next = (change.newValue ?? '').trim();
      if (next.isNotEmpty && !_isCodeId(next)) return next;
      final prev = (change.oldValue ?? '').trim();
      if (prev.isNotEmpty && !_isCodeId(prev)) return prev;
    }
    return '';
  }

  String _userDisplayName(AuditLogGroupModel log) {
    final user = usersById[log.entityId];
    if (user != null && user.name.trim().isNotEmpty) return user.name.trim();

    final fromChanges = _nameFromChanges(log, fields: ['name', 'username']);
    if (fromChanges.isNotEmpty) return fromChanges;

    return 'Unknown User';
  }

  String _taskDisplayName(AuditLogGroupModel log) {
    if (log.taskName != null &&
        log.taskName!.trim().isNotEmpty &&
        !_isCodeId(log.taskName!)) {
      return log.taskName!.trim();
    }

    final fromCode = _lookupName(taskNamesByCode, log.taskCode);
    if (fromCode != null) return fromCode;

    final fromEntity = _lookupName(taskNamesByCode, log.entityId) ??
        _lookupName(taskNamesByCode, 'T${log.entityId}') ??
        _lookupName(taskNamesByCode, 't${log.entityId}');
    if (fromEntity != null) return fromEntity;

    final fromChanges = _nameFromChanges(log, fields: ['task', 'name', 'title']);
    if (fromChanges.isNotEmpty) return fromChanges;

    return 'Unknown Task';
  }

  String _goalDisplayName(AuditLogGroupModel log) {
    final fromEntity = _lookupName(goalNamesByCode, log.entityId) ??
        _lookupName(goalNamesByCode, 'G${log.entityId}') ??
        _lookupName(goalNamesByCode, 'g${log.entityId}');
    if (fromEntity != null) return fromEntity;

    final fromChanges = _nameFromChanges(log, fields: ['goal', 'title', 'name']);
    if (fromChanges.isNotEmpty) return fromChanges;

    return 'Unknown Goal';
  }

  String _entityTitle(AuditLogGroupModel log) {
    switch (log.entityType.trim().toLowerCase()) {
      case 'user':
        return 'User : ${_userDisplayName(log)}';
      case 'task':
        return 'Task : ${_taskDisplayName(log)}';
      case 'goal':
        return 'Goal : ${_goalDisplayName(log)}';
      case 'department':
        return 'Department : ${log.department}';
      default:
        return log.entityType;
    }
  }

  List<AuditLogModel> _dateFilteredLogs() {
    if (selectedRange == null) return List<AuditLogModel>.from(allLogs);

    final start = DateTime(
      selectedRange!.start.year,
      selectedRange!.start.month,
      selectedRange!.start.day,
    );
    final end = DateTime(
      selectedRange!.end.year,
      selectedRange!.end.month,
      selectedRange!.end.day,
      23,
      59,
      59,
    );
    return allLogs.where((log) {
      final date = log.changeDateTime.toLocal();
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  List<AuditLogGroupModel> _visibleLogs() {
    final grouped = _groupLogs(_dateFilteredLogs());
    if (selectedDepartment == "All") return grouped;

    return grouped
        .where((log) => _isSameDepartment(log.department, selectedDepartment))
        .toList();
  }

  String _logDepartment(AuditLogModel log) {
    final entityType = log.entityType.trim().toLowerCase();

    if (entityType == 'user') {
      final user = usersById[log.entityId];
      if (user != null && user.department.trim().isNotEmpty) {
        return user.department.trim();
      }
    }

    if (entityType == 'department') {
      final entityId = int.tryParse(log.entityId);
      if (entityId != null) {
        final fromEntity = departmentNamesById[entityId];
        if (fromEntity != null && fromEntity.trim().isNotEmpty) {
          return fromEntity.trim();
        }
      }
    }

    if (log.departmentName.trim().isNotEmpty) {
      return log.departmentName.trim();
    }

    if (log.departmentId != 0) {
      final fromId = departmentNamesById[log.departmentId];
      if (fromId != null && fromId.trim().isNotEmpty) return fromId.trim();
    }

    final actor = usersById[log.editedById];
    if (actor != null && actor.department.trim().isNotEmpty) {
      return actor.department.trim();
    }

    return '';
  }

  UserModel? _actorOf(AuditLogModel log) => usersById[log.editedById];

  String _actorName(AuditLogModel log) {
    final actor = _actorOf(log);
    if (actor != null && actor.name.trim().isNotEmpty) return actor.name.trim();
    if (log.editedByName.trim().isNotEmpty) return log.editedByName.trim();
    return "Unknown User";
  }

  String _displayDepartment(AuditLogModel log) {
    final fromLog = _logDepartment(log);
    return fromLog.isNotEmpty ? fromLog : "Unknown";
  }

  String _roleLabel(String? roleValue, UserModel? user) {
    final fromRole = _roleName(roleValue);
    if (fromRole.isNotEmpty && int.tryParse(fromRole) == null) return fromRole;

    if (user != null) {
      final fromUser = _roleName(user.role);
      if (fromUser.isNotEmpty && int.tryParse(fromUser) == null) return fromUser;
      if (fromUser.isNotEmpty) return fromUser;
    }

    return fromRole.isNotEmpty ? fromRole : "Unknown";
  }

  String _roleName(String? value) {
    if (value == null || value.trim().isEmpty) return '';

    final raw = value.trim();
    final id = int.tryParse(raw);
    if (id != null) {
      for (final role in roles) {
        if (role.id == id) return role.name;
      }
    }

    for (final role in roles) {
      if (role.name.toLowerCase() == raw.toLowerCase()) return role.name;
    }

    return raw;
  }

  List<AuditLogGroupModel> _groupLogs(List<AuditLogModel> logs) {
    final grouped = <String, List<AuditLogModel>>{};

    for (final log in logs) {
      final key =
          "${log.entityType}_${log.entityId}_${log.changeDateTime.toString().substring(0, 16)}";
      grouped.putIfAbsent(key, () => []).add(log);
    }

    return grouped.values.map((group) {
      final first = group.first;
      return AuditLogGroupModel(
        entityType: first.entityType,
        entityId: first.entityId,
        action: first.action,
        editedByName: _actorName(first),
        editedRole: _roleLabel(first.editedRole, _actorOf(first)),
        department: _displayDepartment(first),
        taskCode: first.taskCode,
        taskName: first.taskName,
        dateTime: first.changeDateTime,
        changes: group,
      );
    }).toList();
  }

  Color actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'edit':
        return Colors.orange;
      case 'delete':
        return Theme.of(context).colorScheme.error;
      case 'logout':
        return Theme.of(context).colorScheme.error;
      case 'login':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  IconData actionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'logout':
        return Icons.logout;
      case 'login':
        return Icons.login;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _visibleLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Audit Log"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final now = DateTime.now();
              final pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: now,
                initialDateRange: selectedRange,
              );
              if (pickedRange != null) {
                setState(() => selectedRange = pickedRange);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              children: departmentChips.map(_buildDeptChip).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: RotatingFlower())
                : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: groupedLogs.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 160),
                              Center(
                                child: Text(
                                  selectedDepartment == "All"
                                      ? "No audit logs found"
                                      : "No audit logs found for ${selectedDepartment.replaceAll(" Department", "")}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: groupedLogs.length,
                            itemBuilder: (context, index) {
                              return _buildAuditItem(groupedLogs[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == "All"
        ? dept == "All"
        : _isSameDepartment(selectedDepartment, dept);
    final label = dept == "All" ? "All" : dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => selectedDepartment = dept),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? secondary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? secondary : const Color(0xFFD0D5D2),
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
                  color: selected ? Colors.white : secondary,
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

  Widget _buildAuditItem(AuditLogGroupModel log) {
    final color = actionColor(log.action);
    final displayName =
        log.editedByName.isNotEmpty ? log.editedByName : "Unknown User";
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon(log.action), color: color, size: 18),
              ),
              Container(width: 2, height: 120, color: color.withOpacity(0.25)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AuditCard(
              color: color,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withOpacity(0.1),
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "$displayName (${log.editedRole} · ${log.department})",
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _entityTitle(log),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (log.action.toLowerCase() != "delete") ...[
                      const Divider(height: 20),
                      Text(
                        "Changes",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      ...log.changes.map(
                        (change) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${change.fieldChanged ?? 'Field'}: ${change.oldValue ?? ''} → ${change.newValue ?? ''}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        log.dateTime.toLocal().toString().split('.').first,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
