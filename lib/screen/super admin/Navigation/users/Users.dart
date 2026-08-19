import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Employee/empdetails.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class Usersview extends StatefulWidget {
  const Usersview({super.key});

  @override
  State<Usersview> createState() => _UsersviewState();
}

class _UsersviewState extends State<Usersview> {
  late Future<List<UserModel>> employeesFuture;

  bool isSelectionMode = false;
  Set<int> selectedEmpIds = {};

  bool isSearching = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Get ALL users
    employeesFuture = SuperAdminService.getAllUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _refreshUsers() {
    setState(() {
      employeesFuture = SuperAdminService.getAllUsers();
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

  List<UserModel> _filterEmployees(List<UserModel> employees) {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return employees;
    }

    return employees.where((emp) {
      return emp.name.toLowerCase().contains(query) ||
          emp.email.toLowerCase().contains(query) ||
          emp.department.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search employee",
                  hintStyle: Theme.of(context).textTheme.headlineSmall,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              )
            : Text(
                "Users List",
                style: Theme.of(context).textTheme.bodySmall,
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
             
                // Add User / Add Task
                GestureDetector(
                  onTap: () async {
                    // Selected users -> Add Task
                    if (selectedEmpIds.isNotEmpty) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Createtask(
                            assignedToIds: selectedEmpIds.toList(),
                          ),
                        ),
                      );
                      return;
                    }

                    // No selection -> Add User
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateUsers()),
                    );

                    if (result == true) {
                      _refreshUsers();
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

            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: employeesFuture,

                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: RotatingFlower());
                  }

                  // Error
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  // Empty
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  }

                  final employees = snapshot.data!;

                  final filteredEmployees = _filterEmployees(employees);

                  if (filteredEmployees.isEmpty) {
                    return const Center(child: Text("No Users Found"));
                  }

                  return ListView.builder(
                    itemCount: filteredEmployees.length,
                    physics: const AlwaysScrollableScrollPhysics(),

                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];

                      final isSelected = selectedEmpIds.contains(emp.userId);

                      return Card(
                        color: Theme.of(context).colorScheme.background,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: ListTile(
                          onLongPress: () {
                            _toggleSelection(emp.userId);
                          },

                          leading: isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  onChanged: (_) {
                                    _toggleSelection(emp.userId);
                                  },
                                )
                              : CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  child: Text(
                                    emp.name.isNotEmpty
                                        ? emp.name[0].toUpperCase()
                                        : "?",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),

                          title: Text(
                            emp.name,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text(
                              //   emp.email,
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              //   style: Theme.of(context).textTheme.labelMedium,
                              // ),

                              const SizedBox(height: 3),

                              Text(
                                emp.department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge   
                              ),
                            ],
                          ),

                          trailing: isSelectionMode
                              ? null
                              : const Icon(Icons.arrow_forward_ios, size: 16),

                          onTap: () async {
                            if (isSelectionMode) {
                              _toggleSelection(emp.userId);
                              return;
                            }

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetail(employee: emp),
                              ),
                            );

                            if (result == true) {
                              _refreshUsers();
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
