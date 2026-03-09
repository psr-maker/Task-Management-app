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

  List<AuditLogGroupModel> groupLogs(
    List<AuditLogModel> logs,
    Map<String, UserModel> users,
  ) {
    final Map<String, List<AuditLogModel>> grouped = {};
    for (var log in logs) {
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

  String getTaskName(AuditLogGroupModel log) {
    if (log.taskName != null && log.taskName!.trim().isNotEmpty) {
      return log.taskName!;
    }

    for (final c in log.changes) {
      final field = c.fieldChanged?.toLowerCase() ?? "";
      if (field.contains("task") || field.contains("name")) {
        if (c.newValue != null && c.newValue!.trim().isNotEmpty)
          return c.newValue!;
        if (c.oldValue != null && c.oldValue!.trim().isNotEmpty)
          return c.oldValue!;
      }
    }

    if (log.action.toLowerCase() == "delete") return "Unknown Task";

    return "";
  }

  String getUserName(AuditLogGroupModel log) {
    for (final c in log.changes) {
      final field = c.fieldChanged!.toLowerCase();

      if ((field.contains("name") || field.contains("username")) &&
          c.oldValue != null &&
          c.oldValue!.trim().isNotEmpty) {
        return c.oldValue!;
      }
    }

    for (final c in log.changes) {
      if (c.oldValue != null && c.oldValue!.trim().isNotEmpty) {
        return c.oldValue!;
      }
    }

    return "";
  }

  UserModel? getAffectedUser(
    AuditLogGroupModel log,
    Map<String, UserModel> users,
  ) {
    if (log.entityType != "User") return null;

    return users[log.entityId];
  }

  void navigateToUserDetails(BuildContext context, UserModel user) {
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

  Widget buildTitle(AuditLogGroupModel log) {
    final color = actionColor(log.action);

    // 🔐 LOGIN
    if (log.action.toLowerCase() == "login") {
      return Text(
        "User logged in",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
    }

    // 🚪 LOGOUT
    if (log.action.toLowerCase() == "logout") {
      return Text(
        "User logged out",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
    }

    // 👤 USER
    if (log.entityType == "User") {
      final userName = getUserName(log);

      if (log.action.toLowerCase() == "delete") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Colors.black87),
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

    // 📋 TASK
    if (log.entityType == "Task") {
      final taskName = getTaskName(log);

      if (log.action.toLowerCase() == "delete") {
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            children: [
              const TextSpan(text: "Task "),
              TextSpan(
                text: taskName,
                style: TextStyle(color: color),
              ),
              const TextSpan(text: " deleted permanently"),
            ],
          ),
        );
      }

      return Text(
        "Task : $taskName",
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );
    }

    return Text(
      "${log.entityType} : ${log.entityId}",
      style: const TextStyle(fontSize: 13),
    );
  }

  String? getTaskCodeForNavigation(AuditLogGroupModel log) {
    if (log.entityType != "Task") return null;

    if (log.action.toLowerCase() == "delete") return null;

    if (log.taskCode != null && log.taskCode!.trim().isNotEmpty) {
      return log.taskCode!;
    }

    return log.entityId;
  }

  void navigateToTaskDetails(BuildContext context, String taskCode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetails(taskCode: taskCode)),
    );
  }

  DateTimeRange? selectedRange;

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
          // if (selectedRange != null)
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

          final users = {for (var u in userList) u.userId.toString(): u};

          List<AuditLogModel> filteredLogs = logs;

          if (selectedRange != null) {
            filteredLogs = logs.where((log) {
              final logDate = log.changeDateTime.toLocal();

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

              return logDate.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  logDate.isBefore(end.add(const Duration(seconds: 1)));
            }).toList();
          }
          final groupedLogs = filteredLogs.isNotEmpty
              ? groupLogs(filteredLogs, users)
              : [];
          filteredLogs.sort(
            (a, b) => b.changeDateTime.compareTo(a.changeDateTime),
          );
          if (groupedLogs.isEmpty) {
            return const Center(child: Text("No audit logs found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groupedLogs.length,
            itemBuilder: (context, index) {
              final log = groupedLogs[index];
              final color = actionColor(log.action);
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
                          child: Icon(
                            actionIcon(log.action),
                            color: color,
                            size: 18,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 120,
                          color: color.withOpacity(0.25),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: isHighlighted
                              ? Border.all(
                                  color: actionColor(log.action),
                                  width: 2,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            if (log.entityType == "User" &&
                                log.action.toLowerCase() != "delete") {
                              final affectedUser = getAffectedUser(log, users);
                              if (affectedUser != null) {
                                navigateToUserDetails(context, affectedUser);
                              }
                              return;
                            }

                            if (log.entityType == "Task" &&
                                log.action.toLowerCase() != "delete") {
                              final taskCode = getTaskCodeForNavigation(log);
                              if (taskCode != null) {
                                navigateToTaskDetails(context, taskCode);
                              }
                            }
                          },

                          child: AuditCard(
                            color: actionColor(log.action),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // USER INFO HEADER
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: actionColor(
                                          log.action,
                                        ).withOpacity(0.1),
                                        child: Text(
                                          log.editedByName[0].toUpperCase(),
                                          style: TextStyle(
                                            color: actionColor(log.action),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "${log.editedByName} (${log.editedRole} · ${log.department})",
                                          style: TextStyle(
                                            color: actionColor(log.action),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // ACTION TITLE
                                  // Text(
                                  buildTitle(log),

                                  //   style:  TextStyle(
                                  //     fontSize: 13,
                                  //     fontWeight: FontWeight.w600,
                                  //      color: actionColor( log.action),
                                  //   ),
                                  // ),
                                  const SizedBox(height: 10),

                                  if (log.action.toLowerCase() != "delete") ...[
                                    const Divider(height: 20),

                                    const Text(
                                      "Changes",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: const Color.fromARGB(
                                          255,
                                          25,
                                          77,
                                          38,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    ...log.changes.map(
                                      (c) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: actionColor(
                                            log.action,
                                          ).withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "${c.fieldChanged}: ${c.oldValue} → ${c.newValue}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      log.dateTime
                                          .toLocal()
                                          .toString()
                                          .split(".")
                                          .first,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
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
            },
          );
        },
      ),
    );
  }
}
