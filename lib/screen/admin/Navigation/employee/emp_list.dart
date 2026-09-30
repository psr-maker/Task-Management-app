import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/users/emp.dart';
import 'package:staff_work_track/screen/super admin/Navigation/users/Employee/empdetails.dart';
import 'package:staff_work_track/screen/super admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/widgets/users_data_table.dart';

class EmployeeList extends StatefulWidget {
  final String department;
  final String searchQuery;
  final bool openReports;
  final bool shrinkWrap;
  const EmployeeList({
    super.key,
    required this.department,
    required this.searchQuery,
    this.openReports = false,
    this.shrinkWrap = false,
  });

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  late Future<List<UserModel>> employeesFuture;
  // String selectedRole = "Staff";
  bool isSelectionMode = false;
  bool isAdmin = false;
  Set<int> selectedEmpIds = {};
  bool isSearching = false;
  final TaskFilterModel activeFilter = TaskFilterModel();
  final TextEditingController searchController = TextEditingController();

  Future<void> _openReport(UserModel emp) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeReportPage(
          userid: emp.userId,
          username: emp.name,
          role: emp.role,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    employeesFuture = AdminService.getEmployeesByDepartment(widget.department);
    _loadRole();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final role = JwtHelper.getRole(token);

    setState(() {
      isAdmin = role == "3";
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (selectedEmpIds.contains(userId)) {
        selectedEmpIds.remove(userId);
        if (selectedEmpIds.isEmpty) {
          isSelectionMode = false;
        }
      } else { 
        selectedEmpIds.add(userId);
        isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !AppLayout.isMobile(context);
    return Padding(
      padding: isWeb
          ? AppLayout.pagePadding(context)
          : const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (isAdmin && !widget.openReports)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: isSearching
                      ? TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search employee",
                            hintStyle: Theme.of(
                              context,
                            ).textTheme.headlineSmall,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        )
                      : Text(
                          "Users",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: isWeb ? 16 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching;
                      searchController.clear();
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    if (selectedEmpIds.isNotEmpty) {
                      await openFormPage(
                        context,
                        Createtask(
                          assignedToIds: selectedEmpIds.toList(),
                          assignedDepartments: [widget.department],
                        ),
                        maxWidth: 880,
                      );
                    } else {
                      final result = await openFormPage(
                        context,
                        const CreateUsers(),
                        maxWidth: 560,
                      );
                      if (result == true) {
                        setState(() {
                          employeesFuture =
                              AdminService.getEmployeesByDepartment(
                                widget.department,
                              );
                        });
                      }
                    }
                  },
                  child: Chip(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    label: Text(
                      selectedEmpIds.isNotEmpty ? "Add Task" : "Users +",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          _staffBody(),
        ],
      ),
    );
  }

  Widget _staffBody() {
    final isWeb = !AppLayout.isMobile(context);
    final body = FutureBuilder<List<UserModel>>(
              future: employeesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: RotatingFlower());
                }
                if (snapshot.hasError) {
                  return const AppLoadError();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No Employees Found"));
                }
                final employees = snapshot.data!;
                final filteredEmployees = employees.where((emp) {
                  final query =
                      searchController.text.trim().toLowerCase().isNotEmpty
                      ? searchController.text.toLowerCase()
                      : widget.searchQuery;
                  if (query.isEmpty) return true;
                  return emp.name.toLowerCase().contains(query) ||
                      emp.email.toLowerCase().contains(query) ||
                      emp.department.toLowerCase().contains(query);
                }).toList();
                if (isWeb) {
                  return UsersDataTable(
                    users: filteredEmployees,
                    shrinkWrap: widget.shrinkWrap,
                    selectedIds: selectedEmpIds,
                    selectionMode: widget.openReports ? false : isSelectionMode,
                    onToggle: (emp) => _toggleSelection(emp.userId),
                    onTap: (emp) async {
                      if (isSelectionMode) {
                        _toggleSelection(emp.userId);
                        return;
                      }
                      if (widget.openReports) {
                        await _openReport(emp);
                        return;
                      }
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeDetail(employee: emp),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          employeesFuture =
                              AdminService.getEmployeesByDepartment(
                                widget.department,
                              );
                        });
                      }
                    },
                  );
                }
                return ListView.builder(
                  shrinkWrap: widget.shrinkWrap,
                  physics: widget.shrinkWrap
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final emp = filteredEmployees[index];
                    final isSelected = selectedEmpIds.contains(emp.userId);
                    return Card(
                      color: Theme.of(context).colorScheme.background,
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onLongPress: widget.openReports
                            ? null
                            : () => _toggleSelection(emp.userId),
                        leading: isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                onChanged: (_) => _toggleSelection(emp.userId),
                              )
                            : CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                child: Text(
                                  emp.name.isNotEmpty
                                      ? emp.name[0].toUpperCase()
                                      : "?",
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                        title: Text(
                          emp.name,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        subtitle: Text(
                          emp.email,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        trailing: isSelectionMode
                            ? null
                            : Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          if (isSelectionMode) {
                            _toggleSelection(emp.userId);
                          } else if (widget.openReports) {
                            await _openReport(emp);
                          } else {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetail(employee: emp),
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                employeesFuture =
                                    AdminService.getEmployeesByDepartment(
                                      widget.department,
                                    );
                              });
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
            );
    if (widget.shrinkWrap) return body;
    return Expanded(child: body);
  }
}
