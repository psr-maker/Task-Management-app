import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class Admintask extends StatefulWidget {
  final int adminId;
  final String searchQuery;
  final TaskFilterModel filter;

  const Admintask({
    super.key,
    required this.adminId,
    required this.searchQuery,
    required this.filter,
  });

  @override
  State<Admintask> createState() => _AdmintaskState();
}

class _AdmintaskState extends State<Admintask> {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final tasks = await AdminService.getAdminTasks(widget.adminId);

    setState(() {
      allTasks = tasks;
      filteredTasks = tasks;
      isLoading = false;
    });
  }

  void applySearchAndFilter() {
    final query = widget.searchQuery.trim().toLowerCase();

    setState(() {
      filteredTasks = allTasks.where((task) {
        // 🔍 SEARCH
        final matchesSearch =
            query.isEmpty ||
            (task["task"] ?? "").toString().toLowerCase().contains(query) ||
            (task["employeeName"] ?? "").toString().toLowerCase().contains(
              query,
            ) ||
            (task["department"] ?? "").toString().toLowerCase().contains(query);

        // 📌 STATUS
        final matchesStatus =
            widget.filter.status == null ||
            AppHelpers.normalize(task["status"]) ==
                AppHelpers.normalize(widget.filter.status!);

        // 🚦 PRIORITY
        final matchesPriority =
            widget.filter.priority == null ||
            task["priority"].toString().toLowerCase() ==
                widget.filter.priority!.toLowerCase();

        final matchesDepartment =
            widget.filter.department == null ||
            (task["assignedTo"] as List).any(
              (u) =>
                  (u["department"] ?? "").toString().toLowerCase() ==
                  widget.filter.department!.toLowerCase(),
            );

        final matchesUser =
            widget.filter.assignedTo == null ||
            (task["assignedTo"] as List).any(
              (u) =>
                  (u["name"] ?? "").toString().toLowerCase() ==
                  widget.filter.assignedTo!
                      .split('-')
                      .first
                      .trim()
                      .toLowerCase(),
            );

        return matchesSearch &&
            matchesStatus &&
            matchesPriority &&
            matchesDepartment &&
            matchesUser;
      }).toList();
    });
  }

  @override
  void didUpdateWidget(covariant Admintask oldWidget) {
    super.didUpdateWidget(oldWidget);
    applySearchAndFilter();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    if (filteredTasks.isEmpty) {
      return const Center(child: Text("No Tasks Found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];

        final statusEnum = TaskUtils.parseStatus(task["status"]);
        final statusColor = TaskUtils.getStatusColor(statusEnum);
        final priorityColor = TaskUtils.getPriorityColor(task["priority"]);

        return TaskCard(
          task: task,
          statusColor: statusColor,
          priorityColor: priorityColor,
          formatDate: AppHelpers.formatDate,
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
  }
}
