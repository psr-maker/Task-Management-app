import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/constant/role_catalog.dart';

class AppRoles {
  static const int directorPosition = 1;
  static const int divisionHeadPosition = 2;
  static const int managerPosition = 3;

  static const String director = '1';
  static const String divisionHead = '2';
  static const String manager = '3';
  static const String fiveS = '50';

  static int? positionOf(String? role, [List<Role>? roles]) {
    final list = roles ?? RoleCatalog.roles;
    final found = RoleCatalog.find(role, list);
    if (found != null && found.position > 0) return found.position;

    final parsed = int.tryParse((role ?? '').trim());
    if (parsed == null || parsed <= 0) return null;
    if (list.isEmpty || list.any((item) => item.position == parsed)) {
      return parsed;
    }
    return null;
  }

  static bool isDirector(String? role, [List<Role>? roles]) =>
      positionOf(role, roles) == directorPosition;

  static bool isDivisionHead(String? role, [List<Role>? roles]) =>
      positionOf(role, roles) == divisionHeadPosition;

  static bool isManager(String? role, [List<Role>? roles]) =>
      positionOf(role, roles) == managerPosition;

  static bool isFiveS(String? role, [List<Role>? roles]) {
    final value = (role ?? '').trim();
    if (value == fiveS) return true;
    final found = RoleCatalog.find(role, roles ?? RoleCatalog.roles);
    return found != null && found.id.toString() == fiveS;
  }

  static bool isAssistantManager(String? role) {
    if (role == null) return false;
    final lower = role.trim().toLowerCase();
    return lower.contains('assistant') && lower.contains('manager');
  }

  static bool shouldHideOvertime(String? role) {
    return isManager(role) || isAssistantManager(role);
  }

  static bool isScoreLeader(String? role, [List<Role>? roles]) {
    return isDivisionHead(role, roles) || isManager(role, roles);
  }

  /// Current name of this user's role. Empty when it cannot be resolved.
  static String displayName(
    String? role, {
    List<Role>? roles,
    String fallback = '',
  }) {
    final list = roles ?? RoleCatalog.roles;
    final found = RoleCatalog.find(role, list);
    if (found != null && found.name.trim().isNotEmpty) {
      return found.name.trim();
    }

    final position = positionOf(role, list);
    if (position != null) {
      final named = RoleCatalog.nameForPosition(position, list);
      if (named.isNotEmpty) return named;
    }

    final raw = role?.trim() ?? '';
    if (raw.isEmpty || int.tryParse(raw) != null) return fallback;
    return raw;
  }

  static String nameForPosition(
    int position, {
    List<Role>? roles,
    String fallback = '',
  }) {
    final name = RoleCatalog.nameForPosition(
      position,
      roles ?? RoleCatalog.roles,
    );
    return name.isEmpty ? fallback : name;
  }

  static String leaderLabel(String? role, [List<Role>? roles]) {
    if (!isScoreLeader(role, roles)) return '';
    return displayName(role, roles: roles);
  }
}

class DivisionConfig {
  static String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+department$'), '')
        .trim();
  }

  static bool isAllowedDepartment(String? department, List<String> allowed) {
    if (department == null || department.trim().isEmpty) return false;
    final key = normalize(department);
    return allowed.any((item) => normalize(item) == key);
  }
}
