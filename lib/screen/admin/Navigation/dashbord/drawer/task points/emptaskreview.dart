import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/taskpoint.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class Taskpoints extends StatefulWidget {
  const Taskpoints({super.key});

  @override
  State<Taskpoints> createState() => _TaskpointsState();
}

class _TaskpointsState extends State<Taskpoints> {
  late Future<List<Map<String, dynamic>>> tasksFuture;
  Map<String, dynamic>? selectedTask;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    tasksFuture = AdminService.getCompletedTaskPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text('Completed Task Points'),
      ),
      body: Padding(padding: const EdgeInsets.all(15), child: _buildTaskList()),
    );
  }

  Widget _buildTaskList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No Completed Task Points Available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final tasks = snapshot.data!;

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final statusEnum = TaskUtils.parseStatus(task['status']);

            return Column(
              children: [
                SizedBox(height: 10),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: expandedIndex == index
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TaskPointDetail(
                            key: ValueKey(task['taskCode']),
                            taskName: task['task'],
                            assignedTo: AppHelpers.extractName(
                              task['assignedTo'] ?? "",
                            ),
                            taskId: task['taskCode'].toString(),
                          ),
                        )
                      : const SizedBox(),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      expandedIndex = expandedIndex == index ? null : index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 1,
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
                                task['task'] ?? "No Task Name",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromARGB(255, 25, 77, 38),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppHelpers.extractName(
                                  task['assignedBy'] ?? "",
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                    "Due: ${AppHelpers.formatDate(task['dueDate'])}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.group,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${task['totalMembers']}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildChip(
                              icon: Icons.flag,
                              text: task['priority'] ?? "N/A",
                              color: TaskUtils.getPriorityColor(
                                task['priority'] ?? "N/A",
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
                ),
              ],
            );
          },
        );
      },
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
