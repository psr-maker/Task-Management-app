import 'package:flutter/material.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';

class SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SmallStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(70), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(value, style: Theme.of(context).textTheme.labelSmall),

            Text(title, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
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
                      Icon(
                        Icons.group,
                      
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${task["totalMembers"] ?? 0} Members",
                         style: Theme.of(context).textTheme.titleLarge
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Due: ${formatDate(task["dueDate"])}",
                    style: Theme.of(context).textTheme.titleLarge
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

  const Taskstatus({super.key, required this.task, required this.onTap});

  @override
  State<Taskstatus> createState() => _TaskCardState();
}

class _TaskCardState extends State<Taskstatus> {
  late TaskStatus selectedStatus;
  bool isUpdating = false;
  bool get isCompleted => selectedStatus == TaskStatus.completed;

  @override
  void initState() {
    super.initState();
    selectedStatus = TaskUtils.parseStatus(
      widget.task["status"]!.toString().trim(),
    );
  }

  @override
  void didUpdateWidget(covariant Taskstatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.task["status"] != widget.task["status"]) {
      selectedStatus = TaskUtils.parseStatus(
        widget.task["status"]!.toString().trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = TaskUtils.getStatusColor(selectedStatus);
    final priorityColor = TaskUtils.getPriorityColor(widget.task["priority"]);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color.fromARGB(255, 14, 138, 45),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            /// Status bar
            Container(
              width: 4,
              height: 55,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),

            /// Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task["task"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 25, 77, 38),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.task["totalMembers"]} Members",
                        style: const TextStyle(fontSize: 12),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<TaskStatus>(
                    value: selectedStatus,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
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

                    onChanged: (isUpdating || isCompleted)
                        ? null
                        : (value) async {
                            if (value == null) return;

                            setState(() {
                              selectedStatus = value;
                              isUpdating = true;
                            });

                            try {
                              await AdminService.updateTaskStatus(
                                taskCode: widget.task["taskCode"],
                                status: value,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Status update failed"),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => isUpdating = false);
                              }
                            }
                          },
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

class DepartmentCard extends StatelessWidget {
  final String departmentName;
  final int totalTasks;
  final int completed;
  final int pending;
  final int inProgress;
  final int overdue;
  final double completedPercentage;
  final int users;

  const DepartmentCard({
    super.key,
    required this.departmentName,
    required this.totalTasks,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.overdue,
    required this.completedPercentage,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Department Name
            Text(
              departmentName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            /// Total Task & Progress
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text("Total Tasks"),
                    Text(
                      totalTasks.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                /// Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: completedPercentage / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${completedPercentage.toStringAsFixed(1)}%",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusRow("Completed", completed, Colors.green),
                _statusRow("Pending", pending, Colors.orange),
                _statusRow(
                  "Not Started",
                  pending,
                  Colors.grey,
                ), // change if separate field
                _statusRow("Overdue", overdue, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String title, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            "$title - $value",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
