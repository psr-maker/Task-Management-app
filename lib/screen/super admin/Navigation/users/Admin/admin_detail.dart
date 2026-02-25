import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/common/search_filter_page.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Admin/admintask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Admin/assignedtask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/edit_user.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';

import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

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
  UsersDetails? _admin;

  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  // common
  String searchQuery = "";
  final TaskFilterModel taskFilter = TaskFilterModel();
  bool showFilter = false;
  List<String> departmentsList = [];
  List<String> usersList = [];
  bool permissionLoaded = false;
  bool canEditadmin = false;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    adminFuture = SuperAdminService.getAdminDetails(widget.adminId);

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

  void _buildFilterListsFromTasks(List<Map<String, dynamic>> tasks) {
    final departmentSet = <String>{};
    final userWithRoleList = <String>[];

    for (final task in tasks) {
      final assignedList = task["assignedTo"] as List? ?? [];

      for (final u in assignedList) {
        final dept = u["department"]?.toString();
        final name = u["name"]?.toString();
        final role = u["role"]?.toString();

        if (dept != null && dept.isNotEmpty) {
          departmentSet.add(dept);
        }

        if (name != null && role != null) {
          final combined = "$name - $role";
          if (!userWithRoleList.contains(combined)) {
            userWithRoleList.add(combined);
          }
        }
      }
    }

    setState(() {
      departmentsList = departmentSet.toList()..sort();
      usersList = userWithRoleList..sort();
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
            : const Text(
                "Manager Details",
              
              ),
        actions: [
          if (showAdminTasks || showAssignedTasks || showEmployees)
            IconButton(
              icon: Icon(
                isSearching ? Icons.close : Icons.search,
               
              ),
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
              icon: Icon(
                showFilter ? Icons.close : Icons.filter_list,
              
              ),
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
                        await SuperAdminService.deleteUser(_admin!.userId);
                        Navigator.pop(context, true);
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    Createtask(assignedToIds: [admin.userId]),
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
            Icon(
              Icons.person,
             
            ),
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
                  if (role == "Director") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AuditLogPage(highlightid: admin.userId.toString()),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.edit_outlined,
                 
                ),
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
                color: isActive ? Theme.of(context).colorScheme.secondary : Colors.red,
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
                      activeColor:Theme.of(context).colorScheme.secondary,
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

         Divider(height: 10, color: Theme.of(context).colorScheme.secondary,),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              "Created By",
            style: Theme.of(context).textTheme.titleLarge
            ),
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
        Icon(icon,),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
           style: Theme.of(context).textTheme.headlineLarge,
          ),
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
                title: "Manager Tasks",
                value: admin.totalTasksAssignedTo,
                icon: Icons.task_alt,
                isActive: showAdminTasks,
                onTap: () async {
                  setState(() {
                    showAdminTasks = true;
                    showEmployees = false;
                    showAssignedTasks = false;
                  });

                  final tasks = await AdminService.getAdminTasks(admin.userId);

                  if (mounted) {
                    _buildFilterListsFromTasks(tasks);
                    setState(() {
                      taskFilter.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                title: "Assigned Tasks",
                value: admin.totalTasksAssignedBy,
                icon: Icons.assignment,
                isActive: showAssignedTasks,
                onTap: () async {
                  setState(() {
                    showAssignedTasks = true;
                    showEmployees = false;
                    showAdminTasks = false;
                  });

                  final tasks = await AdminService.getTasksAssignedByAdmin(
                    admin.userId,
                  );

                  if (mounted) {
                    final List<Map<String, dynamic>> taskMaps = tasks
                        .cast<Map<String, dynamic>>();

                    _buildFilterListsFromTasks(taskMaps);
                    setState(() {
                      taskFilter.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ), 
        SizedBox(height: 10),
        if (showEmployees)
          EmployeeList(department: admin.department, searchQuery: searchQuery),

        if (showAdminTasks)
          Admintask(
            adminId: admin.userId,
            searchQuery: searchQuery,
            filter: taskFilter,
          ),

        if (showAssignedTasks)
          AdminAssigntsk(
            adminId: admin.userId,
            searchQuery: searchQuery,
            filter: taskFilter,
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
            Text(
              title,
             style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  } 
}
