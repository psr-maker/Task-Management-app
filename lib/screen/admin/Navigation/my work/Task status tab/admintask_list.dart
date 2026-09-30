import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/adaptive_goal_cards.dart';

class Alltasklist extends StatelessWidget {
  final List tasks;
  final String searchQuery;
  final Future<void> Function(Map<String, dynamic> task)? onStatusSaved;

  const Alltasklist({
    super.key,
    required this.tasks,
    required this.searchQuery,
    this.onStatusSaved,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();

    final filteredTasks = tasks.where((task) {
      if (query.isEmpty) return true;

      final taskName = (task['task'] ?? '').toString().toLowerCase();
      final status = (task['status'] ?? '').toString().toLowerCase();
      final priority = (task['priority'] ?? '').toString().toLowerCase();

      return taskName.contains(query) ||
          status.contains(query) ||
          priority.contains(query);
    }).toList();

    if (filteredTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(15),
        child: Text("No tasks found"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(15),
      child: AdaptiveGoalCards(
        shrinkWrap: true,
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return Taskstatus(
            task: task,
            onStatusSaved: onStatusSaved,
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
  }
}