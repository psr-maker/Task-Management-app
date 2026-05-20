import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/auth_service.dart';

class AssignUsersPage extends StatefulWidget {
  final List<UserModel> users;
  final List<UserModel> selectedUsers;

  const AssignUsersPage({
    super.key,
    required this.users,
    required this.selectedUsers,
  });

  @override
  State<AssignUsersPage> createState() => _AssignUsersPageState();
}

class _AssignUsersPageState extends State<AssignUsersPage> {
  late List<UserModel> selected;
  List<UserModel> filteredUsers = [];

  bool isSearching = false;
  bool isLoading = false;
  bool isStaffUser = false;

  String? loginRole;
  String? loginDepartment;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.selectedUsers);

    initUserData();
  }

  Future<void> initUserData() async {
    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final decoded = JwtDecoder.decode(token);
      final userId = int.parse(decoded['UserId'].toString());

      loginRole = decoded['Role'];

      // ✅ Find current user in the provided users list to get their department
      UserModel? currentUser;
      for (var user in widget.users) {
        if (user.userId == userId) {
          currentUser = user;
          break;
        }
      }

      if (currentUser != null) {
        loginDepartment = currentUser.department;
        debugPrint("✅ Got manager department from users list: $loginDepartment");
      } else {
        debugPrint("⚠️ Current user not found in users list. userId: $userId");
      }

      _applyRoleBasedFilter(); // ✅ NOW SAFE
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ✅ Main Role Logic
  void _applyRoleBasedFilter() {
    if (loginRole == "Staff") {
      setState(() {
        isStaffUser = true;
      });
      return;
    }

    List<UserModel> users = widget.users;

    if (loginRole == "Director") {
      users = users.where((u) => u.role != "Director").toList();
    } else if (loginRole == "Manager") {
      // Filter users by: same department AND not director
      if (loginDepartment != null && loginDepartment!.isNotEmpty) {
        users = users
            .where((u) =>
                u.department.toLowerCase().trim() ==
                    loginDepartment!.toLowerCase().trim() &&
                u.role != "Director")
            .toList();
      } else {
        // If department is not available, show no users
        users = [];
        debugPrint(
            "⚠️ Manager department not found. loginDepartment: $loginDepartment");
      }
    }

    setState(() {
      filteredUsers = users;
    });
  }

  void applySearch(String query) {
    final text = query.toLowerCase().trim();

    // Start with role-filtered users
    List<UserModel> baseUsers = [];
    
    if (loginRole == "Director") {
      baseUsers = widget.users.where((u) => u.role != "Director").toList();
    } else if (loginRole == "Manager" && loginDepartment != null) {
      baseUsers = widget.users
          .where((u) =>
              u.department.toLowerCase().trim() ==
                  loginDepartment!.toLowerCase().trim() &&
              u.role != "Director")
          .toList();
    }

    // Then search within those users
    setState(() {
      filteredUsers = baseUsers.where((user) {
        return user.name.toLowerCase().contains(text) ||
            user.department.toLowerCase().contains(text) ||
            user.role.toLowerCase().contains(text);
      }).toList();
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
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: applySearch,
              )
            : Text("Assign Users (${selected.length})"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                _applyRoleBasedFilter();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: !isStaffUser
            ? Column(
                children: [
                  //isStaffUser
                  // ? Text(
                  //     "You can't assign any staff",
                  //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  //   )
                  // :
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? const Center(child: Text("No users found"))
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isSelected = selected.any(
                                (u) => u.userId == user.userId,
                              );
                    
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selected.removeWhere(
                                        (u) => u.userId == user.userId,
                                      );
                                    } else {
                                      selected.add(user);
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color.fromARGB(
                                      255,
                                      134,
                                      170,
                                      136,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: const Color.fromARGB(
                                            255,
                                            50,
                                            99,
                                            49,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                selected.add(user);
                                              } else {
                                                selected.removeWhere(
                                                  (u) => u.userId == user.userId,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            50,
                                            99,
                                            49,
                                          ),
                                          child: Text(user.name[0].toUpperCase()),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelMedium,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "${user.role} • ${user.department}",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  AppButton(
                    text: "Done",
                    isLoading: isLoading,
                    onPressed: () {
                      Navigator.pop(context, selected);
                    },
                    color: Theme.of(context).colorScheme.secondary,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
              )
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "You can't assign any staff",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
