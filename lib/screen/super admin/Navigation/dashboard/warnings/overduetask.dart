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

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: overdueTasks.length,
          itemBuilder: (context, index) {
            final task = overdueTasks[index];

            final assignedRaw = task["members"];

            List assignedList = [];

            if (assignedRaw is List) {
              assignedList = assignedRaw;
            }

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
                            task["task"],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineLarge,
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
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.group,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${task["totalMembers"] ?? (assignedList.length)}",
                                style: Theme.of(context).textTheme.labelMedium,
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
                          text: task["priority"] ?? "N/A",
                          color: TaskUtils.getPriorityColor(
                            task["priority"] ?? "",
                          ),
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

class OverdueGoalList extends StatelessWidget {
  final List<Map<String, dynamic>> overdueGoals;
  final Map<String, dynamic>? data;

  const OverdueGoalList({super.key, required this.overdueGoals, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: overdueGoals.length,
          itemBuilder: (context, index) {
            final goal = overdueGoals[index];

            final statusEnum = TaskUtils.parseStatus(goal["status"] ?? "");

            return Container(
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
                  // LEFT STATUS BAR
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: TaskUtils.getStatusColor(statusEnum),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // MAIN CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GOAL NAME
                        Text(
                          goal["goal"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),

                        const SizedBox(height: 6),

                        // DUE DATE
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Due: ${AppHelpers.formatDate(goal["dueDate"])}",
                               style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // DAYS LEFT
                        Text(
                          _getDaysLeftText(goal["dueDate"]),
                          style: TextStyle(
                            color: _getDaysLeftColor(goal["dueDate"]),
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
                        text: goal["priority"] ?? "",
                        color: TaskUtils.getPriorityColor(
                          goal["priority"] ?? "",
                        ),
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
