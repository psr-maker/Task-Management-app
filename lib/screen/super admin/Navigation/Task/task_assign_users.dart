import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/role_hierarchy.dart';
import 'package:staff_work_track/widgets/staff_picker.dart';

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
  List<Role> roles = [];

  bool isLoading = false;

  String? loginRole;
  String? loginDepartment;
  int? loginUserId;
  int? loginRolePosition;

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

      loginRolePosition = rolePosition(roles, loginRole);
      await _resolveLoginDepartment();
      await _loadUsersForPosition();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
    var users = await _loadDepartmentUsers();
    users = users
        .where((user) => user.status.toLowerCase() != "inactive")
        .toList();
    users = _applyHierarchy(_uniqueUsers(users));
    users = await _ensureLoginUser(users);
    users.sort((a, b) {
      if (a.userId == loginUserId) return -1;
      if (b.userId == loginUserId) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    if (!mounted) return;
    setState(() {
      allowedUsers = users;
    });
  }

  Future<List<UserModel>> _ensureLoginUser(List<UserModel> users) async {
    if (loginUserId == null) return users;
    // Division heads assign only managers — do not force-add themselves.
    if (AppRoles.isDivisionHead(loginRole, roles)) return users;
    if (users.any((user) => user.userId == loginUserId)) return users;

    try {
      final details = await SuperAdminService.getAdminDetails(loginUserId!);
      return [
        UserModel(
          userId: details.userId,
          name: details.name,
          email: details.email,
          department: details.department,
          role: details.role,
          status: details.status,
          createdBy: details.createdBy,
          wasEdited: details.wasEdited,
        ),
        ...users,
      ];
    } catch (_) {
      return users;
    }
  }

  List<UserModel> _applyHierarchy(List<UserModel> users) {
    return users
        .where(
          (user) => canAssignUser(
            loginPosition: loginRolePosition,
            user: user,
            roles: roles,
            loginUserId: loginUserId,
            loginRole: loginRole,
          ),
        )
        .toList();
  }

  Future<List<UserModel>> _loadDepartmentUsers() async {
    final department = loginDepartment?.trim() ?? '';
    final allowedDepartments = await AdminService.assignmentDepartments(
      role: loginRole,
      ownDepartment: department,
    );
    List<UserModel> users = [];
    Map<int, String> names = {};
    try {
      final allUsers = await SuperAdminService.getAllUsers();
      for (final user in allUsers) {
        final name = user.displayName;
        if (user.userId > 0 && name.isNotEmpty) names[user.userId] = name;
      }
      if (allowedDepartments.isEmpty) users = allUsers;
    } catch (_) {}

    if (allowedDepartments.isNotEmpty) {
      try {
        users = await AdminService.getEmployeesByDepartments(allowedDepartments);
      } catch (_) {}

      if (users.isEmpty) {
        users = names.isEmpty ? List<UserModel>.from(widget.users) : users;
        if (users.isEmpty) {
          try {
            users = await SuperAdminService.getAllUsers();
          } catch (_) {
            users = List.from(widget.users);
          }
        }
        users = users
            .where(
              (user) =>
                  user.department.trim().isEmpty ||
                  DivisionConfig.isAllowedDepartment(
                    user.department,
                    allowedDepartments,
                  ),
            )
            .toList();
      }
    }

    return users.map((user) {
      final known = names[user.userId];
      if (user.displayName.isNotEmpty || known == null) return user;
      return UserModel(
        userId: user.userId,
        name: known,
        email: user.email,
        department: user.department,
        role: user.role,
        status: user.status,
        createdBy: user.createdBy,
        wasEdited: user.wasEdited,
      );
    }).toList();
  }

  List<UserModel> _uniqueUsers(List<UserModel> users) {
    final unique = <int, UserModel>{};
    for (final user in users) {
      unique[user.userId] = user;
    }
    return unique.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final popup = !AppLayout.isMobile(context);
    return Scaffold(
      appBar: popup
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Assign users"),
            ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : StaffPicker(
              users: allowedUsers,
              selectedIds: selected.map((user) => user.userId).toSet(),
              title: "Assign users",
              onDone: (ids) {
                final picked = allowedUsers
                    .where((user) => ids.contains(user.userId))
                    .toList();
                Navigator.pop(context, picked);
              },
            ),
    );
  }
}
