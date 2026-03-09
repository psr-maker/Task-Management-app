import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Users.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class UsersTasklist extends StatefulWidget {
  const UsersTasklist({super.key});

  @override
  State<UsersTasklist> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<UsersTasklist> {
  bool isLoading = true;
  int totalTasks = 0;
  bool isSearching = false;

  TextEditingController searchController = TextEditingController();

  List<TaskModel> allTasks = [];
  List<TaskModel> filteredTasks = [];
  bool showFilter = false;
  final TaskFilterModel activeFilter = TaskFilterModel();

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final data = await SuperAdminService.getAllTasks();
      final fetchedTasks = (data['result'] as List)
          .map((e) => TaskModel.fromJson(e))
          .toList();

      setState(() {
        totalTasks = data['totalTasks'] ?? 0;

        allTasks = fetchedTasks;
        filteredTasks = fetchedTasks;

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
      setState(() => isLoading = false);
    }
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
            ).toLowerCase().contains(query) ||
            (task.assignerDepartment ?? '').toLowerCase().contains(query);

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
                  (u['department'] ?? '').toString().toLowerCase() ==
                  activeFilter.department!.toLowerCase(),
            );

        final matchAssignedTo =
            activeFilter.assignedTo == null ||
            task.assignedTo.any((u) {
              final selectedName = activeFilter.assignedTo!
                  .split(' - ')
                  .first
                  .toLowerCase();

              return (u['name'] ?? '').toString().toLowerCase() == selectedName;
            });

        return matchSearch &&
            matchStatus &&
            matchPriority &&
            matchDepartment &&
            matchAssignedTo;
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,

                decoration: InputDecoration(
                  hintText: "Search task / user",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: (_) => applySearchAndFilter(),
              )
            : Text("All Users Tasks ($totalTasks)"),
        actions: [
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

          IconButton(
            icon: Icon(showFilter ? Icons.close : Icons.filter_list),
            onPressed: () {
              setState(() => showFilter = !showFilter);
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Usersview()),
                      );
                      if (result == true) {
                        fetchTasks();
                      }
                    },
                    child: Chip(
                      backgroundColor: Theme.of(context).primaryColor,
                      label: Text(
                        "Add Task +",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),

                  isLoading
                      ? const Center(child: RotatingFlower())
                      : ListView.builder(
                          itemCount: filteredTasks.length,

                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final statusEnum = TaskUtils.parseStatus(
                              task.status,
                            );

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TaskDetails(taskCode: task.taskCode),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme
                                      .cardTheme
                                      .color, // <-- uses theme card color
                                  borderRadius:
                                      theme.cardTheme.shape
                                          is RoundedRectangleBorder
                                      ? (theme.cardTheme.shape
                                                as RoundedRectangleBorder)
                                            .borderRadius
                                      : BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: TaskUtils.getStatusColor(
                                          statusEnum,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.task,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineLarge,
                                          ),
                                          const SizedBox(height: 6),

                                          Text(
                                            "${task.assignerRole ?? "N/A"} • ${AppHelpers.extractName(task.assignedBy)}",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
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
                                                "Due: ${AppHelpers.formatDate(task.dueDate)}",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.group,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${task.totalMembers}",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _buildChip(
                                          icon: Icons.flag,
                                          text: task.priority,
                                          color: TaskUtils.getPriorityColor(
                                            task.priority,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildChip(
                                          icon: Icons.timelapse,
                                          text: TaskUtils.getStatusText(
                                            statusEnum,
                                          ),
                                          color: TaskUtils.getStatusColor(
                                            statusEnum,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
      ),
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
