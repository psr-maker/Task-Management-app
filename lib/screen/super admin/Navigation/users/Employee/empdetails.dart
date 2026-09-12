import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/taskdetail.dart';
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
  bool isLoading = true;
  bool isActive = false;
  bool isUpdating = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  bool showFilter = false;
  String searchQuery = "";
  final TaskFilterModel taskFilter = TaskFilterModel();
  List<String> departmentsList = [];
  bool permissionLoaded = false;
  bool canEditDelete = false;
  bool canSendWarning = false;
  bool canShowMenu = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  List<dynamic> staffGoals = [];
  List<Map<String, dynamic>> standaloneTasks = [];
  final Set<String> _removedGoalCodes = {};
  DateTime? _lastRefreshTime;
  DateTime? _lastGoalRefreshTime;
  late UserModel employee;
  List<Role> roles = [];

  List<dynamic> applyGoalSearch(List<dynamic> goals) {
    List<dynamic> filtered = goals;

    // SEARCH
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();

      filtered = filtered.where((goal) {
        final title = (goal["title"] ?? "").toString().toLowerCase();
        final code = (goal["goalCode"] ?? "").toString().toLowerCase();
        final department = (goal["department"] ?? "").toString().toLowerCase();
        final status = (goal["status"] ?? "").toString().toLowerCase();
        final priority = (goal["priority"] ?? "").toString().toLowerCase();

        return title.contains(query) ||
            code.contains(query) ||
            department.contains(query) ||
            status.contains(query) ||
            priority.contains(query);
      }).toList();
    }

    // STATUS FILTER
    if (taskFilter.status != null && taskFilter.status!.isNotEmpty) {
      filtered = filtered.where((goal) {
        String goalStatus = (goal["status"] ?? "")
            .toString()
            .toLowerCase()
            .replaceAll(' ', '');

        String filterStatus = taskFilter.status!.toLowerCase().replaceAll(
          ' ',
          '',
        );

        return goalStatus == filterStatus;
      }).toList();
    }
    // PRIORITY FILTER
    if (taskFilter.priority != null && taskFilter.priority!.isNotEmpty) {
      filtered = filtered.where((goal) {
        return (goal["priority"] ?? "").toString().toLowerCase() ==
            taskFilter.priority!.toLowerCase();
      }).toList();
    }

    // DEPARTMENT FILTER
    if (taskFilter.department != null && taskFilter.department!.isNotEmpty) {
      filtered = filtered.where((goal) {
        return (goal["department"] ?? "").toString().toLowerCase() ==
            taskFilter.department!.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> applyTaskSearch(
    List<Map<String, dynamic>> tasks,
  ) {
    List<Map<String, dynamic>> filtered = tasks;

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        final title = (task["task"] ?? task["title"] ?? "")
            .toString()
            .toLowerCase();
        final code = (task["taskCode"] ?? "").toString().toLowerCase();
        final department = (task["department"] ?? task["assignerDepartment"] ?? "")
            .toString()
            .toLowerCase();
        final status = (task["status"] ?? "").toString().toLowerCase();
        final priority = (task["priority"] ?? "").toString().toLowerCase();

        return title.contains(query) ||
            code.contains(query) ||
            department.contains(query) ||
            status.contains(query) ||
            priority.contains(query);
      }).toList();
    }

    if (taskFilter.status != null && taskFilter.status!.isNotEmpty) {
      filtered = filtered.where((task) {
        final taskStatus = (task["status"] ?? "")
            .toString()
            .toLowerCase()
            .replaceAll(' ', '');
        final filterStatus = taskFilter.status!.toLowerCase().replaceAll(
          ' ',
          '',
        );
        return taskStatus == filterStatus;
      }).toList();
    }

    if (taskFilter.priority != null && taskFilter.priority!.isNotEmpty) {
      filtered = filtered.where((task) {
        return (task["priority"] ?? "").toString().toLowerCase() ==
            taskFilter.priority!.toLowerCase();
      }).toList();
    }

    if (taskFilter.department != null && taskFilter.department!.isNotEmpty) {
      filtered = filtered.where((task) {
        final department =
            (task["department"] ?? task["assignerDepartment"] ?? "")
                .toString()
                .toLowerCase();
        return department == taskFilter.department!.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  bool _isStandaloneTask(Map<String, dynamic> task) {
    final goalCode = (task["goalCode"] ?? task["goal_code"] ?? "")
        .toString()
        .trim();
    return goalCode.isEmpty || goalCode.toLowerCase() == "null";
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadRoles();
    employee = widget.employee;
  }

  void _initializeData() {
    _checkEditPermission(widget.employee);
    _reloadEmployeeStatus();
    loadEmployeeGoals(showLoader: true);
  }

  /// Reload the latest employee status and role from server
  Future<void> _reloadEmployeeStatus() async {
    try {
      final details = await SuperAdminService.getAdminDetails(
        widget.employee.userId,
      );

      if (!mounted) return;
      setState(() {
        isActive = details.status.toLowerCase() == "active";
        employee = UserModel(
          userId: details.userId,
          name: details.name,
          email: details.email,
          department: details.department,
          role: details.role,
          status: details.status,
          createdBy: details.createdBy,
          wasEdited: details.wasEdited,
        );
      });
      return;
    } catch (e) {
      debugPrint("Failed to reload employee details: $e");
    }

    try {
      final users = await SuperAdminService.getEmployees();

      if (!mounted) return;
      for (var user in users) {
        if (user.userId == widget.employee.userId) {
          setState(() {
            isActive = user.status.toLowerCase() == "active";
            employee = user;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Failed to reload employee status: $e");
    }
  }

  Future<void> _loadRoles() async {
    try {
      final rolesList = await SuperAdminService.getRoles();

      if (!mounted) return;

      setState(() {
        roles = rolesList;
      });
    } catch (e) {
      debugPrint("Failed to fetch Roles: $e");

      if (!mounted) return;

      showTopMessage("Failed to load roles", isError: true);
    }
  }

  String getRoleName(dynamic roleId) {
    if (roleId == null) return '-';
    final raw = roleId.toString().trim();
    if (raw.isEmpty) return '-';

    final id = int.tryParse(raw);
    if (id == null) return raw;

    for (final role in roles) {
      if (role.id == id) return role.name;
    }
    return raw;
  }

  Future<void> loadEmployeeGoals({bool showLoader = false}) async {
    try {
      if (showLoader && mounted) setState(() => isLoading = true);

      final goals = await AdminService.getusergoalbyid(widget.employee.userId);

      List<Map<String, dynamic>> tasks = [];
      try {
        tasks = await AdminService.getAdminTasks(widget.employee.userId);
      } catch (e) {
        debugPrint("Task load error: $e");
      }

      final nestedCodes = <String>{};
      for (final goal in goals) {
        final goalTasks = goal is Map ? (goal["tasks"] ?? []) : [];
        if (goalTasks is! List) continue;
        for (final task in goalTasks) {
          if (task is Map && task["taskCode"] != null) {
            nestedCodes.add(task["taskCode"].toString());
          }
        }
      }

      final standalone = tasks.where((task) {
        final taskCode = (task["taskCode"] ?? "").toString();
        if (taskCode.isNotEmpty && nestedCodes.contains(taskCode)) {
          return false;
        }
        return _isStandaloneTask(task);
      }).toList();

      if (mounted) {
        setState(() {
          staffGoals = goals.where((goal) {
            final code = (goal["goalCode"] ?? goal["GoalCode"] ?? "")
                .toString()
                .trim();
            return !_removedGoalCodes.contains(code);
          }).toList();
          standaloneTasks = standalone;

          departmentsList = {
            ...goals.map((g) => (g["department"] ?? "").toString()),
            ...standalone.map(
              (t) =>
                  (t["department"] ?? t["assignerDepartment"] ?? "").toString(),
            ),
          }.where((d) => d.isNotEmpty).toList();

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Goal load error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkEditPermission(UserModel employee) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final loginUserIdRaw = JwtHelper.getuid(token);
    final loginUserRoleRaw = JwtHelper.getRole(token);

    if (loginUserIdRaw == null || loginUserRoleRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();
    final loginUserRole = loginUserRoleRaw.toString().trim();

    String createdById = "";
    if (employee.createdBy.isNotEmpty) {
      if (employee.createdBy.contains('-')) {
        createdById = employee.createdBy.split('-')[0].trim();
      } else {
        createdById = employee.createdBy.trim();
      }
    }

    final isDirector = loginUserRole == "1";
    final isManager = loginUserRole == "3";
    final isTargetDirector = employee.role.toString().trim() == "1";
    final createdByMatch = loginUserId == createdById;

    var loginDept = (JwtHelper.getDepartment(token) ?? "")
        .toString()
        .trim()
        .toLowerCase();
    if (loginDept.isEmpty) {
      try {
        final details = await SuperAdminService.getAdminDetails(
          int.parse(loginUserId),
        );
        loginDept = details.department.trim().toLowerCase();
      } catch (_) {}
    }

    final employeeDept = employee.department.trim().toLowerCase();
    final sameDepartment =
        loginDept.isNotEmpty &&
        employeeDept.isNotEmpty &&
        loginDept == employeeDept;

    final allowEditDelete =
        isDirector ||
        (isManager &&
            !isTargetDirector &&
            (sameDepartment || createdByMatch));
    final allowWarning = isDirector || isManager;

    final showMenu = allowEditDelete || allowWarning;

    if (mounted) {
      setState(() {
        canEditDelete = allowEditDelete;
        canSendWarning = allowWarning;
        canShowMenu = showMenu;
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

  @override
  void didUpdateWidget(EmployeeDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the employee parameter changed
    if (oldWidget.employee.userId != widget.employee.userId) {
      _initializeData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for refresh signals and reload data
    final refreshNotifier = context.watch<DataRefreshNotifier>();

    // Reload if user refresh signal changed
    if (refreshNotifier.lastUserRefresh != null &&
        (_lastRefreshTime == null ||
            refreshNotifier.lastUserRefresh!.isAfter(_lastRefreshTime!))) {
      _lastRefreshTime = refreshNotifier.lastUserRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadEmployeeStatus();
      });
    }

    // Reload if goal refresh signal changed
    if (refreshNotifier.lastGoalRefresh != null &&
        (_lastGoalRefreshTime == null ||
            refreshNotifier.lastGoalRefresh!.isAfter(_lastGoalRefreshTime!))) {
      _lastGoalRefreshTime = refreshNotifier.lastGoalRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loadEmployeeGoals();
      });
    }
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
                style: Theme.of(context).textTheme.titleMedium,
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
            enabled: canShowMenu,
            icon: Icon(
              Icons.more_vert,
              color: canShowMenu ? Colors.white : Colors.grey,
            ),
            onSelected: (value) async {
              if (value == 'edit' && canEditDelete) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUser(user: widget.employee),
                  ),
                );

                if (result != null) {
                  setState(() {
                    employee = UserModel(
                      userId: employee.userId,
                      name: result["name"],
                      email: result["email"],
                      department: result["department"],
                      status: employee.status,
                      createdBy: employee.createdBy,
                      wasEdited: employee.wasEdited,
                      role: result["role"] ?? employee.role,
                    );
                  });
                }
              }

              if (value == 'delete' && canEditDelete) {
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
                        if (mounted) Navigator.pop(context, true);
                      });
                    } else {
                      showTopMessage("Failed to delete user", isError: true);
                    }
                  } catch (e) {
                    showTopMessage("Something went wrong", isError: true);
                  }
                }
              }

              if (value == 'send warning' && canSendWarning) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendWarningPage(
                      receiverId: widget.employee.userId,
                      receivername: employee.name,
                    ),
                  ),
                );

                if (result == true) setState(() {});
              }
            },
            itemBuilder: (_) => [
              if (canEditDelete)
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    "Edit",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

              if (canEditDelete)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    "Delete",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

              if (canSendWarning)
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

      body: isLoading ? const Center(child: RotatingFlower()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final filteredGoals = applyGoalSearch(staffGoals);
    final filteredTasks = applyTaskSearch(standaloneTasks);

    final nestedTasks = staffGoals.expand((g) => (g["tasks"] ?? [])).toList();
    final allTasksCount = nestedTasks.length + standaloneTasks.length;

    final now = DateTime.now();

    final completedGoals = staffGoals
        .where(
          (g) =>
              (g["status"] ?? "").toString().toLowerCase().trim() ==
              "completed",
        )
        .length;

    final pendingGoals = staffGoals.where((g) {
      final status = (g["status"] ?? "").toString().toLowerCase().trim();

      return status != "completed";
    }).length;

    final overdueGoals = staffGoals.where((g) {
      final status = (g["status"] ?? "").toString().toLowerCase().trim();

      if (status == "completed") return false;

      final dueDateStr = g["dueDate"];
      if (dueDateStr == null) return false;

      final dueDate = DateTime.tryParse(dueDateStr);
      if (dueDate == null) return false;

      return dueDate.isBefore(now);
    }).length;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _employeeCard(allTasksCount),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Completed",
                        value: completedGoals.toString(),
                        icon: Icons.task_alt,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending",
                        value: pendingGoals.toString(),
                        icon: Icons.pending_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue",
                        value: overdueGoals.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Goals : ${staffGoals.length}",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Createtask(
                              assignedToIds: [widget.employee.userId],
                            ),
                          ),
                        );
                        if (result == true) {
                          context.read<DataRefreshNotifier>().refreshGoals();
                          loadEmployeeGoals();
                        }
                      },
                      child: Chip(
                        backgroundColor: Theme.of(context).primaryColor,
                        label: Text(
                          "Add Goal/Task",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (filteredGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "No goals found",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      final goalCode =
                          (goal["goalCode"] ?? goal["GoalCode"] ?? "")
                              .toString()
                              .trim();
                      return GoalCard(
                        key: ValueKey(goalCode),
                        goal: goal,
                        onDelete: (msg, isError) {
                          if (!isError) {
                            setState(() {
                              if (goalCode.isNotEmpty) {
                                _removedGoalCodes.add(goalCode.trim());
                              }
                              staffGoals = staffGoals
                                  .where(
                                    (item) =>
                                        (item["goalCode"] ??
                                                item["GoalCode"] ??
                                                "")
                                            .toString()
                                            .trim() !=
                                        goalCode.trim(),
                                  )
                                  .toList();
                            });
                          }
                          showTopMessage(msg, isError: isError);
                        },
                        onRefresh: () => loadEmployeeGoals(),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                Text(
                  "Tasks : ${standaloneTasks.length}",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                if (filteredTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "No tasks without a goal",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final statusEnum = TaskUtils.parseStatus(
                        (task["status"] ?? "").toString().trim(),
                      );
                      return TaskCard(
                        task: task,
                        statusColor: TaskUtils.getStatusColor(statusEnum),
                        priorityColor: TaskUtils.getPriorityColor(
                          (task["priority"] ?? "").toString(),
                        ),
                        formatDate: AppHelpers.formatDate,
                        onTap: () async {
                          final taskCode = (task["taskCode"] ?? "").toString();
                          if (taskCode.isEmpty) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetails(taskCode: taskCode),
                            ),
                          );
                          loadEmployeeGoals();
                        },
                      );
                    },
                  ),
              ],
            ),
          ),

          // 🔽 FILTER UI
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

          // 🔽 TOP MESSAGE
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
                employee.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (employee.wasEdited == true)
              IconButton(
                onPressed: () async {
                  final token = await AuthService.getToken();
                  final role = JwtHelper.getRole(token!)?.toLowerCase().trim();
                  if (role == "1") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditLogPage(
                          highlightid: employee.userId.toString(),
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
        _row(Icons.email, employee.email),
        const SizedBox(height: 10),
        _row(Icons.business, employee.department),
        const SizedBox(height: 10),
        _row(Icons.work, getRoleName(employee.role)),

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
                      onChanged: !canEditDelete
                          ? null
                          : (value) async {
                              setState(() {
                                isActive = value;
                                isUpdating = true;
                              });

                              try {
                                await SuperAdminService.updateusersstatus(
                                  employee.userId,
                                  value ? "Active" : "Deactive",
                                );

                                if (mounted) {
                                  context
                                      .read<DataRefreshNotifier>()
                                      .refreshUsers();
                                  showTopMessage(
                                    "Status updated successfully",
                                    isError: false,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isActive = !value;
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Failed to update status: $e",
                                    ),
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

        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text("Created By", style: Theme.of(context).textTheme.titleLarge),
        //     Text(
        //       getRoleName(employee.createdBy),
        //       style: Theme.of(context).textTheme.headlineMedium,
        //     ),
        //   ],
        // ),
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
}
