import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/common/filter_model.dart';
import 'package:staff_work_track/screen/super admin/Navigation/users/Employee/empdetails.dart';
import 'package:staff_work_track/screen/super admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class EmployeeList extends StatefulWidget {
  final String department;
  final String searchQuery;
  const EmployeeList({
    super.key,
    required this.department,
    required this.searchQuery,
  });

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  late Future<List<UserModel>> employeesFuture;
  String selectedRole = "Staff";

  bool isSelectionMode = false;
  bool isAdmin = false;
  Set<int> selectedEmpIds = {};

  bool isSearching = false;
  final TaskFilterModel activeFilter = TaskFilterModel();

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    employeesFuture = AdminService.getEmployeesByDepartment(widget.department);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final role = JwtHelper.getRole(token);

    setState(() {
      isAdmin = role == "Manager";
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
    return FutureBuilder<List<UserModel>>(
      future: employeesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RotatingFlower());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No Employees Found"));
        }

        final employees = snapshot.data!;

        final filteredEmployees = employees.where((emp) {
          // final query = widget.searchQuery.trim().toLowerCase();
          final query = searchController.text.trim().toLowerCase().isNotEmpty
              ? searchController.text.toLowerCase()
              : widget.searchQuery;

          if (query.isEmpty) return true;

          return emp.name.toLowerCase().contains(query) ||
              emp.email.toLowerCase().contains(query) ||
              emp.department.toLowerCase().contains(query);
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                if (isAdmin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: isSearching
                            ? TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: "Search employee...",
                                  hintStyle: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium,
                                  // prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() {}),
                              )
                            : Text(
                                "Staff List",
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                      ),

                      IconButton(
                        icon: Icon(
                          isSearching ? Icons.close : Icons.search,
                         
                        ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Createtask(
                                  assignedToIds: selectedEmpIds.toList(),
                                ),
                              ),
                            );
                          } else {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateUsers(role: selectedRole),
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

                        child:   Chip(
                         backgroundColor: const Color.fromARGB(255, 25, 77, 38),
                        label: Text(
                          selectedEmpIds.isNotEmpty
                              ? "Add Task"
                              : "Staff +",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ),
                    ],
                  ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final emp = filteredEmployees[index];

                    final isSelected = selectedEmpIds.contains(emp.userId);

                    return Card(
                      color: const Color.fromARGB(255, 134, 170, 136),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onLongPress: () => _toggleSelection(emp.userId),

                        leading: isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: const Color.fromARGB(
                                  255,
                                  25,
                                  77,
                                  38,
                                ),
                                onChanged: (_) => _toggleSelection(emp.userId),
                              )
                            : CircleAvatar(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  25,
                                  77,
                                  38,
                                ),
                                child: Text(
                                  emp.name.isNotEmpty
                                      ? emp.name[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),

                        title: Text(
                          emp.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),

                        subtitle: Text(
                          emp.email,
                           style: Theme.of(context).textTheme.titleMedium,
                        ),

                        trailing: isSelectionMode
                            ? null
                            : Icon(
                                Icons.arrow_forward_ios,
                                
                              ),

                        onTap: () {
                          if (isSelectionMode) {
                            _toggleSelection(emp.userId);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetail(employee: emp),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
