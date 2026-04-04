import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/auditlog.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Admin/admin_detail.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Employee/empdetails.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/auditcard.dart';

class AuditLogPage extends StatefulWidget {
  final String? highlightid;
  const AuditLogPage({super.key, this.highlightid});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  DateTimeRange? selectedRange;

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
        return Colors.grey;
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

  List<AuditLogModel> _applyDateFilter(List<AuditLogModel> logs) {
    if (selectedRange == null) return logs;
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
    return logs.where((log) {
      final logDate = log.changeDateTime.toLocal();
      return !logDate.isBefore(start) && !logDate.isAfter(end);
    }).toList();
  }

  List<AuditLogGroupModel> _groupLogs(
    List<AuditLogModel> logs,
    Map<String, UserModel> users,
  ) {
    final Map<String, List<AuditLogModel>> grouped = {};
    for (final log in logs) {
      final key =
          "${log.entityType}_${log.entityId}_${log.changeDateTime.toString().substring(0, 16)}";
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped.values.map((group) {
      final first = group.first;
      final user = users[first.editedById];

      return AuditLogGroupModel(
        entityType: first.entityType,
        entityId: first.entityId,
        action: first.action,
        editedByName: user?.name ?? first.editedByName,
        editedRole: user?.role ?? first.editedRole,
        department: user?.department ?? "Unknown",
        taskCode: first.taskCode,
        taskName: first.taskName,
        dateTime: first.changeDateTime,
        changes: group,
      );
    }).toList();
  }

  String _getGoalName(AuditLogGroupModel log) {
    if (log.action.toLowerCase() == "delete" && log.changes.isNotEmpty) {
      final first = log.changes.first;
      if (first.oldValue != null && first.oldValue!.trim().isNotEmpty) {
        return first.oldValue!;
      }
    }
    for (final change in log.changes) {
      final field = (change.fieldChanged ?? "").toLowerCase();
      if (field.contains("goal") || field.contains("title")) {
        if (change.newValue != null && change.newValue!.trim().isNotEmpty) {
          return change.newValue!;
        }
        if (change.oldValue != null && change.oldValue!.trim().isNotEmpty) {
          return change.oldValue!;
        }
      }
    }
    return log.entityId.isNotEmpty ? log.entityId : "Unknown Goal";
  }

  String _getTaskName(AuditLogGroupModel log) {
    if (log.action.toLowerCase() == "delete" && log.changes.isNotEmpty) {
      final first = log.changes.first;
      if (first.oldValue != null && first.oldValue!.trim().isNotEmpty) {
        return first.oldValue!;
      }
    }
    if (log.taskName != null && log.taskName!.trim().isNotEmpty) {
      return log.taskName!;
    }
    for (final change in log.changes) {
      final field = (change.fieldChanged ?? "").toLowerCase();
      if (field.contains("task") || field.contains("name")) {
        if (change.newValue != null && change.newValue!.trim().isNotEmpty) {
          return change.newValue!;
        }
        if (change.oldValue != null && change.oldValue!.trim().isNotEmpty) {
          return change.oldValue!;
        }
      }
    }
    return log.entityId.isNotEmpty ? log.entityId : "Unknown Task";
  }

  String _getUserName(AuditLogGroupModel log) {
    for (final change in log.changes) {
      final field = (change.fieldChanged ?? "").toLowerCase();
      if ((field.contains("name") || field.contains("username")) &&
          change.oldValue != null &&
          change.oldValue!.trim().isNotEmpty) {
        return change.oldValue!;
      }
    }
    for (final change in log.changes) {
      if (change.oldValue != null && change.oldValue!.trim().isNotEmpty) {
        return change.oldValue!;
      }
    }
    return "Unknown User";
  }

  UserModel? _getAffectedUser(
    AuditLogGroupModel log,
    Map<String, UserModel> users,
  ) {
    if (log.entityType != "User") return null;
    return users[log.entityId];
  }

  void _navigateToUserDetails(BuildContext context, UserModel user) {
    if (user.role.toLowerCase() == "director") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Admindetails(adminId: user.userId)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EmployeeDetail(employee: user)),
      );
    }
  }

  void _navigateToTaskDetails(BuildContext context, String taskCode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetails(taskCode: taskCode)),
    );
  }

  String? _getTaskCodeForNavigation(AuditLogGroupModel log) {
    if (log.entityType != "Task" || log.action.toLowerCase() == "delete") {
      return null;
    }
    if (log.taskCode != null && log.taskCode!.trim().isNotEmpty) {
      return log.taskCode!;
    }
    return log.entityId;
  }

  Widget _buildTitle(AuditLogGroupModel log) {
    final action = log.action.toLowerCase();
    final color = actionColor(log.action);
    if (action == "login") {
      return Text(
        "User logged in",
        style: const TextStyle(fontSize: 12, color: Colors.black),
      );
    }
    if (action == "logout") {
      return Text(
        "User logged out",
        style: Theme.of(context).textTheme.labelMedium,
      );
    }
    if (log.entityType == "User") {
      final userName = _getUserName(log);
      if (action == "delete") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.black),
            children: [
              const TextSpan(text: "User "),
              TextSpan(
                text: userName,
                style: TextStyle(color: color),
              ),
              const TextSpan(text: " deleted permanently"),
            ],
          ),
        );
      }
      return Text(
        "User : $userName",
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );
    }
    if (log.entityType == "Task") {
      final taskName = _getTaskName(log);
      if (action == "delete") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.black),
            children: [
              const TextSpan(text: "Task '"),
              TextSpan(
                text: taskName,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: " was permanently deleted"),
            ],
          ),
        );
      }
      if (action == "edit") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.black),
            children: [
              const TextSpan(text: "Task '"),
              TextSpan(
                text: taskName,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: "' updated"),
            ],
          ),
        );
      }
      return Text(
        "Task : $taskName",
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );
    }
    if (log.entityType == "Goal") {
      final goalName = _getGoalName(log);
      if (action == "delete") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.black),
            children: [
              const TextSpan(text: "Goal '"),
              TextSpan(
                text: goalName,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: " was permanently deleted"),
            ],
          ),
        );
      }
      if (action == "edit") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Colors.black),
            children: [
              const TextSpan(text: "Goal '"),
              TextSpan(
                text: goalName,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: "' updated"),
            ],
          ),
        );
      }
      return Text(
        "Goal : $goalName",
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );
    }
    return Text(
      "${log.entityType} : ${log.entityId}",
      style: const TextStyle(fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                setState(() {
                  selectedRange = pickedRange;
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Object>>(
        future: Future.wait([
          SuperAdminService.getAuditLogs(),
          SuperAdminService.getAllUsers(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final logs = snapshot.data![0] as List<AuditLogModel>;
          final userList = snapshot.data![1] as List<UserModel>;
          final users = {
            for (var user in userList) user.userId.toString(): user,
          };
          final filteredLogs = _applyDateFilter(logs);
          final groupedLogs = _groupLogs(filteredLogs, users);
          if (groupedLogs.isEmpty) {
            return const Center(
              child: Text(
                "No audit logs found",
                style: TextStyle(fontSize: 14),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groupedLogs.length,
            itemBuilder: (context, index) {
              return _buildAuditItem(groupedLogs[index], users);
            },
          );
        },
      ),
    );
  }

  Widget _buildAuditItem(AuditLogGroupModel log, Map<String, UserModel> users) {
    final color = actionColor(log.action);
    final displayName = log.editedByName.isNotEmpty
        ? log.editedByName
        : "System";
    final isHighlighted =
        widget.highlightid != null &&
        (log.taskCode == widget.highlightid ||
            log.entityId == widget.highlightid);
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
            child: Container(
              decoration: BoxDecoration(
                border: isHighlighted
                    ? Border.all(color: color, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (log.entityType == "User" &&
                      log.action.toLowerCase() != "delete") {
                    final affectedUser = _getAffectedUser(log, users);
                    if (affectedUser != null) {
                      _navigateToUserDetails(context, affectedUser);
                    }
                    return;
                  }
                  if (log.entityType == "Task" &&
                      log.action.toLowerCase() != "delete") {
                    final taskCode = _getTaskCodeForNavigation(log);
                    if (taskCode != null) {
                      _navigateToTaskDetails(context, taskCode);
                    }
                  }
                },
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
                                displayName[0].toUpperCase(),
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
                        _buildTitle(log),
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
            ),
          ),
        ],
      ),
    );
  }
}
