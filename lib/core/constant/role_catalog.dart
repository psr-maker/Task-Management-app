import 'package:staff_work_track/Models/rolesmodel.dart';

/// Roles loaded from the server. Checks use [Role.position].
/// Labels use [Role.name], so renaming a role does not change access.
class RoleCatalog {
  static List<Role> _roles = const [];

  static List<Role> get roles => _roles;

  static void replace(List<Role> roles) {
    _roles = List<Role>.from(roles);
  }

  /// Match a stored user role by id, then by the role's current name.
  static Role? find(String? value, [List<Role>? roles]) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final list = roles ?? _roles;

    final id = int.tryParse(raw);
    if (id != null) {
      for (final role in list) {
        if (role.id == id) return role;
      }
      return null;
    }

    final lower = raw.toLowerCase();
    for (final role in list) {
      if (role.name.trim().toLowerCase() == lower) return role;
    }
    return null;
  }

  static String nameForPosition(int position, List<Role> roles) {
    Role? inactive;
    for (final role in roles) {
      if (role.position != position || role.name.trim().isEmpty) continue;
      if (role.status) return role.name.trim();
      inactive ??= role;
    }
    return inactive?.name.trim() ?? '';
  }
}
