import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/craete_warnings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/edit_user.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/widgets/StatCard.dart';

class Admindetails extends StatefulWidget {
  final int adminId;

  const Admindetails({super.key, required this.adminId});

  @override
  State<Admindetails> createState() => _AdmindetailsState();
}

class _AdmindetailsState extends State<Admindetails> {
  late Future<UsersDetails> adminFuture;
  bool isActive = false;
  bool isUpdating = false;
  bool showEmployees = true;
  bool showAdminTasks = false;
  bool showAssignedTasks = false;
  bool _statusInitialized = false;
  List<dynamic> managerGoals = [];
  List<dynamic> managerassignGoals = [];

  UsersDetails? _admin;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  final TaskFilterModel taskFilter = TaskFilterModel();
  bool showFilter = false;
  List<String> departmentsList = [];
  List<String> usersList = [];
  bool permissionLoaded = false;
  bool canEditadmin = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();

    adminFuture = SuperAdminService.getAdminDetails(widget.adminId);
    _loadGoalCounts();
    adminFuture.then((adminDetails) {
      final adminUser = UserModel(
        userId: adminDetails.userId,
        name: adminDetails.name,
        email: adminDetails.email,
        department: adminDetails.department,
        role: adminDetails.role,
        status: adminDetails.status,
        createdBy: adminDetails.createdBy,
        wasEdited: adminDetails.wasEdited,
      );

      _checkEditPermission(adminUser);
    });
  }

  List<dynamic> applyGoalSearch(List<dynamic> goals) {
    List<dynamic> filtered = goals;

    // SEARCH
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();

      filtered = filtered.where((goal) {
        final title = (goal["title"] ?? "").toString().toLowerCase();
        final code = (goal["goalCode"] ?? "").toString().toLowerCase();
        final department = (goal["department"] ?? "").toString().toLowerCase();

        return title.contains(query) ||
            code.contains(query) ||
            department.contains(query);
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

  Future<void> _checkEditPermission(UserModel user) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final loginUserIdRaw = JwtHelper.getuid(token);
    final loginUserRoleRaw = JwtHelper.getRole(token);
    if (loginUserIdRaw == null || loginUserRoleRaw == null) return;

    final loginUserId = loginUserIdRaw.toString().trim();
    final loginUserRole = loginUserRoleRaw.toLowerCase().trim();

    String createdById = '';
    if (user.createdBy.contains('-')) {
      createdById = user.createdBy.split('-')[0].trim();
    } else {
      createdById = user.createdBy.trim();
    }

    final isSuperAdmin = loginUserRole == "Director";

    final canEdit = isSuperAdmin || (loginUserId == createdById);

    debugPrint("=== PERMISSION CHECK ===");
    debugPrint("LOGIN ROLE: $loginUserRole");
    debugPrint("LOGIN ID: $loginUserId");
    debugPrint("TARGET CREATED BY: $createdById");
    debugPrint("CAN EDIT: $canEdit");
    debugPrint("========================");

    if (mounted) {
      setState(() {
        canEditadmin = canEdit;
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

  Future<void> _loadGoalCounts() async {
    try {
      final adminGoals = await AdminService.getusergoalbyid(widget.adminId);
      final assignedGoals = await AdminService.getgoalAssignedByAdmin(
        widget.adminId,
      );

      if (mounted) {
        setState(() {
          managerGoals = adminGoals;
          managerassignGoals = assignedGoals;
        });
      }
    } catch (e) {
      debugPrint("Failed to load goals: $e");
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
              )
            : const Text("Manager Details"),
        actions: [
          if (showAdminTasks || showAssignedTasks || showEmployees)
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
          if (showAdminTasks || showAssignedTasks)
            IconButton(
              icon: Icon(showFilter ? Icons.close : Icons.filter_list),
              onPressed: () {
                setState(() => showFilter = !showFilter);
              },
            ),

          PopupMenuButton<String>(
            borderRadius: BorderRadius.circular(15),

            enabled: canEditadmin,
            icon: Icon(
              Icons.more_vert,
              color: canEditadmin ? Colors.white : Colors.grey,
            ),
            onSelected: canEditadmin
                ? (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditUser(user: _admin!),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          adminFuture = SuperAdminService.getAdminDetails(
                            widget.adminId,
                          );
                          _admin = null;
                        });
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
                            _admin!.userId,
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
                            receiverId: _admin!.userId,
                            receivername: _admin!.name,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          adminFuture = SuperAdminService.getAdminDetails(
                            widget.adminId,
                          );
                          _admin = null;
                        });
                      }
                    }
                  }
                : null,
            itemBuilder: (context) => [
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

      body: FutureBuilder<UsersDetails>(
        future: adminFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          }

          final admin = snapshot.data!;
          _admin ??= admin;
          if (!_statusInitialized) {
            isActive = admin.status.toLowerCase() == "active";
            _statusInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Stack(
              children: [
                Column(
                  children: [
                    _detailCard(admin),
                    SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    Createtask(assignedToIds: [admin.userId]),
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                adminFuture = SuperAdminService.getAdminDetails(
                                  widget.adminId,
                                );
                              });
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
                    SizedBox(height: 5),
                    _statsRow(admin),
                  ],
                ),
                if (showFilter && (showAdminTasks || showAssignedTasks))
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
                        //  users: usersList,
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
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailCard(UsersDetails admin) {
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
                admin.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (admin.wasEdited == true)
              IconButton(
                onPressed: () async {
                  final token = await AuthService.getToken();
                  final role = JwtHelper.getRole(token!)?.toLowerCase().trim();
                  if (role == "director") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AuditLogPage(highlightid: admin.userId.toString()),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.edit_outlined),
              ),
            // ),
          ],
        ),

        const SizedBox(height: 8),
        _row(Icons.email, admin.email),
        const SizedBox(height: 8),
        _row(Icons.business, admin.department),

        // _row(Icons.person, admin.role),
        Row(
          children: [
            Text(
              isActive ? "Active" : "Deactive",
              style: TextStyle(
                fontSize: 14,
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
                            admin.userId,
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
              admin.createdBy.split('-').length > 1
                  ? admin.createdBy.split('-')[1]
                  : admin.createdBy,
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

  Widget _statsRow(UsersDetails admin) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: "Staff",
                value: admin.totalEmployees,
                icon: Icons.groups,
                isActive: showEmployees,
                onTap: () {
                  setState(() {
                    showEmployees = true;
                    showAdminTasks = false;
                    showAssignedTasks = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                title: "Manager Goals",
                value: managerGoals.length,
                icon: Icons.task_alt,
                isActive: showAdminTasks,
                onTap: () {
                  setState(() {
                    showAdminTasks = true;
                    showEmployees = false;
                    showAssignedTasks = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                title: "Assigned Goals",
                value: managerassignGoals.length,
                icon: Icons.assignment,
                isActive: showAssignedTasks,
                onTap: () {
                  setState(() {
                    showAssignedTasks = true;
                    showEmployees = false;
                    showAdminTasks = false;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        if (showEmployees)
          EmployeeList(department: admin.department, searchQuery: searchQuery),

        if (showAdminTasks)
          Builder(
            builder: (context) {
              final filteredGoals = applyGoalSearch(managerGoals);

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGoals.length,
                itemBuilder: (context, index) {
                  final goal = filteredGoals[index];
                  return GoalCard(goal: goal);
                },
              );
            },
          ),

        if (showAssignedTasks)
          Builder(
            builder: (context) {
              final filteredGoals = applyGoalSearch(managerassignGoals);

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGoals.length,
                itemBuilder: (context, index) {
                  final goal = filteredGoals[index];
                  return GoalCard(goal: goal);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 227, 248, 228),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Color.fromARGB(255, 25, 77, 38)
                  : Colors.green.shade300,
            ),
            const SizedBox(height: 5),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? Color.fromARGB(255, 25, 77, 38)
                    : Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
