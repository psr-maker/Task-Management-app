import 'package:flutter/material.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class PendingTab extends StatefulWidget {
  final int adminId;
  const PendingTab({super.key, required this.adminId});

  @override
  State<PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<PendingTab> {
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
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No Tasks Found"));
        }

        // Filter only pending and paused tasks
        final tasks = snapshot.data!.where((task) {
          final normalizedStatus = AppHelpers.normalize(task["status"]);
          return normalizedStatus == "pending" ||
              normalizedStatus == "paused" ||
              normalizedStatus == "notstarted";
        }).toList();

        if (tasks.isEmpty) {
          return const Center(child: Text("No Pending/Paused Tasks"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return Taskstatus(
              task: task,
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
        );
      },
    );
  }
}
