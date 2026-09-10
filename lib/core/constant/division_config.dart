class AppRoles {
  static const String director = "1";
  static const String manager = "3";
  static const String divisionHead = "2";
  static const String fiveS = "50";

  static bool isDivisionHead(String? role) {
    if (role == null) return false;
    final value = role.trim();
    if (value == divisionHead) return true;
    final lower = value.toLowerCase();
    return lower.contains("division") && lower.contains("head");
  }
}

class DivisionConfig {
  static const Map<String, List<String>> childDepartmentsByParent = {
    "Operations Department": [
      "Production Department",
      "IT Department",
      "Purchase Department",
      "Quality Department",
      "Store Department",
    ],
  };

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+department$'), '')
        .trim();
  }

  static List<String> childDepartments(String? department) {
    if (department == null || department.trim().isEmpty) return [];

    final key = _normalize(department);
    for (final entry in childDepartmentsByParent.entries) {
      if (_normalize(entry.key) == key) {
        return List<String>.from(entry.value);
      }
    }
    return [];
  }

  static bool isAllowedDepartment(String? department, List<String> allowed) {
    if (department == null || department.trim().isEmpty) return false;
    final key = _normalize(department);
    return allowed.any((item) => _normalize(item) == key);
  }
}
