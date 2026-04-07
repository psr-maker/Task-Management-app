import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Employee/empdetails.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class Employeetab extends StatefulWidget {
  const Employeetab({super.key});

  @override
  State<Employeetab> createState() => _EmployeetabState();
}

class _EmployeetabState extends State<Employeetab> {
  late Future<List<UserModel>> employeeFuture;
  List<int> selectedempIds = [];
  bool isSelectionMode = false;
  String selectedRole = "Staff";
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<UserModel> allEmp = [];
  List<UserModel> filteredemp = [];
  @override
  void initState() {
    super.initState();
    employees();
    isSelectionMode = false;
    selectedempIds.clear();
  }

  void employees() async {
    employeeFuture = SuperAdminService.getEmployees();

    employeeFuture.then((data) {
      setState(() {
        allEmp = data;
        filteredemp = data;
      });
    });
  }

  void applySearch(String query) {
    final text = query.toLowerCase().trim();

    setState(() {
      filteredemp = allEmp.where((emp) {
        return emp.name.toLowerCase().contains(text) ||
            emp.department.toLowerCase().contains(text);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: isSearching
                      ? TextField(
                          controller: searchController,
                          autofocus: true,

                          decoration: InputDecoration(
                            hintText: "Search Staff",
                            hintStyle: Theme.of(context).textTheme.bodyMedium,
                            border: InputBorder.none,
                          ),
                          onChanged: applySearch,
                        )
                      : Text(
                          "Staff List",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                ),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(isSearching ? Icons.close : Icons.search),
                      onPressed: () {
                        setState(() {
                          isSearching = !isSearching;
                          searchController.clear();
                          filteredemp = allEmp;
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (selectedempIds.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Createtask(
                                assignedToIds: selectedempIds.toList(),
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
                            employees();
                          }
                        }
                      },
                      child: Chip(
                        label: Text(
                          selectedempIds.isNotEmpty
                              ? "Add Goal/Task"
                              : "Staff +",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),
            Expanded(
              child: FutureBuilder(
                future: employeeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: RotatingFlower());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No Staff Found"));
                  } else {
                    // final employee = snapshot.data!;
                    final employee = isSearching ? filteredemp : snapshot.data!;
                    return ListView.builder(
                      itemCount: employee.length,
                      itemBuilder: (context, index) {
                        final emp = employee[index];
                        return GestureDetector(
                          onLongPress: () {
                            setState(() {
                              isSelectionMode = true;
                              selectedempIds.add(emp.userId);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).colorScheme.background,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isSelectionMode)
                                        Checkbox(
                                          value: selectedempIds.contains(
                                            emp.userId,
                                          ),
                                          activeColor: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedempIds.add(emp.userId);
                                              } else {
                                                selectedempIds.remove(
                                                  emp.userId,
                                                );
                                                if (selectedempIds.isEmpty) {
                                                  isSelectionMode = false;
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        child: Text(
                                          emp.name[0].toUpperCase(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 15),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              emp.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelMedium,
                                            ),
                                            const SizedBox(height: 5),

                                            Text(
                                              emp.department,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                            const SizedBox(height: 5),

                                            Row(
                                              children: [
                                                Text(
                                                  "Creator - ",
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.labelSmall,
                                                ),
                                                Text(
                                                  emp.createdBy
                                                              .split('-')
                                                              .length >
                                                          1
                                                      ? emp.createdBy.split(
                                                          '-',
                                                        )[1]
                                                      : emp.createdBy,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.labelSmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      InkWell(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EmployeeDetail(employee: emp),
                                            ),
                                          );
                                          if (result == true) {
                                            employees();
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.arrow_forward_ios),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
