import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class OverdueTaskList extends StatelessWidget {
  final List<Map<String, dynamic>> overdueTasks;
  final Map<String, dynamic>? data;

  const OverdueTaskList({super.key, required this.overdueTasks, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (overdueTasks.isEmpty) {
      return const Center(
        child: Text(
          "No overdue tasks",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Column(
      children: [
        if (data != null) _buildCriticalAlert(data!),
    
        ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: overdueTasks.length,
          itemBuilder: (context, index) {
            final task = overdueTasks[index];
            // final assignedList = task["assignedTo"] as List?;
            final assignedList = (task["assignedTo"] ?? task["members"] ?? []) as List;

            final statusEnum = TaskUtils.parseStatus(task["status"] ?? "");
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TaskDetails(taskCode: task["taskCode"]),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
                      ? (theme.cardTheme.shape as RoundedRectangleBorder)
                            .borderRadius
                      : BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: TaskUtils.getStatusColor(statusEnum),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task["task"] ?? "Unnamed Task",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 6),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: assignedList.map<Widget>((member) {
                              return Text(
                                "${member["role"] ?? "N/A"} • ${AppHelpers.extractName(member["userId"] ?? "")}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Due: ${AppHelpers.formatDate(task["dueDate"])}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.group,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                              "${task["totalMembers"] ?? assignedList.length}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getDaysLeftText(task["dueDate"]),
                            style: TextStyle(
                              color: _getDaysLeftColor(task["dueDate"]),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChip(
                          icon: Icons.flag,
                          text:  task["priority"] ?? "N/A",
                        color: TaskUtils.getPriorityColor(task["priority"] ?? ""),
                        ),
                        const SizedBox(height: 8),
                        _buildChip(
                          icon: Icons.timelapse,
                          text: TaskUtils.getStatusText(statusEnum),
                          color: TaskUtils.getStatusColor(statusEnum),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getDaysLeftText(dynamic dueDate) {
    if (dueDate == null) return "";

    DateTime due;
    try {
      due = DateTime.parse(dueDate.toString());
    } catch (_) {
      return "";
    }

    final now = DateTime.now();
    final difference = due.difference(now).inDays;

    if (difference > 0)
      return "$difference day${difference > 1 ? 's' : ''} left";
    if (difference == 0) return "Due today!";
    return "Overdue by ${difference.abs()} day${difference.abs() > 1 ? 's' : ''}";
  }

  Color _getDaysLeftColor(dynamic dueDate) {
    if (dueDate == null) return Colors.grey.shade400;

    DateTime due;
    try {
      due = DateTime.parse(dueDate.toString());
    } catch (_) {
      return Colors.grey.shade400;
    }

    final now = DateTime.now();
    final difference = due.difference(now).inDays;

    if (difference > 0) return Colors.greenAccent.shade400;
    if (difference == 0) return Colors.orangeAccent.shade200;
    return Colors.redAccent.shade200;
  }

  Widget _buildCriticalAlert(Map<String, dynamic> data) {
    final critical = data["overdueTasks"] ?? 0;

    if (critical == 0) return const SizedBox();

    return Row(
      children: [
        const Icon(Icons.warning, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$critical critical overdue tasks need attention!",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
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
