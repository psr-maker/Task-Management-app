import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

int? rolePosition(List<Role> roles, String? roleValue) {
  return AppRoles.positionOf(roleValue, roles);
}

bool skipsOvertime(List<Role> roles, String? roleValue) {
  final position = _listedPosition(roles, roleValue);
  return position != null && position >= 1 && position <= 5;
}

int? _listedPosition(List<Role> roles, String? roleValue) {
  if (roleValue == null || roleValue.trim().isEmpty) return null;
  final value = roleValue.trim();
  final roleId = int.tryParse(value);

  if (roleId != null) {
    for (final role in roles) {
      if (role.id == roleId && role.position > 0) return role.position;
    }
  }

  for (final role in roles) {
    if (role.name.toLowerCase() == value.toLowerCase() && role.position > 0) {
      return role.position;
    }
  }
  return null;
}

class OvertimeEligibility {
  final Set<int> excludedUserIds;
  final Set<String> excludedNames;

  const OvertimeEligibility(this.excludedUserIds, this.excludedNames);

  bool excludesUser(UserModel user) => excludedUserIds.contains(user.userId);

  bool excludesRecord(Map item) {
    for (final key in ['uid', 'userId', 'staffId', 'employeeId']) {
      final id = int.tryParse('${item[key] ?? ''}');
      if (id != null && id > 0) return excludedUserIds.contains(id);
    }
    final name = (item['staffName'] ?? item['name'] ?? item['userName'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return name.isNotEmpty && excludedNames.contains(name);
  }
}

Future<OvertimeEligibility> loadOvertimeEligibility() async {
  final roles = await SuperAdminService.getRoles();
  final users = await SuperAdminService.getAllUsers();
  final ids = <int>{};
  final names = <String>{};
  for (final user in users) {
    if (!skipsOvertime(roles, user.role)) continue;
    ids.add(user.userId);
    final name = user.name.trim().toLowerCase();
    if (name.isNotEmpty) names.add(name);
  }
  return OvertimeEligibility(ids, names);
}

bool canAssignUser({
  required int? loginPosition,
  required UserModel user,
  required List<Role> roles,
  int? loginUserId,
  String? loginRole,
}) {
  if (loginUserId != null && user.userId == loginUserId) return true;
  // Division heads may assign only to department managers under them.
  if (AppRoles.isDivisionHead(loginRole, roles)) {
    return AppRoles.isManager(user.role, roles);
  }

  if (loginPosition == null) return false;
  final position = rolePosition(roles, user.role);
  if (position == null) return false;
  return position >= loginPosition;
}

/// Leadership roles a yearly goal can be assigned to.
/// Lower position number is a higher role: director, division head, manager.
bool isHierarchyLevelRole(List<Role> roles, String? roleValue) {
  final position = rolePosition(roles, roleValue);
  return position != null &&
      position >= AppRoles.directorPosition &&
      position <= AppRoles.managerPosition;
}

Future<List<UserModel>> keepAssignableUsers(List<UserModel> users) async {
  final token = await AuthService.getToken();
  final loginRole = token == null ? null : JwtHelper.getRole(token);
  final loginUserId = int.tryParse(
    (token == null ? null : JwtHelper.getuid(token))?.toString() ?? '',
  );
  List<Role> roles = [];
  try {
    roles = await SuperAdminService.getRoles();
  } catch (_) {}
  final loginPosition = rolePosition(roles, loginRole);
  return users
      .where(
        (user) => canAssignUser(
          loginPosition: loginPosition,
          user: user,
          roles: roles,
          loginUserId: loginUserId,
          loginRole: loginRole,
        ),
      )
      .toList();
}
