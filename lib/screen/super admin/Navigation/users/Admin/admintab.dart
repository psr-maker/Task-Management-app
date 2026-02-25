import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Admin/admin_detail.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/create_task.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/user_create.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class Admintab extends StatefulWidget {
  const Admintab({super.key});

  @override
  State<Admintab> createState() => AdmintabState();
}

class AdmintabState extends State<Admintab> {
  late Future<List<UserModel>> adminsFuture;
  List<int> selectedAdminIds = [];
  bool isSelectionMode = false;
  bool isSearching = false;
  String selectedRole = "Manager";
  TextEditingController searchController = TextEditingController();
  List<UserModel> allAdmin = [];
  List<UserModel> filteredadmin = [];
  @override
  void initState() {
    super.initState();
    loadAdmins();
    isSelectionMode = false;
    selectedAdminIds.clear();
  }

  void loadAdmins() async {
    adminsFuture = SuperAdminService.getAdmins();

    adminsFuture.then((data) {
      setState(() {
        allAdmin = data;
        filteredadmin = data;
      });
    });
  }

  void applySearch(String query) {
    final text = query.toLowerCase().trim();

    setState(() {
      filteredadmin = allAdmin.where((admin) {
        return admin.name.toLowerCase().contains(text) ||
            admin.department.toLowerCase().contains(text);
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
                /// LEFT SIDE (TITLE / SEARCH)
                Expanded(
                  child: isSearching
                      ? TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search Manager...",
                              hintStyle: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium,
                               
                            // prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: applySearch,
                        )
                      : Text(
                          "Manager List",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                ),

                /// RIGHT SIDE ACTIONS
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isSearching ? Icons.close : Icons.search,
                    
                      ),
                      onPressed: () {
                        setState(() {
                          isSearching = !isSearching;
                          searchController.clear();
                          filteredadmin = allAdmin;
                        });
                      },
                    ),
                    GestureDetector(
                      
                      onTap: () async {
                        if (selectedAdminIds.isNotEmpty) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Createtask(
                                assignedToIds: selectedAdminIds.toList(),
                              ),
                            ),
                          );
                          setState(() {
                            isSelectionMode = false;
                            selectedAdminIds.clear();
                          });
                          loadAdmins();
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateUsers(role: selectedRole),
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              isSelectionMode = false;
                              selectedAdminIds.clear();
                            });
                            loadAdmins();
                          }
                        }
                      },

                      child: Chip(
                         backgroundColor: const Color.fromARGB(255, 25, 77, 38),
                        label: Text(
                          selectedAdminIds.isNotEmpty
                              ? "Add Task"
                              : "Manager +",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Expanded(
              child: FutureBuilder(
                future: adminsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: RotatingFlower());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No Manager Found"));
                  } else {
                    // final admins = snapshot.data!;
                    final admins = isSearching ? filteredadmin : snapshot.data!;

                    return ListView.builder(
                      itemCount: admins.length,
                      itemBuilder: (context, index) {
                        final admin = admins[index];
                        return GestureDetector(
                          onLongPress: () { 
                            setState(() {
                              isSelectionMode = true;
                              selectedAdminIds.add(admin.userId);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color.fromARGB(255, 134, 170, 136),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  if (isSelectionMode)
                                    Checkbox(
                                      value: selectedAdminIds.contains(
                                        admin.userId,
                                      ),
                                      activeColor: const Color.fromARGB(
                                            255,
                                            50,
                                            99,
                                            49,
                                          ),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedAdminIds.add(admin.userId);
                                          } else {
                                            selectedAdminIds.remove(
                                              admin.userId,
                                            );
                                            if (selectedAdminIds.isEmpty) {
                                              isSelectionMode = false;
                                            }
                                          }
                                        });
                                      },
                                    ),

                                  // ✅ Existing UI
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color.fromARGB(
                                            255,
                                            50,
                                            99,
                                            49,
                                          ),
                                    child: Text(
                                      admin.name[0].toUpperCase(),
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          admin.name,
                                          style: Theme.of(context).textTheme.labelLarge,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          admin.department,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Admindetails(
                                            adminId: admin.userId,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        loadAdmins();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color:Color.fromARGB(255, 25, 77, 38),
                                      ),
                                    ),
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
