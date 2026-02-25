// import 'package:flutter/material.dart';
// import 'package:staff_work_track/Models/getusers.dart';
// import 'package:staff_work_track/core/widgets/buttons.dart';

// class AssignUsersPage extends StatefulWidget {
//   final List<UserModel> users;
//   final List<UserModel> selectedUsers;

//   const AssignUsersPage({
//     super.key,
//     required this.users,
//     required this.selectedUsers,
//   });

//   @override
//   State<AssignUsersPage> createState() => _AssignUsersPageState();
// }

// class _AssignUsersPageState extends State<AssignUsersPage> {
//   late List<UserModel> selected;
//   late List<UserModel> filteredUsers;

//   bool isSearching = false;
//   bool _isLoading = false; // ✅ FIXED
//   TextEditingController searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     selected = List.from(widget.selectedUsers);
//     filteredUsers = widget.users;
//   }

//   void applySearch(String query) {
//     final text = query.toLowerCase().trim();

//     setState(() {
//       filteredUsers = widget.users.where((user) {
//         return user.name.toLowerCase().contains(text) ||
//             user.department.toLowerCase().contains(text) ||
//             user.role.toLowerCase().contains(text);
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: isSearching
//             ? TextField(
//                 controller: searchController,
//                 autofocus: true,
//                 decoration: const InputDecoration(
//                   hintText: "Search users...",
//                   border: InputBorder.none,
//                 ),
//                 onChanged: applySearch,
//               )
//             : Text("Assign Users (${selected.length})"), // ✅ show count
//         actions: [
//           IconButton(
//             icon: Icon(isSearching ? Icons.close : Icons.search),
//             onPressed: () {
//               setState(() {
//                 isSearching = !isSearching;
//                 searchController.clear();
//                 filteredUsers = widget.users;
//               });
//             },
//           ),
//         ],
//       ),

//       body: Padding(
//         padding: const EdgeInsets.all(15),
//         child: Column(
//           children: [
//             /// ✅ FIXED: Expanded added
//             Expanded(
//               child: filteredUsers.isEmpty
//                   ? const Center(child: Text("No users found"))
//                   : ListView.builder(
//                       itemCount: filteredUsers.length,
//                       itemBuilder: (context, index) {
//                         final user = filteredUsers[index];
//                         final isSelected = selected.any(
//                           (u) => u.userId == user.userId,
//                         );

//                         return GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               if (isSelected) {
//                                 selected.removeWhere(
//                                   (u) => u.userId == user.userId,
//                                 );
//                               } else {
//                                 selected.add(user);
//                               }
//                             });
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.only(bottom: 14),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(16),
//                               color: const Color.fromARGB(255, 134, 170, 136),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(10),
//                               child: Row(
//                                 children: [
//                                   Checkbox(
//                                     value: isSelected,
//                                     activeColor: const Color.fromARGB(
//                                       255,
//                                       50,
//                                       99,
//                                       49,
//                                     ),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         if (value == true) {
//                                           selected.add(user);
//                                         } else {
//                                           selected.removeWhere(
//                                             (u) => u.userId == user.userId,
//                                           );
//                                         }
//                                       });
//                                     },
//                                   ),
//                                   CircleAvatar(
//                                     radius: 18,
//                                     backgroundColor: const Color.fromARGB(
//                                       255,
//                                       50,
//                                       99,
//                                       49,
//                                     ),
//                                     child: Text(
//                                       user.name[0].toUpperCase(),
//                                       style: Theme.of(
//                                         context,
//                                       ).textTheme.labelLarge,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 15),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           user.name,
//                                           style: Theme.of(
//                                             context,
//                                           ).textTheme.headlineLarge,
//                                         ),
//                                         const SizedBox(height: 3),
//                                         Text(
//                                           "${user.role} • ${user.department}",
//                                           style: Theme.of(
//                                             context,
//                                           ).textTheme.titleLarge,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),

//             /// ✅ Correct Button
//             AppButton(
//               text: "Done",
//               isLoading: _isLoading,
//               onPressed: () {
//                 setState(() => _isLoading = true);

//                 Future.delayed(const Duration(milliseconds: 300), () {
//                   Navigator.pop(context, selected);
//                 });
//               },
//               color: Theme.of(context).colorScheme.secondary,
//               txtcolor: Theme.of(context).colorScheme.onPrimary,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

import 'package:jwt_decode/jwt_decode.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

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
  bool _isLoading = false;
  bool isStaffUser = false;

  String? loginRole;
  String? loginDepartment;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.selectedUsers);
    _initializeUser();
  }

  /// ✅ Get Role + Department from JWT
  Future<void> _initializeUser() async {
    final token = await AuthService.getToken(); // your getToken()
    if (token == null) return;

    loginRole = JwtHelper.getRole(token);

    final decoded = Jwt.parseJwt(token);
    loginDepartment = decoded["Department"]; // make sure department exists in JWT

    _applyRoleBasedFilter();
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

    // ❌ Remove Director always
    users = users.where((u) => u.role != "Director").toList();

    if (loginRole == "Manager") {
      users = users
          .where((u) => u.department == loginDepartment)
          .toList();
    }

    setState(() {
      filteredUsers = users;
    });
  }

  /// ✅ Search
  void applySearch(String query) {
    final text = query.toLowerCase().trim();

    setState(() {
      filteredUsers = filteredUsers.where((user) {
        return user.name.toLowerCase().contains(text) ||
            user.department.toLowerCase().contains(text) ||
            user.role.toLowerCase().contains(text);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isStaffUser) {
      return Scaffold(
        appBar: AppBar(title: const Text("Assign Users")),
        body: const Center(
          child: Text(
            "You can't assign any staff",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search users...",
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
                _applyRoleBasedFilter(); // reset filter
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = selected
                            .any((u) => u.userId == user.userId);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selected.removeWhere(
                                    (u) => u.userId == user.userId);
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
                                  255, 134, 170, 136),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor:
                                        const Color.fromARGB(
                                            255, 50, 99, 49),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selected.add(user);
                                        } else {
                                          selected.removeWhere(
                                              (u) =>
                                                  u.userId ==
                                                  user.userId);
                                        }
                                      });
                                    },
                                  ),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        const Color.fromARGB(
                                            255, 50, 99, 49),
                                    child: Text(
                                      user.name[0].toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user.name),
                                        const SizedBox(height: 3),
                                        Text(
                                          "${user.role} • ${user.department}",
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
              isLoading: _isLoading,
              onPressed: () {
                Navigator.pop(context, selected);
              },
              color:
                  Theme.of(context).colorScheme.secondary,
              txtcolor:
                  Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
} 