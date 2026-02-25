import 'package:flutter/material.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class AdminAssigntsk extends StatefulWidget {
  final int adminId;
  final String searchQuery;
  final TaskFilterModel filter;

  const AdminAssigntsk({
    super.key,
    required this.adminId,
    required this.searchQuery,
    required this.filter,
  });

  @override
  State<AdminAssigntsk> createState() => _AdminAssignState();
}

class _AdminAssignState extends State<AdminAssigntsk> {
  late Future<List<dynamic>> taskFuture;

  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final tasks = await AdminService.getTasksAssignedByAdmin(widget.adminId);

    setState(() {
      allTasks = List<Map<String, dynamic>>.from(tasks);
      filteredTasks = allTasks;
      isLoading = false;
    });
  }

  void applySearchAndFilter() {
    setState(() {
      filteredTasks = allTasks.where((task) {
        final query = widget.searchQuery.trim().toLowerCase();

        final matchesSearch =
            query.isEmpty ||
            (task["taskName"] ?? task["task"] ?? "")
                .toString()
                .toLowerCase()
                .contains(query) ||
            (task["department"] ?? "").toString().toLowerCase().contains(
              query,
            ) ||
            ((task["assignedTo"] as List?)?.any(
                  (u) => (u["name"] ?? "").toString().toLowerCase().contains(
                    query,
                  ),
                ) ??
                false);

        final matchesStatus =
            widget.filter.status == null ||
            AppHelpers.normalize(task["status"]) ==
                AppHelpers.normalize(widget.filter.status!);

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
  void didUpdateWidget(covariant AdminAssigntsk oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filter != widget.filter) {
      applySearchAndFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    if (filteredTasks.isEmpty) {
      return const Center(child: Text("No matching tasks"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
