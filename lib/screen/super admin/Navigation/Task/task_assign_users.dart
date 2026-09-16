import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class AssignUsersPage extends StatefulWidget {
  final List<UserModel> users;
  final List<UserModel> selectedUsers;

  const AssignUsersPage({
    super.key,
    this.users = const [],
    required this.selectedUsers,
  });

  @override
  State<AssignUsersPage> createState() => _AssignUsersPageState();
}

class _AssignUsersPageState extends State<AssignUsersPage> {
  late List<UserModel> selected;
  List<UserModel> allowedUsers = [];
  List<UserModel> filteredUsers = [];
  List<Role> roles = [];

  bool isSearching = false;
  bool isLoading = false;

  String? loginRole;
  String? loginDepartment;
  int? loginUserId;
  int? loginRolePosition;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.selectedUsers);
    initUserData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> initUserData() async {
    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      loginRole = JwtHelper.getRole(token);
      loginUserId = int.tryParse(JwtHelper.getuid(token)?.toString() ?? '');
      final decoded = Jwt.parseJwt(token);
      loginDepartment = (JwtHelper.getDepartment(token) ??
              decoded['department'] ??
              decoded['Department'] ??
              '')
          .toString()
          .trim();
      if (loginDepartment!.isEmpty) loginDepartment = null;

      try {
        roles = await SuperAdminService.getRoles();
      } catch (_) {
        roles = [];
      }

      loginRolePosition = _resolveLoginPosition();
      await _resolveLoginDepartment();
      await _loadUsersForPosition();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  int? _resolveLoginPosition() {
    final fromRoles = _getRolePosition(loginRole);
    if (fromRoles != null && fromRoles > 0) return fromRoles;

    final parsed = int.tryParse((loginRole ?? '').trim());
    if (parsed != null) return parsed;

    if (AppRoles.isManager(loginRole)) return 3;
    if (AppRoles.isDivisionHead(loginRole)) return 2;
    final lower = (loginRole ?? '').toLowerCase();
    if (lower == 'director' || loginRole == AppRoles.director) return 1;
    return null;
  }

  Future<void> _resolveLoginDepartment() async {
    if (loginDepartment != null && loginDepartment!.isNotEmpty) return;

    if (loginUserId != null) {
      for (final user in widget.users) {
        if (user.userId == loginUserId && user.department.trim().isNotEmpty) {
          loginDepartment = user.department.trim();
          return;
        }
      }

      try {
        final details = await SuperAdminService.getAdminDetails(loginUserId!);
        if (details.department.trim().isNotEmpty) {
          loginDepartment = details.department.trim();
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _loadUsersForPosition() async {
    List<UserModel> users = List.from(widget.users);

    if (loginRolePosition == 1) {
      try {
        users = await SuperAdminService.getAllUsers();
      } catch (_) {}
    } else if (loginRolePosition == 2) {
      final allowedDepartments = <String>{
        if (loginDepartment != null && loginDepartment!.isNotEmpty)
          loginDepartment!,
        ...DivisionConfig.childDepartments(loginDepartment),
      }.toList();

      if (allowedDepartments.isNotEmpty) {
        users = await AdminService.getEmployeesByDepartments(allowedDepartments);
      }

      if (users.isEmpty) {
        try {
          final allUsers = await SuperAdminService.getAllUsers();
          users = allUsers
              .where(
                (user) => DivisionConfig.isAllowedDepartment(
                  user.department,
                  allowedDepartments,
                ),
              )
              .toList();
        } catch (_) {}
      }
    } else {
      users = await _loadDepartmentUsers();
    }

    users = _applyHierarchy(_uniqueUsers(users));

    if (!mounted) return;
    setState(() {
      allowedUsers = users;
      filteredUsers = users;
    });
  }

  List<UserModel> _applyHierarchy(List<UserModel> users) {
    final loginPosition = loginRolePosition;
    if (loginPosition == null) return [];

    return users.where((user) {
      if (loginUserId != null && user.userId == loginUserId) return false;

      final position = _positionForUser(user);
      if (position == null) return false;

      return position >= loginPosition;
    }).toList();
  }

  int? _positionForUser(UserModel user) {
    final roleMeta = _roleForUser(user);
    if (roleMeta != null && roleMeta.position > 0) return roleMeta.position;

    final parsed = int.tryParse(user.role.trim());
    if (parsed != null && parsed > 0) {
      for (final role in roles) {
        if (role.id == parsed) return role.position;
      }
    }
    return null;
  }

  Future<List<UserModel>> _loadDepartmentUsers() async {
    final department = loginDepartment?.trim() ?? '';
    if (department.isEmpty) return [];

    List<UserModel> users = [];
    try {
      users = await AdminService.getEmployeesByDepartment(department);
    } catch (_) {}

    if (users.isEmpty) {
      try {
        users = await SuperAdminService.getAllUsers();
      } catch (_) {
        users = List.from(widget.users);
      }
    }

    return users
        .where(
          (user) => DivisionConfig.isAllowedDepartment(user.department, [
            department,
          ]),
        )
        .toList();
  }

  List<UserModel> _uniqueUsers(List<UserModel> users) {
    final unique = <int, UserModel>{};
    for (final user in users) {
      unique[user.userId] = user;
    }
    return unique.values.toList();
  }

  int? _getRolePosition(String? roleValue) {
    if (roleValue == null || roleValue.isEmpty) return null;

    final roleId = int.tryParse(roleValue);
    if (roleId != null) {
      for (final role in roles) {
        if (role.id == roleId) return role.position;
      }
    }

    for (final role in roles) {
      if (role.name.toLowerCase() == roleValue.toLowerCase()) {
        return role.position;
      }
    }

    return null;
  }

  Role? _roleForUser(UserModel user) {
    if (user.role.isEmpty) return null;

    final roleId = int.tryParse(user.role);
    if (roleId != null) {
      for (final role in roles) {
        if (role.id == roleId) return role;
      }
    }

    for (final role in roles) {
      if (role.name.toLowerCase() == user.role.toLowerCase()) {
        return role;
      }
    }

    return null;
  }

  void applySearch(String query) {
    final text = query.toLowerCase().trim();

    setState(() {
      filteredUsers = allowedUsers.where((user) {
        final roleMeta = _roleForUser(user);
        final roleLabel = roleMeta != null ? roleMeta.name : user.role;
        return user.name.toLowerCase().contains(text) ||
            user.department.toLowerCase().contains(text) ||
            roleLabel.toLowerCase().contains(text);
      }).toList();
    });
  }

  bool get _isDepartmentScoped =>
      loginRolePosition != null && loginRolePosition != 1;

  String get _title {
    if (_isDepartmentScoped && loginDepartment != null) {
      return "Assign Users (${allowedUsers.length} in ${loginDepartment!.replaceAll(" Department", "")})";
    }
    return "Assign Users (${selected.length})";
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
                  hintText: "Search users...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: applySearch,
              )
            : Text(_title),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                filteredUsers = allowedUsers;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            if (_isDepartmentScoped && loginDepartment != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${allowedUsers.length} users in $loginDepartment",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        _isDepartmentScoped
                            ? "No users found in ${loginDepartment ?? "your department"}"
                            : "No users found",
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = selected.any(
                          (u) => u.userId == user.userId,
                        );
                        final roleMeta = _roleForUser(user);
                        final roleLabel = roleMeta != null
                            ? roleMeta.name
                            : user.role;

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
                              color: const Color.fromARGB(255, 134, 170, 136),
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
                                          "$roleLabel - ${user.department}",
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
        ),
      ),
    );
  }
}
