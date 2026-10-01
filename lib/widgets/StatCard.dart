import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/admintask_list.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/edit_goal.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/screen/admin/Navigation/my work/Task status tab/yearly_monthly_goals.dart';

List<Map> taskAssignees(Map task) {
  final raw = task["assignedTo"] ??
      task["AssignedTo"] ??
      task["members"] ??
      task["Members"] ??
      task["assignedMembers"] ??
      task["assignedUsers"] ??
      task["AssignedUsers"];
  if (raw is! List) return const [];
  return raw.whereType<Map>().toList();
}

bool _missingMemberName(String name) {
  final text = name.trim().toLowerCase();
  return text.isEmpty || text == "null" || text == "n/a";
}

String memberUserId(Map user) {
  final nested = user["user"] ?? user["User"];
  final source = nested is Map ? nested : user;
  final raw = (source["userId"] ??
          source["UserId"] ??
          source["id"] ??
          source["Id"] ??
          "")
      .toString()
      .trim();
  if (raw.contains("-")) return raw.split("-").first.trim();
  return raw;
}

String? memberDisplayName(Map user) {
  final nested = user["user"] ?? user["User"];
  final source = nested is Map ? nested : user;
  final name = (source["name"] ??
          source["Name"] ??
          source["staffName"] ??
          source["StaffName"] ??
          source["userName"] ??
          source["UserName"] ??
          source["fullName"] ??
          source["FullName"] ??
          "")
      .toString()
      .trim();
  if (!_missingMemberName(name)) return name;

  final raw = (source["userId"] ?? source["UserId"] ?? "").toString().trim();
  if (raw.contains("-")) {
    final extracted = AppHelpers.extractName(raw).trim();
    if (!_missingMemberName(extracted)) return extracted;
  }
  return null;
}

String taskMemberLabel(Map task) {
  final names = <String>[];
  for (final user in taskAssignees(task)) {
    final name = memberDisplayName(user);
    if (name != null) names.add(name);
  }
  if (names.length == 1) return names.first;
  if (names.length > 1) return names.join(", ");

  final total = task["totalMembers"] ?? task["TotalMembers"];
  final count = total is num ? total.round() : int.tryParse("${total ?? ""}");
  if (count != null && count > 0) return "$count Members";
  return "No members";
}

class SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SmallStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  Widget _tappable(Widget child) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppLayout.isMobile(context)) {
      return _tappable(Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withAlpha(25),
          border: Border.all(color: color.withAlpha(70), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 5),
              Text(value, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ));
    }

    return _tappable(Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: WebTheme.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: WebTheme.inkOf(context),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WebTheme.mutedOf(context),
            ),
          ),
        ],
      ),
    ));
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final Color statusColor;
  final Color priorityColor;
  final VoidCallback onTap;
  final String Function(String?) formatDate;

  const TaskCard({
    super.key,
    required this.task,
    required this.statusColor,
    required this.priorityColor,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, // <-- uses theme card color
          borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
              ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
              : BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.secondary, width: 1.2),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 55,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task["task"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.group),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          taskMemberLabel(task),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Due: ${formatDate(task["dueDate"])}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            // Right section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task["priority"] ?? "",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task["status"] ?? "",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Taskstatus extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;
  final Future<void> Function(Map<String, dynamic> task)? onStatusSaved;

  const Taskstatus({
    super.key,
    required this.task,
    required this.onTap,
    this.onStatusSaved,
  });

  @override
  State<Taskstatus> createState() => _TaskCardState();
}

class _TaskCardState extends State<Taskstatus> {
  late TaskStatus selectedStatus;
  bool isUpdating = false;
  bool _canEditStatus = false;
  bool _permissionChecked = false;
  bool _quantityFetchStarted = false;
  int? _userId;

  bool get isCompleted => selectedStatus == TaskStatus.completed;

  static const _assignedQtyKeys = [
    "quantity",
    "Quantity",
    "qty",
    "Qty",
    "taskQuantity",
    "TaskQuantity",
  ];

  static const _completedQtyKeys = [
    "completedQuantity",
    "CompletedQuantity",
    "achievedQuantity",
    "AchievedQuantity",
  ];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    selectedStatus = TaskUtils.parseStatus(
      widget.task["status"]!.toString().trim(),
    );
    _loadUserId();
    _loadQuantitySplits();
    _checkPermissions();
    _ensureCompletedQuantity();
  }

  Future<void> _loadQuantitySplits() async {
    if (widget.task["quantitySplits"] is List ||
        widget.task["QuantitySplits"] is List) {
      return;
    }
    final code =
        (widget.task["taskCode"] ?? widget.task["TaskCode"])?.toString() ?? "";
    if (code.isEmpty) return;
    try {
      final details = _asTaskMap(await SuperAdminService.getTaskByCode(code));
      final splits = details["quantitySplits"] ?? details["QuantitySplits"];
      if (splits is List) widget.task["quantitySplits"] = splits;
      final people = details["assignedTo"] ?? details["AssignedTo"];
      if (people is List) widget.task["assignedTo"] = people;
      final done = readGoalInt(details, _completedQtyKeys);
      if (done != null) widget.task["completedQuantity"] = done;
      _keepTaskOpenUntilEveryShareIsDone();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Quantity split load failed: $e");
    }
  }

  Future<void> _loadUserId() async {
    final token = await AuthService.getToken();
    if (!mounted || token == null) return;
    final id = int.tryParse(JwtHelper.getuid(token) ?? "");
    if (id == null) return;
    setState(() {
      _userId = id;
      _keepTaskOpenUntilEveryShareIsDone();
    });
  }

  void _keepTaskOpenUntilEveryShareIsDone() {
    final shares = widget.task["quantitySplits"] ?? widget.task["QuantitySplits"];
    if (shares is! List || shares.isEmpty) return;
    final userId = _userId;
    if (userId != null) {
      final mine = memberUserStatus(widget.task, userId);
      if (mine != null) {
        selectedStatus = TaskUtils.parseStatus(mine);
        return;
      }
    }
    if (allQuantitySharesCompleted(widget.task)) {
      widget.task["status"] = "Completed";
      selectedStatus = TaskStatus.completed;
      return;
    }
    widget.task["status"] = "In Progress";
    if (selectedStatus == TaskStatus.completed) {
      selectedStatus = TaskStatus.inProgress;
    }
  }

  int get _myQuantity {
    final userId = _userId;
    if (userId != null) {
      final share = memberShareQuantity(widget.task, userId);
      if (share != null && share > 0) return share;
    }
    return taskAssignedQty(widget.task);
  }

  int get _myCompleted {
    final userId = _userId;
    if (userId != null) {
      final share = memberShareCompleted(widget.task, userId);
      if (share != null) return share;
    }
    return taskAchievedQty(widget.task);
  }

  Future<void> _checkPermissions() async {
    try {
      final token = await AuthService.getToken();
      if (!mounted) return;
      if (token == null) {
        _setStateIfMounted(() {
          _canEditStatus = false;
          _permissionChecked = true;
        });
        return;
      }

      final loginUserId = JwtHelper.getuid(token)?.toString().trim();
      final userRole = JwtHelper.getRole(token)?.toLowerCase().trim();
      final userDepartment = JwtHelper.getDepartment(
        token,
      )?.toLowerCase().trim();

      if (loginUserId == null || userRole == null) {
        _setStateIfMounted(() {
          _canEditStatus = false;
          _permissionChecked = true;
        });
        return;
      }

      final assignedTo = taskAssignees(widget.task);
      if (assignedTo.isEmpty) {
        _setStateIfMounted(() {
          _canEditStatus = false;
          _permissionChecked = true;
        });
        return;
      }

      // Directors can edit any task (no restrictions)
      if (userRole == "1") {
        _setStateIfMounted(() {
          _canEditStatus = true;
          _permissionChecked = true;
        });
        return;
      }

      // Check if login user is in the assigned list
      bool isAssignedToUser = false;
      for (final staff in assignedTo) {
        final staffUserId = memberUserId(staff);
        if (staffUserId == loginUserId) {
          isAssignedToUser = true;
          break;
        }
      }

      // Staff can only edit if task is assigned to them
      if (userRole != "3") {
        _setStateIfMounted(() {
          _canEditStatus = isAssignedToUser;
          _permissionChecked = true;
        });
        return;
      }

      // Managers: can edit if assigned to them OR if staff are in their department
      if (isAssignedToUser) {
        _setStateIfMounted(() {
          _canEditStatus = true;
          _permissionChecked = true;
        });
        return;
      }

      if (userDepartment == null) {
        _setStateIfMounted(() {
          _canEditStatus = false;
          _permissionChecked = true;
        });
        return;
      }

      // Check if at least one staff member is in the manager's department
      bool hasStaffInDepartment = false;
      for (final staff in assignedTo) {
        final staffDept =
            (staff["department"] ?? staff["Department"])?.toString().toLowerCase().trim();
        if (staffDept == userDepartment) {
          hasStaffInDepartment = true;
          break;
        }
      }

      _setStateIfMounted(() {
        _canEditStatus = hasStaffInDepartment;
        _permissionChecked = true;
      });
    } catch (e) {
      debugPrint("Permission check error: $e");
      _setStateIfMounted(() {
        _canEditStatus = false;
        _permissionChecked = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant Taskstatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.task["status"] != widget.task["status"]) {
      selectedStatus = TaskUtils.parseStatus(
        widget.task["status"]!.toString().trim(),
      );
      if (isCompleted) {
        _quantityFetchStarted = false;
        _ensureCompletedQuantity();
      }
    }
    final oldCode = oldWidget.task["taskCode"] ?? oldWidget.task["TaskCode"];
    final newCode = widget.task["taskCode"] ?? widget.task["TaskCode"];
    if (oldCode != newCode) {
      _quantityFetchStarted = false;
      _ensureCompletedQuantity();
    }
  }

  bool _mapHasKey(Map task, List<String> keys) {
    for (final key in keys) {
      if (task.containsKey(key) && task[key] != null) return true;
    }
    return false;
  }

  bool get _taskMeasuresQuantity {
    final type = (widget.task["performanceType"] ??
            widget.task["PerformanceType"] ??
            "")
        .toString()
        .toLowerCase()
        .trim();
    if (type == "qty" || type == "quantity") return true;
    if (type.isNotEmpty) return false;
    return taskAssignedQty(widget.task) > 0 ||
        !_mapHasKey(widget.task, _assignedQtyKeys);
  }

  Future<void> _ensureCompletedQuantity() async {
    if (!isCompleted || _quantityFetchStarted || !_taskMeasuresQuantity) return;
    final hasTarget = _mapHasKey(widget.task, _assignedQtyKeys);
    final hasDone = _mapHasKey(widget.task, _completedQtyKeys);
    if (hasTarget && taskAssignedQty(widget.task) <= 0) return;
    if (hasTarget && hasDone) return;

    _quantityFetchStarted = true;
    await _loadAssignedQuantity(includeCompleted: true);
    _setStateIfMounted(() {});
  }

  Map<String, dynamic> _asTaskMap(Map raw) {
    for (final key in ["task", "data", "result"]) {
      final nested = raw[key];
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<int> _loadAssignedQuantity({bool includeCompleted = false}) async {
    final current = taskAssignedQty(widget.task);
    final needsCompleted =
        includeCompleted && !_mapHasKey(widget.task, _completedQtyKeys);
    if (current > 0 && !needsCompleted) return current;

    final code =
        (widget.task["taskCode"] ?? widget.task["TaskCode"])?.toString() ?? "";
    if (code.isEmpty) return current;

    try {
      final details = _asTaskMap(await SuperAdminService.getTaskByCode(code));
      final assigned = readGoalInt(details, _assignedQtyKeys);
      if (assigned != null && assigned > 0) {
        widget.task["quantity"] = assigned;
      }
      final type = details["performanceType"] ?? details["PerformanceType"];
      if (type != null) widget.task["performanceType"] = type;
      final achieved = readGoalInt(details, _completedQtyKeys);
      if (achieved != null) {
        widget.task["completedQuantity"] = achieved;
      }
      return taskAssignedQty(widget.task);
    } catch (e) {
      debugPrint("Task quantity load failed: $e");
      return current;
    }
  }

  Future<int?> _loadSavedCompletedQuantity() async {
    final code =
        (widget.task["taskCode"] ?? widget.task["TaskCode"])?.toString() ?? "";
    if (code.isEmpty) return null;
    try {
      final details = _asTaskMap(await SuperAdminService.getTaskByCode(code));
      final splits = details["quantitySplits"] ?? details["QuantitySplits"];
      if (splits is List) widget.task["quantitySplits"] = splits;
      final people = details["assignedTo"] ?? details["AssignedTo"];
      if (people is List) widget.task["assignedTo"] = people;
      _keepTaskOpenUntilEveryShareIsDone();
      final taskDone = readGoalInt(details, _completedQtyKeys);
      if (taskDone != null) widget.task["completedQuantity"] = taskDone;
      final userId = _userId;
      if (userId != null) {
        return memberShareCompleted(widget.task, userId) ?? taskDone;
      }
      return taskDone;
    } catch (e) {
      debugPrint("Saved completed quantity load failed: $e");
      return null;
    }
  }

  Future<int?> _askAchievedQuantity(int target) {
    final existing = taskAchievedQty(widget.task);
    return showDialog<int>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => _CompletedQuantityDialog(
        target: target,
        initialValue: existing > 0 ? existing.toString() : "",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = TaskUtils.getStatusColor(selectedStatus);
    final priorityColor = TaskUtils.getPriorityColor(widget.task["priority"]);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // color: Theme.of(context).colorScheme.onPrimary,
          color: isDark
              ? Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Status bar
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),

            /// Task Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task["task"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (!isCompleted &&
                      _userId != null &&
                      (memberShareQuantity(widget.task, _userId!) ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Your quantity ${formatGoalQty(_myQuantity)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (isCompleted && _taskMeasuresQuantity) ...[
                    const SizedBox(height: 4),
                    Text(
                      _myQuantity > 0
                          ? "Completed Qty ${formatGoalQty(_myCompleted)} of ${formatGoalQty(_myQuantity)}"
                          : "Completed Qty ${formatGoalQty(_myCompleted)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B7A3A),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          taskMemberLabel(widget.task),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Due: ${AppHelpers.formatDate(widget.task["dueDate"])}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            /// Right side
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.task["priority"] ?? "",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                /// STATUS DROPDOWN
                Tooltip(
                  message: !_permissionChecked
                      ? "Loading permissions..."
                      : !_canEditStatus
                      ? "Permission denied: Managers can only edit their department staff tasks"
                      : "Click to change status",
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: !_permissionChecked || !_canEditStatus
                          ? Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: DropdownButton<TaskStatus>(
                      value: selectedStatus,
                      underline: const SizedBox(),
                      isDense: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: !_canEditStatus ? Colors.grey : null,
                      ),
                      items: TaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            TaskUtils.getStatusText(status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: TaskUtils.getStatusColor(status),
                            ),
                          ),
                        );
                      }).toList(),

                      onChanged:
                          (isUpdating ||
                              isCompleted ||
                              !_canEditStatus ||
                              !_permissionChecked)
                          ? null
                          : (value) async {
                              if (value == null || value == selectedStatus) {
                                return;
                              }
                              final previous = selectedStatus;
                              int? achievedQuantity;
                              if (value != TaskStatus.completed) {
                                var assigned = _myQuantity;
                                if (assigned <= 0) {
                                  assigned = await _loadAssignedQuantity();
                                }
                                if (!mounted) return;
                                final currentQuantity = assigned > 0
                                    ? taskAchievedQty(widget.task)
                                    : null;
                                _setStateIfMounted(() {
                                  selectedStatus = value;
                                  isUpdating = true;
                                });
                                try {
                                  await AdminService.updateTaskStatus(
                                    taskCode: widget.task["taskCode"],
                                    status: value,
                                    achievedQuantity: currentQuantity,
                                  );
                                  widget.task["status"] =
                                      TaskUtils.getStatusText(value);
                                  await widget.onStatusSaved?.call(widget.task);
                                } catch (e) {
                                  if (!mounted) return;
                                  _setStateIfMounted(() {
                                    selectedStatus = previous;
                                  });
                                  final message = e
                                      .toString()
                                      .replaceFirst("Exception: ", "");
                                  showAppMessage(context, message);
                                } finally {
                                  _setStateIfMounted(() => isUpdating = false);
                                }
                                return;
                              }

                              await Future<void>.delayed(
                                const Duration(milliseconds: 300),
                              );
                              if (!mounted) return;
                              final assigned = _myQuantity > 0
                                  ? _myQuantity
                                  : await _loadAssignedQuantity();
                              if (!mounted) return;
                              if (assigned > 0) {
                                achievedQuantity = await _askAchievedQuantity(
                                  assigned,
                                );
                                if (!mounted || achievedQuantity == null) {
                                  return;
                                }
                              }

                              _setStateIfMounted(() {
                                selectedStatus = value;
                                isUpdating = true;
                              });

                              try {
                                await AdminService.updateTaskStatus(
                                  taskCode: widget.task["taskCode"],
                                  status: value,
                                  achievedQuantity: achievedQuantity,
                                );
                                widget.task["status"] =
                                    TaskUtils.getStatusText(value);
                                await _loadSavedCompletedQuantity();
                                if (_userId != null) {
                                  final mine = memberShareCompleted(
                                    widget.task,
                                    _userId!,
                                  );
                                  if (mine != null) {
                                    widget.task["myCompletedQuantity"] = mine;
                                  }
                                }
                                await widget.onStatusSaved?.call(widget.task);
                              } catch (e) {
                                if (!mounted) return;
                                _setStateIfMounted(() {
                                  selectedStatus = previous;
                                });
                                final message = e
                                    .toString()
                                    .replaceFirst("Exception: ", "");
                                showAppMessage(context, message);
                              } finally {
                                _setStateIfMounted(() => isUpdating = false);
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedQuantityDialog extends StatefulWidget {
  final int target;
  final String initialValue;

  const _CompletedQuantityDialog({
    required this.target,
    required this.initialValue,
  });

  @override
  State<_CompletedQuantityDialog> createState() =>
      _CompletedQuantityDialogState();
}

class _CompletedQuantityDialogState extends State<_CompletedQuantityDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entered = int.tryParse(_controller.text.trim());
    final percent = entered == null
        ? null
        : quantityPercent(entered, widget.target);
    return AlertDialog(
      title: const Text("Completed quantity"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Target quantity is ${formatGoalQty(widget.target)}. Enter what was completed.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(
                labelText: "Completed quantity",
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: 8),
              Text(
                "Achieved ${formatGoalQty(entered!)} of ${formatGoalQty(widget.target)} · ${formatQuantityPercent(percent)}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: percent >= 100
                      ? const Color(0xFF1B7A3A)
                      : const Color(0xFFB45309),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final value = int.tryParse(_controller.text.trim());
            if (value == null || value < 0) {
              setState(() {
                _error = "Enter a completed quantity of 0 or more";
              });
              return;
            }
            Navigator.pop(context, value);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class GoalCard extends StatefulWidget {
  final Map<String, dynamic> goal;
  final Function(String message, bool isError)? onDelete;
  final VoidCallback? onRefresh;
  const GoalCard({
    super.key,
    required this.goal,
    this.onDelete,
    this.onRefresh,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  bool isExpanded = false;
  int? adminId;
  bool isLoading = true;
  bool isSearching = false;
  late final isDark = Theme.of(context).brightness == Brightness.dark;
  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    loadAdminId();
  }

  Future<void> loadAdminId() async {
    try {
      final id = await getAdminIdFromToken();

      if (!mounted) return;

      setState(() {
        adminId = id;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<int> getAdminIdFromToken() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final decodedToken = JwtDecoder.decode(token);

    return int.parse(decodedToken['UserId'].toString());
  }

  Color getProgressColor(int progress) {
    if (progress <= 30) {
      return Theme.of(context).colorScheme.error;
    } else if (progress <= 70) {
      return Colors.orange;
    } else {
      return isDark
          ? Theme.of(context).colorScheme.onSecondary
          : Theme.of(context).colorScheme.secondary;
    }
  }

  int getStarCount(int points) {
    if (points >= 81) return 5;
    if (points >= 61) return 4;
    if (points >= 41) return 3;
    if (points >= 21) return 2;
    if (points > 0) return 1;
    return 0;
  }

  void _notifyGoalRefresh() {
    try {
      context.read<DataRefreshNotifier>().refreshGoals();
    } catch (_) {}
  }

  String _ownerId(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text.contains('-') ? text.split('-').first.trim() : text;
  }

  Future<bool> _isGoalCreator() async {
    final token = await AuthService.getToken();
    final loginUserId = token == null ? null : JwtHelper.getuid(token);
    if (loginUserId == null || loginUserId.trim().isEmpty) return false;
    final owner = _ownerId(
      widget.goal["createdBy"] ??
          widget.goal["CreatedBy"] ??
          widget.goal["createdById"] ??
          widget.goal["CreatedById"] ??
          widget.goal["assignBy"] ??
          widget.goal["createdByName"],
    );
    return owner.isNotEmpty && owner == loginUserId.trim();
  }

  Future<void> _showGoalDialog() async {
    if (!await _isGoalCreator()) {
      if (!mounted) return;
      showAppMessage(
        context,
        "Only the person who created this goal can edit or delete it",
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          widget.goal["title"] ?? "",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        content: const Text("What do you want to do with this goal?"),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditGoalPage(goal: widget.goal),
                    ),
                  );
                  if (!mounted) return;
                  if (result != null && result != false) {
                    if (result is Map) {
                      setState(() {
                        widget.goal["title"] =
                            result["title"] ?? widget.goal["title"];
                        widget.goal["dueDate"] =
                            result["dueDate"] ?? widget.goal["dueDate"];
                        widget.goal["priority"] =
                            result["priority"] ?? widget.goal["priority"];
                        if (result.containsKey("targetQuantity")) {
                          widget.goal["targetQuantity"] =
                              result["targetQuantity"];
                        }
                        if (result["assignedUsers"] is List) {
                          widget.goal["assignedUsers"] =
                              result["assignedUsers"];
                        }
                      });
                    }
                    _notifyGoalRefresh();
                    widget.onRefresh?.call();
                  }
                },

                label: Text(
                  "Edit",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              if ((widget.goal["status"] ?? "").toString().toLowerCase() !=
                  "completed")
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);

                    final confirmed = await showDeleteConfirmDialog(context);
                    if (confirmed != true) return;
                    if (!mounted) return;

                    widget.onDelete?.call(
                      "Goal deleted successfully",
                      false,
                    );

                    final goalCode =
                        (widget.goal["goalCode"] ??
                                widget.goal["GoalCode"] ??
                                "")
                            .toString()
                            .trim();

                    final success = await SuperAdminService.deleteGoal(
                      goalCode,
                    );

                    if (!success && mounted) {
                      widget.onDelete?.call(
                        "Failed to delete goal",
                        true,
                      );
                      return;
                    }

                    _notifyGoalRefresh();
                    widget.onRefresh?.call();
                  },

                  label: Text(
                    "Delete",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressRaw = widget.goal["progress"] ?? 0;
    final progress = progressRaw is num
        ? progressRaw.round()
        : int.tryParse("$progressRaw") ?? 0;

    final statusEnum = TaskUtils.parseStatus(
      widget.goal["status"]?.toString().trim() ?? "",
    );

    final statusColor = TaskUtils.getStatusColor(statusEnum);

    final priorityColor = TaskUtils.getPriorityColor(
      widget.goal["priority"]?.toString() ?? "",
    );
    final goalPointsRaw = widget.goal["goalpoints"] ?? 0;
    final goalPoints = goalPointsRaw is num
        ? goalPointsRaw.round()
        : int.tryParse("$goalPointsRaw") ?? 0;
    final goalType = (widget.goal["goalType"] ?? "").toString();
    final createdBy = (widget.goal["createdByName"] ??
            widget.goal["assignBy"] ??
            "")
        .toString();
    final tasks = widget.goal["tasks"] is List ? widget.goal["tasks"] : [];
    final monthlyGoals = _monthlyGoalsOf(widget.goal);
    final isYearly =
        goalType.toLowerCase() == 'yearly' || monthlyGoals.isNotEmpty;
    final assignedTo = isYearly
        ? _yearlyAssignedTo(widget.goal, monthlyGoals)
        : _assignedToNames(widget.goal);
    final quantity = goalQuantityView(
      widget.goal,
      months: isYearly ? monthlyGoals : null,
      tasks: isYearly ? null : tasks,
      preferMonthTotals: isYearly,
    );
    final shownProgress = quantity != null ? quantity.percent : progress;

    return GestureDetector(
      onLongPress: _showGoalDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                if (isYearly) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => YearlyMonthlyGoalsPage(
                        yearlyGoal: widget.goal,
                        monthlyGoals: monthlyGoals,
                        onDelete: widget.onDelete,
                        onRefresh: widget.onRefresh,
                      ),
                    ),
                  );
                  widget.onRefresh?.call();
                  return;
                }
                setState(() => isExpanded = !isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.goal["title"] ?? "",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isYearly
                                    ? Icons.chevron_right
                                    : isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (goalPoints != 0)
                            Row(
                              children: [
                                buildStars(goalPoints),
                                const SizedBox(width: 8),
                                Text(
                                  "$goalPoints points",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                "Progress",
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    minHeight: 8,
                                    value: shownProgress / 100,
                                    backgroundColor: Colors.grey.shade300,
                                    color: getProgressColor(shownProgress),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "$shownProgress%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: getProgressColor(shownProgress),
                                ),
                              ),
                            ],
                          ),
                          if (quantity != null) ...[
                            const SizedBox(height: 12),
                            _quantityStrip(quantity),
                          ],
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (goalType.isNotEmpty) ...[
                                    _badge(
                                      goalType,
                                      Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _badge(
                                    widget.goal["status"] ?? "",
                                    statusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  _badge(
                                    widget.goal["priority"] ?? "",
                                    priorityColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "By : ${AppHelpers.extractName(createdBy)}",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.person_outline, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "To: $assignedTo",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                      maxLines: isYearly ? 3 : 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Start: ${AppHelpers.formatDate(widget.goal["startDate"]?.toString())}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.event,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Due: ${AppHelpers.formatDate(widget.goal["dueDate"]?.toString())}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (isYearly) ...[
                                const SizedBox(height: 10),
                                Text(
                                  monthlyGoals.isEmpty
                                      ? "Tap to open monthly goals"
                                      : "${monthlyGoals.length} monthly goals  •  tap to open",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded && !isYearly)
              Alltasklist(
                tasks: tasks,
                searchQuery: searchController.text,
                onStatusSaved: (task) => _onGoalTaskStatusSaved(tasks),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quantityStrip(GoalQuantityView quantity) {
    final percentColor = quantity.percent >= 100
        ? const Color(0xFF1B7A3A)
        : const Color(0xFFB45309);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _qtyFigure("Target", quantity.target)),
            Expanded(child: _qtyFigure("Achieved", quantity.done)),
            Expanded(child: _qtyFigure("Pending", quantity.pending)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: quantity.fraction,
            backgroundColor: Colors.grey.shade300,
            color: percentColor,
          ),
        ),
      ],
    );
  }

  Widget _qtyFigure(String label, int value, {Color? valueColor}) {
    return _qtyText(label, formatGoalQty(value), valueColor: valueColor);
  }

  Widget _qtyText(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _onGoalTaskStatusSaved(List tasks) async {
    if (!mounted) return;
    final allDone = tasks.isNotEmpty &&
        tasks.every((item) {
          if (item is! Map) return false;
          return TaskUtils.parseStatus((item["status"] ?? "").toString()) ==
              TaskStatus.completed;
        });
    final achieved = tasksAchievedTotal(tasks);
    setState(() {
      widget.goal["completedQuantity"] = achieved;
      if (allDone) widget.goal["status"] = "Completed";
    });
    _notifyGoalRefresh();
    widget.onRefresh?.call();
  }

  List<Map<String, dynamic>> _monthlyGoalsOf(Map<String, dynamic> goal) {
    final raw = goal["monthlyGoals"] ?? goal["MonthlyGoals"];
    if (raw is! List) return [];
    return raw.map((item) {
      Map<String, dynamic> month;
      if (item is Map<String, dynamic>) {
        month = Map<String, dynamic>.from(item);
      } else if (item is Map) {
        month = Map<String, dynamic>.from(item);
      } else {
        return <String, dynamic>{};
      }
      month["goalType"] = "Monthly";
      month["monthlyGoals"] = <Map<String, dynamic>>[];
      if (month["tasks"] is! List) month["tasks"] = [];
      return month;
    }).where((item) => item.isNotEmpty).toList();
  }

  String _assignedToNames(Map<String, dynamic> goal) {
    final names = _memberNamesOf(goal);
    if (names.isNotEmpty) return names.join(", ");
    return AppHelpers.extractName(goal["assignTo"]?.toString() ?? "");
  }

  String _yearlyAssignedTo(
    Map<String, dynamic> yearly,
    List<Map<String, dynamic>> months,
  ) {
    final names = <String>[];
    final seen = <String>{};

    void addAll(Iterable<String> values) {
      for (final name in values) {
        final key = name.toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        names.add(name);
      }
    }

    addAll(_memberNamesOf(yearly));
    for (final month in months) {
      addAll(_memberNamesOf(month));
    }

    if (names.isEmpty) return "0 members";
    return "${names.length} members (${names.join(", ")})";
  }

  List<String> _memberNamesOf(Map<String, dynamic> goal) {
    final names = <String>[];
    final seen = <String>{};

    void addName(String raw, [String? id]) {
      final name = AppHelpers.extractName(raw).trim();
      if (name.isEmpty || name.toLowerCase() == "n/a") return;
      final key = (id ?? name).toLowerCase();
      if (!seen.add(key)) return;
      names.add(name);
    }

    final users = goal["assignedUsers"] ?? goal["AssignedUsers"];
    if (users is List) {
      for (final user in users) {
        if (user is Map) {
          final named = memberDisplayName(Map<String, dynamic>.from(user));
          if (named != null) {
            addName(
              named,
              (user["userId"] ?? user["UserId"] ?? user["id"] ?? "").toString(),
            );
          }
        } else {
          final text = user.toString().trim();
          if (text.contains('-')) addName(text);
        }
      }
    }

    addName(goal["assignTo"]?.toString() ?? "");

    final tasks = goal["tasks"];
    if (tasks is List) {
      for (final task in tasks) {
        if (task is! Map) continue;
        final assigned = task["assignedTo"] ?? task["AssignedTo"];
        if (assigned is List) {
          for (final user in assigned) {
            if (user is Map) {
              final named = memberDisplayName(Map<String, dynamic>.from(user));
              if (named != null) {
                addName(
                  named,
                  (user["userId"] ?? user["UserId"] ?? user["id"] ?? "")
                      .toString(),
                );
              }
            } else {
              final text = user.toString().trim();
              if (text.contains('-')) addName(text);
            }
          }
        }
      }
    }

    return names;
  }

  Widget _badge(String text, Color color) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildStars(int points) {
    int starCount = getStarCount(points);

    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 18,
          color: index < starCount ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }
}

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const StatusChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
