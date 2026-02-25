import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class Alltasklist extends StatefulWidget {
  final int adminId;
  final String searchQuery;

  const Alltasklist({
    super.key,
    required this.adminId,
    required this.searchQuery,
  });

  @override
  State<Alltasklist> createState() => _AlltasklistState();
}

class _AlltasklistState extends State<Alltasklist> {
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

        final tasks = snapshot.data!;
        final query = widget.searchQuery.trim().toLowerCase();

        final filteredTasks = tasks.where((task) {
          if (query.isEmpty) return true;

          final taskName = (task['task'] ?? '').toString().toLowerCase();
          final status = (task['status'] ?? '').toString().toLowerCase();
          final priority = (task['priority'] ?? '').toString().toLowerCase();

          return taskName.contains(query) ||
              status.contains(query) ||
              priority.contains(query);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          //   itemCount: tasks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];

            if (filteredTasks.isEmpty) {
              return const Center(child: Text("No tasks found"));
            }

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
