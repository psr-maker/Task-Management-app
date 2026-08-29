import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/taskpoint.dart';
import 'package:staff_work_track/services/admin_service.dart';
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
  bool showPending = true;
  bool showSubmitted = true;

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

  Future<void> _refreshTasks() async {
    setState(() {
      expandedIndex = null;
      tasksFuture = AdminService.getCompletedTaskPoints();
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
        title: const Text('Task Performance'),
      ),
      body: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(15), child: _buildTaskList()),

          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 20 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
                backgroundColor: _isErrorMessage
                    ? Colors.red
                    : Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.secondary,
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
            if (pendingTasks.isNotEmpty)
              _buildDropdownSection(
                title: "Pending Reviews...⭐",
                isOpen: showPending,
                onTap: () {
                  setState(() => showPending = !showPending);
                },
                children: pendingTasks
                    .asMap()
                    .entries
                    .map((entry) => _buildTaskCard(entry.value, entry.key))
                    .toList(),
              ),

            const SizedBox(height: 16),

            if (submittedTasks.isNotEmpty)
              _buildDropdownSection(
                title: "Submitted Reviews",
                isOpen: showSubmitted,
                onTap: () {
                  setState(() => showSubmitted = !showSubmitted);
                },
                children: submittedTasks
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildTaskCard(entry.value, entry.key + 1000),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final int? staffId = task['staffId'];

    if (staffId == null) {
      return const SizedBox();
    }

    final bool isReviewed = task['finalPoints'] != null;
    final bool isExpanded = expandedIndex == index;

    return Column(
      children: [
        const SizedBox(height: 15),

        // Expanded review section
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskPointDetail(
                    key: ValueKey("${task['taskCode']}_$staffId"),

                    taskName: task['task'] ?? "",

                    assignedTo: task['staffName'] ?? "",

                    taskId: task['taskCode'].toString(),

                    staffId: staffId,

                    systemPoints: task['systemPoints'] ?? 0,

                    finalPoints: task['finalPoints'],

                    isReviewed: isReviewed,

                    delayJustified: task['isDelayJustified'] ?? false,

                    delayReason: task['delayReason'],

                    comment: task['comment'],

                    onShowMessage: (msg, {isError = true}) {
                      showTopMessage(msg, isError: isError);
                    },

                    onReviewSubmitted: _refreshTasks,
                  ),
                )
              : const SizedBox(),
        ),

        // ⭐ THIS IS THE IMPORTANT PART
        GestureDetector(
          onTap: () {
            setState(() {
              expandedIndex = expandedIndex == index ? null : index;
            });
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                //  color: Theme.of(context).colorScheme.secondary,
                width: 1,
              ),
              //color: Theme.of(context).colorScheme.primary,
            ),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 65,
                  decoration: BoxDecoration(
                    color: isReviewed ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staff name
                      Text(
                        task['staffName'] ?? "Unknown Staff",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 5),

                      // Task
                      Text(
                        task['task'] ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(Icons.people, size: 14),
                          const SizedBox(width: 5),

                          Text(
                            '${task['totalMembers'] ?? 0}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),

                          const SizedBox(width: 12),

                          const Icon(Icons.calendar_today, size: 13),
                          const SizedBox(width: 5),

                          Text(
                            "Due: ${AppHelpers.formatDate(task['dueDate'])}",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Review status
                Column(
                  children: [
                    Icon(
                      isReviewed ? Icons.check_circle : Icons.pending_actions,
                      color: isReviewed ? Colors.green : Colors.orange,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      isReviewed ? "${task['finalPoints']}/100" : "Pending",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isReviewed ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 5),

                // Expand icon
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required bool isOpen,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary,
              // border: Border.all(
              //   color: Theme.of(context).colorScheme.secondary,
              // ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 👇 CONTENT
        AnimatedCrossFade(
          firstChild: const SizedBox(),
          secondChild: Column(children: children),
          crossFadeState: isOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
