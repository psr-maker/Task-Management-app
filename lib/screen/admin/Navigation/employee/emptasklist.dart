import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/employee.dart';
import 'package:staff_work_track/screen/super admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class Emptasklist extends StatefulWidget {
  final String department;
  const Emptasklist({super.key, required this.department});

  @override
  State<Emptasklist> createState() => _EmptasklistState();
}

class _EmptasklistState extends State<Emptasklist> {
  bool showFilter = false;
  bool isSearching = false;

  final TextEditingController searchController = TextEditingController();
  final TaskFilterModel activeFilter = TaskFilterModel();

  List<TaskModel> allTasks = [];
  List<TaskModel> filteredTasks = [];

  late Future<List<TaskModel>> emptasksFuture;

  @override
  void initState() {
    super.initState();
    emptasksFuture = _loadTasks();
  }

  Future<List<TaskModel>> _loadTasks() async {
    final data = await AdminService.getTasksByDepartment(widget.department);

    allTasks = data.map<TaskModel>((e) => TaskModel.fromJson(e)).toList();
    filteredTasks = List.from(allTasks);
    return filteredTasks;
  }

  List<String> getUniqueAssignedTo() {
    final Set<String> uniqueUsers = {};

    for (final task in allTasks) {
      final assignedTo = task.assignedTo;
      for (final user in assignedTo) {
        final name = user['name']?.toString();
        final role = user['role']?.toString();

        if (name != null &&
            name.isNotEmpty &&
            role != null &&
            role.isNotEmpty) {
          uniqueUsers.add("$name - $role");
        }
      }
    }

    return uniqueUsers.toList()..sort();
  }

  List<String> getUniqueDepartments() {
    final Set<String> uniqueDepts = {};
    for (final task in allTasks) {
      final assignedTo = task.assignedTo;
      for (final user in assignedTo) {
        final dept = user['department']?.toString();
        if (dept != null && dept.isNotEmpty) {
          uniqueDepts.add(dept);
        }
      }
    }
    return uniqueDepts.toList()..sort();
  }

  void applySearchAndFilter() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredTasks = allTasks.where((task) {
        final matchSearch =
            query.isEmpty ||
            task.task.toLowerCase().contains(query) ||
            AppHelpers.extractName(
              task.assignedBy,
            ).toLowerCase().contains(query);

        final matchStatus =
            activeFilter.status == null ||
            AppHelpers.normalize(task.status) ==
                AppHelpers.normalize(activeFilter.status!);

        final matchPriority =
            activeFilter.priority == null ||
            task.priority.toLowerCase() == activeFilter.priority!.toLowerCase();

        final matchDepartment =
            activeFilter.department == null ||
            task.assignedTo.any(
              (u) =>
                  (u['department'] ?? '').toLowerCase() ==
                  activeFilter.department!.toLowerCase(),
            );

        final matchAssignedTo =
            activeFilter.assignedTo == null ||
            task.assignedTo.any((u) {
              final selectedName = activeFilter.assignedTo!
                  .split(" - ")
                  .first
                  .trim()
                  .toLowerCase();

              return (u['name'] ?? '').toString().trim().toLowerCase() ==
                  selectedName;
            });

        return matchSearch &&
            matchStatus &&
            matchPriority &&
            matchDepartment &&
            matchAssignedTo;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Column(
              children: [
                /// 🔹 Top Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => Employeelist()),
                        );
                      },
                      child: Chip(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        label: Text(
                          "Add Task",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(showFilter ? Icons.close : Icons.filter_list),
                      onPressed: () {
                        setState(() => showFilter = !showFilter);
                      },
                    ),
                    if (isSearching)
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tasks',
                            hintStyle: Theme.of(
                              context,
                            ).textTheme.headlineSmall,
                            // prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (_) => applySearchAndFilter(),
                        ),
                      ),

                    IconButton(
                      icon: Icon(isSearching ? Icons.close : Icons.search),
                      onPressed: () {
                        setState(() {
                          isSearching = !isSearching;
                          searchController.clear();
                          applySearchAndFilter();
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 5),

                /// 🔹 Task List
                Expanded(
                  child: FutureBuilder<List<TaskModel>>(
                    future: emptasksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: RotatingFlower());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }

                      if (filteredTasks.isEmpty) {
                        return const Center(child: Text("No tasks found"));
                      }

                      return ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          return Taskstatus(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TaskDetails(taskCode: task.taskCode),
                                ),
                              );
                            },
                            task: {
                              'task': task.task,
                              'description': task.description,
                              'priority': task.priority,
                              'status': task.status,
                              'createdAt': task.createdAt,
                              'dueDate': task.dueDate,
                              "totalMembers": task.assignedTo.length,
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: showFilter
                  ? TaskFilterDropdown(
                      filter: activeFilter,
                      departments: getUniqueDepartments(),
                      users: getUniqueAssignedTo(),
                      onClear: () {
                        setState(() {
                          activeFilter.clear();
                          applySearchAndFilter();
                          showFilter = false;
                        });
                      },
                      onApply: () {
                        setState(() {
                          applySearchAndFilter();
                          showFilter = false;
                        });
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
