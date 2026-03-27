import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/Task%20status%20tab/admintask_list.dart';
import 'package:staff_work_track/services/auth_service.dart';
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
                      Icon(Icons.group),
                      const SizedBox(width: 4),
                      Text(
                        "${task["totalMembers"] ?? 0} Members",
                        style: Theme.of(context).textTheme.titleLarge,
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

class GoalCard extends StatefulWidget {
  final Map<String, dynamic> goal;

  const GoalCard({super.key, required this.goal});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  bool isExpanded = false;
  int? adminId;
  bool isLoading = true;
  bool isSearching = false;
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
      isLoading = false;
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
      return Theme.of(context).colorScheme.secondary;
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

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal["progress"] ?? 0;

    final statusEnum = TaskUtils.parseStatus(
      widget.goal["status"]?.toString().trim() ?? "",
    );

    final statusColor = TaskUtils.getStatusColor(statusEnum);

    final priorityColor = TaskUtils.getPriorityColor(
      widget.goal["priority"]?.toString() ?? "",
    );
    final goalPoints = widget.goal["goalpoints"] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
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
                                style: Theme.of(context).textTheme.displaySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.black,
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
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: progress / 100,
                                  backgroundColor: Colors.grey.shade300,
                                  color: getProgressColor(progress),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$progress%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: getProgressColor(progress),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
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
                                const Icon(Icons.person),
                                const SizedBox(width: 4),
                                Text(
                                  "By : ${AppHelpers.extractName(widget.goal["assignBy"] ?? "")}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                const Icon(Icons.person_outline),
                                const SizedBox(width: 4),
                                Text(
                                  "To: ${AppHelpers.extractName(widget.goal["assignTo"] ?? "")}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Start: ${AppHelpers.formatDate(widget.goal["startDate"])}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
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
                                  "Due: ${AppHelpers.formatDate(widget.goal["dueDate"])}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && adminId != null)
            Alltasklist(
              tasks: widget.goal["tasks"] ?? [],
              searchQuery: searchController.text,
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
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
