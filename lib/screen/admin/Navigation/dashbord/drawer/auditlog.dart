import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/auditlog.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class AuditLogPage extends StatefulWidget {
  final String? highlightid;
  const AuditLogPage({super.key, this.highlightid});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  String? loginUserId;
  String? loginUserRole;
  String? loginUserDept;

  DateTimeRange? selectedRange;
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    loadLoginUserId();
  }

  List<AuditLogModel> applyDateFilter(List<AuditLogModel> logs) {
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
      return logDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          logDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<void> loadLoginUserId() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    setState(() {
      loginUserId = JwtHelper.getuid(token).toString();
      isLoadingUser = false;
    });
  }

  List<AuditLogModel> applyAdminFilter(
    List<AuditLogModel> logs,
    Map<String, UserModel> users,
  ) {
    final loginUser = users[loginUserId];

    if (loginUser == null) return [];

    final role = loginUser.role.toLowerCase();
    final dept = loginUser.department.toLowerCase();

    if (role == "manager") {
      return logs.where((log) {
        final editedUser = users[log.editedById];
        if (editedUser == null) return false;

        return editedUser.role.toLowerCase() == "manager" &&
            editedUser.department.toLowerCase() == dept;
      }).toList();
    }

    return [];
  }

  Color actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'edit':
        return const Color.fromARGB(255, 25, 77, 38);
      case 'delete':
        return Colors.red;
        ;
      case 'logout':
        return Colors.red;
      case 'login':
        return Color.fromARGB(255, 25, 77, 38);
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

  String getTaskName(AuditLogGroupModel log) {
    if (log.action.toLowerCase() == "delete") {
      for (final c in log.changes) {
        final field = c.fieldChanged!.toLowerCase();

        if ((field.contains("taskname") || field == "name") &&
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

    if (log.taskName != null && log.taskName!.trim().isNotEmpty) {
      return log.taskName!;
    }

    for (final c in log.changes) {
      final field = c.fieldChanged!.toLowerCase();

      if (field.contains("taskname") || field == "name") {
        if (c.newValue != null && c.newValue!.trim().isNotEmpty) {
          return c.newValue!;
        }
        if (c.oldValue != null && c.oldValue!.trim().isNotEmpty) {
          return c.oldValue!;
        }
      }
    }

    return "";
  }

  Widget buildTitle(AuditLogGroupModel log) {
    final color = actionColor(log.action);

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

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Audit Log"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final logs = snapshot.data![0] as List<AuditLogModel>;
          final userList = snapshot.data![1] as List<UserModel>;

          final users = {for (var u in userList) u.userId.toString(): u};

          final adminFilteredLogs = applyAdminFilter(logs, users);
          final filteredLogs = applyDateFilter(adminFilteredLogs);

          if (filteredLogs.isEmpty) {
            return const Center(
              child: Text(
                "No audit logs found",
                style: TextStyle(fontSize: 14),
              ),
            );
          }
          final groupedLogs = groupLogs(filteredLogs, users);
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
                    /// 🔹 LEFT TIMELINE SECTION
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

                    /// 🔹 CARD SECTION
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: isHighlighted
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // You can add navigation here if needed
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// 🔹 HEADER (User Info)
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: color.withOpacity(0.1),
                                      child: Text(
                                        log.editedByName.isNotEmpty
                                            ? log.editedByName[0].toUpperCase()
                                            : "?",
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "${log.editedByName} (${log.editedRole})",
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                buildTitle(log),

                                if (log.action.toLowerCase() != "delete" &&
                                    log.changes.isNotEmpty) ...[
                                  const Divider(height: 20),

                                  Text(
                                    "Changes",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),

                                  const SizedBox(height: 6),

                                  ...log.changes.map(
                                    (c) => Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "${c.fieldChanged}: ${c.oldValue} → ${c.newValue}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),

                                /// 🔹 DATE
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    log.dateTime
                                        .toLocal()
                                        .toString()
                                        .split(".")
                                        .first,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ],
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
