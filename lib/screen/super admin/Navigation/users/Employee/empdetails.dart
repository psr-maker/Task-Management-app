import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/craete_warnings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/edit_user.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class EmployeeDetail extends StatefulWidget {
  final UserModel employee;

  const EmployeeDetail({super.key, required this.employee});

  @override
  State<EmployeeDetail> createState() => _EmployeeDetailState();
}

class _EmployeeDetailState extends State<EmployeeDetail> {
  late Future<List<Map<String, dynamic>>> taskFuture;
  bool isActive = false;
  bool isUpdating = false;
  bool _statusInitialized = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  bool showFilter = false;
  String searchQuery = "";
  final TaskFilterModel taskFilter = TaskFilterModel();
  List<String> departmentsList = [];
  List<String> usersList = [];
  bool canEditEmployee = false;
  bool permissionLoaded = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  List<Map<String, dynamic>> applySearchAndFilter(
    List<Map<String, dynamic>> tasks,
  ) {
    return tasks.where((task) {
      final matchesSearch =
          searchQuery.isEmpty ||
          task["task"].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          task["taskCode"].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      final matchesUser =
          taskFilter.assignedTo == null ||
          (task["assignedTo"] as List).any((u) {
            final selectedUser = taskFilter.assignedTo!
                .split('-')
                .first
                .trim()
                .toLowerCase();
            final taskUser = (u["name"] ?? "").toString().trim().toLowerCase();

            return taskUser == selectedUser;
          });

      final matchesDepartment =
          taskFilter.department == null ||
          (task["assignedTo"] as List).any((u) {
            final taskDept = (u["department"] ?? "")
                .toString()
                .trim()
                .toLowerCase();
            final selectedDept = taskFilter.department!.trim().toLowerCase();

            return taskDept == selectedDept;
          });

      final matchesStatus =
          taskFilter.status == null ||
          AppHelpers.normalize(task["status"]) ==
              AppHelpers.normalize(taskFilter.status!);

      final matchesPriority =
          taskFilter.priority == null ||
          task["priority"].toString().toLowerCase() ==
              taskFilter.priority!.toLowerCase();
      return matchesSearch &&
          matchesUser &&
          matchesDepartment &&
          matchesStatus &&
          matchesPriority;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    taskFuture = AdminService.getTasksByUser(widget.employee.userId);
    _checkEditPermission(widget.employee);
  }

  Future<void> _checkEditPermission(UserModel employee) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final loginUserIdRaw = JwtHelper.getuid(token);
    final loginUserRoleRaw = JwtHelper.getRole(token);

    if (loginUserIdRaw == null || loginUserRoleRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();
    final loginUserRole = loginUserRoleRaw.toLowerCase().trim();

    // Parse createdBy numeric ID
    String createdById = "";
    if (employee.createdBy.isNotEmpty) {
      if (employee.createdBy.contains('-')) {
        createdById = employee.createdBy.split('-')[0].trim();
      } else {
        createdById = employee.createdBy.trim();
      }
    }

    // Permission: Director or created this employee/admin
    final isSuperAdmin = loginUserRole.contains("director");
    final canEdit = isSuperAdmin || (loginUserId == createdById);

    debugPrint("LOGIN ROLE RAW: '$loginUserRoleRaw'");
    debugPrint("LOGIN ROLE PROCESSED: '$loginUserRole'");
    debugPrint("LOGIN ID: $loginUserId");
    debugPrint("CREATED BY FIELD: ${employee.createdBy}");
    debugPrint("CREATED BY ID: $createdById");
    debugPrint("CAN EDIT: $canEdit");

    if (mounted) {
      setState(() {
        canEditEmployee = canEdit;
        permissionLoaded = true;
      });
    }
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  void buildFilterListsFromTasks(List<Map<String, dynamic>> tasks) {
    final Set<String> departments = {};
    final Set<String> users = {};

    for (final task in tasks) {
      final assignedList = task["assignedTo"] as List? ?? [];

      for (final u in assignedList) {
        if (u["department"] != null) {
          departments.add(u["department"].toString());
        }

        if (u["name"] != null && u["role"] != null) {
          users.add("${u["name"]}-${u["role"]}");
        }
      }
    }

    departmentsList = departments.toList();
    usersList = users.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: Theme.of(context).textTheme.labelLarge,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
              )
            : const Text("Employee Details"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                searchQuery = "";
              });
            },
          ),

          IconButton(
            icon: Icon(showFilter ? Icons.close : Icons.filter_list),
            onPressed: () {
              setState(() => showFilter = !showFilter);
            },
          ),

          PopupMenuButton<String>(
            enabled: canEditEmployee,
            icon: Icon(
              Icons.more_vert,
              color: canEditEmployee ? Colors.white : Colors.grey,
            ),
            onSelected: canEditEmployee
                ? (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditUser(user: widget.employee),
                        ),
                      );

                      if (result == true) {
                        setState(() {});
                      }
                    }

                    if (value == 'delete') {
                      final confirm = await showConfirmDialog(
                        context,
                        "Delete",
                        "User",
                      );

                      if (confirm == true) {
                        try {
                          final success = await SuperAdminService.deleteUser(
                            widget.employee.userId,
                          );

                          if (success) {
                            showTopMessage(
                              "User deleted successfully",
                              isError: false,
                            );

                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                Navigator.pop(context, true);
                              }
                            });
                          } else {
                            showTopMessage(
                              "Failed to delete user",
                              isError: true,
                            );
                          }
                        } catch (e) {
                          showTopMessage("Something went wrong", isError: true);
                        }
                      }
                    }

                    if (value == 'send warning') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendWarningPage(
                            receiverId: widget.employee.userId,
                            receivername: widget.employee.name,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {});
                      }
                    }
                  }
                : null,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  "Edit",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  "Delete",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              PopupMenuItem(
                value: 'send warning',
                child: Text(
                  "Send Warning",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          // final tasks = snapshot.data ?? [];
          final allTasks = snapshot.data ?? [];

          buildFilterListsFromTasks(allTasks);

          final tasks = applySearchAndFilter(allTasks);

          final completed = tasks
              .where((t) => t["status"] == "completed")
              .length;
          final inProgress = tasks
              .where((t) => t["status"] == "inProgress")
              .length;
          final pending = tasks.where((t) => t["status"] == "pending").length;

          if (!_statusInitialized) {
            isActive = widget.employee.status.toLowerCase() == "active";
            _statusInitialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(15),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _employeeCard(tasks.length),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryItem(
                            "Completed",
                            completed,
                            Colors.green,
                            Icons.task_alt,
                          ),
                          const SizedBox(width: 10),
                          _summaryItem(
                            "In Progress",
                            inProgress,
                            Colors.orange,
                            Icons.pending_outlined,
                          ),
                          const SizedBox(width: 10),
                          _summaryItem(
                            "Pending",
                            pending,
                            Colors.red,
                            Icons.access_time_sharp,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Task List : ${tasks.length}",
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Createtask(
                                    assignedToIds: [widget.employee.userId],
                                  ),
                                ),
                              );
                            },
                            child: Chip(
                              backgroundColor: Theme.of(context).primaryColor,
                              label: Text(
                                "Add Task",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final statusEnum = TaskUtils.parseStatus(
                            task["status"],
                          );
                          final statusColor = TaskUtils.getStatusColor(
                            statusEnum,
                          );
                          final priorityColor = TaskUtils.getPriorityColor(
                            task["priority"],
                          );

                          return TaskCard(
                            task: task,
                            statusColor: statusColor,
                            priorityColor: priorityColor,
                            formatDate: AppHelpers.formatDate,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TaskDetails(taskCode: task["taskCode"]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                if (showFilter)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 8,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: TaskFilterDropdown(
                        filter: taskFilter,
                        departments: departmentsList,
                        users: usersList,
                        onClear: () {
                          setState(() {
                            taskFilter.clear();
                            showFilter = false;
                          });
                        },
                        onApply: () {
                          setState(() {
                            showFilter = false;
                          });
                        },
                      ),
                    ),
                  ),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      iconColor: Theme.of(context).colorScheme.onPrimary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _employeeCard(int taskCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.person),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.employee.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (widget.employee.wasEdited == true)
              IconButton(
                onPressed: () async {
                  final token = await AuthService.getToken();
                  final role = JwtHelper.getRole(token!)?.toLowerCase().trim();
                  if (role == "director") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditLogPage(
                          highlightid: widget.employee.userId.toString(),
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _row(Icons.email, widget.employee.email),
        const SizedBox(height: 10),
        _row(Icons.business, widget.employee.department),

        Row(
          children: [
            Text(
              isActive ? "Active" : "Deactive",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            isUpdating
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: RotatingFlower(size: 10),
                  )
                : Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (value) async {
                        setState(() {
                          isActive = value;
                          isUpdating = true;
                        });

                        try {
                          await SuperAdminService.updateusersstatus(
                            widget.employee.userId,
                            value ? "Active" : "Deactive",
                          );
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              isActive = !value;
                            });
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to update status: $e"),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              isUpdating = false;
                            });
                          }
                        }
                      },
                    ),
                  ),
          ],
        ),

        Divider(height: 10, color: Theme.of(context).colorScheme.secondary),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Created By", style: Theme.of(context).textTheme.titleLarge),
            Text(
              widget.employee.createdBy.split('-').length > 1
                  ? widget.employee.createdBy.split('-')[1]
                  : widget.employee.createdBy,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.headlineLarge),
        ),
      ],
    );
  }

  Widget _summaryItem(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 5),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
