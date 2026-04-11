import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/craete_warnings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/edit_user.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
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
  bool _statusInitialized = false;

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
        return (goal["status"] ?? "").toString().toLowerCase() ==
            taskFilter.status!.toLowerCase();
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

  @override
  void initState() {
    super.initState();

    _checkEditPermission(widget.employee);
    loadEmployeeGoals();
  }

  Future<void> loadEmployeeGoals() async {
    try {
      setState(() => isLoading = true);

      final goals = await AdminService.getusergoalbyid(widget.employee.userId);

      if (mounted) {
        setState(() {
          staffGoals = goals;

          departmentsList = goals
              .map((g) => (g["department"] ?? "").toString())
              .where((d) => d.isNotEmpty)
              .toSet()
              .toList();

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Goal load error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkEditPermission(UserModel employee) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final loginUserIdRaw = JwtHelper.getuid(token);
    final loginUserRoleRaw = JwtHelper.getRole(token);

    if (loginUserIdRaw == null || loginUserRoleRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();
    final loginUserRole = loginUserRoleRaw.toLowerCase().trim();

    // Extract createdBy ID
    String createdById = "";
    if (employee.createdBy.isNotEmpty) {
      if (employee.createdBy.contains('-')) {
        createdById = employee.createdBy.split('-')[0].trim();
      } else {
        createdById = employee.createdBy.trim();
      }
    }

    final isDirector = loginUserRole.contains("director");
    final isManager = loginUserRole.contains("manager");

    // ✅ RULES
    final allowEditDelete = isDirector || (loginUserId == createdById);
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

                if (result == true) {
                  loadEmployeeGoals();
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
                      receivername: widget.employee.name,
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

    final allTasks = staffGoals.expand((g) => (g["tasks"] ?? [])).toList();
    if (!_statusInitialized) {
      isActive = widget.employee.status.toLowerCase() == "active";
      _statusInitialized = true;
    }

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
                _employeeCard(allTasks.length),

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

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredGoals.length,
                  itemBuilder: (context, index) {
                    final goal = filteredGoals[index];
                    return GoalCard(goal: goal);
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
}
