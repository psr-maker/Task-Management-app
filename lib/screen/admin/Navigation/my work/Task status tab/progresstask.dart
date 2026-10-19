import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

class InProcessTab extends StatefulWidget {
  final int adminId;
  final String Function(Map task)? statusOf;
  final Future<void> Function(Map<String, dynamic> task)? onStatusSaved;
  const InProcessTab({
    super.key,
    required this.adminId,
    this.statusOf,
    this.onStatusSaved,
  });

  @override
  State<InProcessTab> createState() => _InProcessTabState();
}

class _InProcessTabState extends State<InProcessTab> {
  late Future<List<Map<String, dynamic>>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = AdminService.getAdminTasks(widget.adminId);
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }

        if (snapshot.hasError) {
          return const AppLoadError();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No Tasks Found"));
        }

        final tasks = snapshot.data!.where((task) {
          final normalizedStatus = widget.statusOf?.call(task) ??
              AppHelpers.normalize(
                viewerTaskStatus(task, widget.adminId),
              );
          return normalizedStatus == "inprogress";
        }).toList();

        if (tasks.isEmpty) {
          return const Center(child: Text("No In Progress Tasks"));
        }

        return Padding(
          padding: const EdgeInsets.all(15),
          child: AdaptiveGoalCards(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Taskstatus(
                task: task,
                onStatusSaved: widget.onStatusSaved,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetails(taskCode: task["taskCode"]),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
