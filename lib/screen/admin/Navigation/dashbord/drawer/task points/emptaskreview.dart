import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
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
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text('Completed Task Points'),
      ),
      body: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(15), child: _buildTaskList()),

          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 0 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
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
        final pendingTasks = tasks
            .where((t) => t['finalPoints'] == null)
            .toList();

        final submittedTasks = tasks
            .where((t) => t['finalPoints'] != null)
            .toList();

        return ListView(
          children: [
            if (pendingTasks.isNotEmpty) ...[
              _buildSectionTitle("Pending Reviews"),
              ...pendingTasks
                  .asMap()
                  .entries
                  .map((entry) => _buildTaskCard(entry.value, entry.key))
                  .toList(),
            ],

            if (submittedTasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle("Submitted Reviews"),
              ...submittedTasks
                  .asMap()
                  .entries
                  .map((entry) => _buildTaskCard(entry.value, entry.key + 1000))
                  .toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.displaySmall);
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final statusEnum = TaskUtils.parseStatus(task['status']);

    return Column(
      children: [
        const SizedBox(height: 15),

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
                    systemPoints: task['systemPoints'] ?? 0,
                    finalPoints: task['finalPoints'],
                    isReviewed: task['finalPoints'] != null,
                    delayJustified: task['isDelayJustified'] ?? false,
                    delayReason: task['delayReason'],
                    comment: task['comment'],
                    onShowMessage: (msg, {isError = true}) {
                      showTopMessage(msg, isError: isError);
                    },
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
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
                        task['task'] ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppHelpers.extractName(task['assignedTo'] ?? ""),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Completed: ${AppHelpers.formatDate(task['completedDate'])}",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 6),

                          Text(
                            "Due: ${AppHelpers.formatDate(task['dueDate'])}",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.group, size: 14),
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

                task['finalPoints'] != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.pending_actions, color: Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
