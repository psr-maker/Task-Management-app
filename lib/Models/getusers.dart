class UserModel {
  final int userId;
  final String name;
  final String email;
  final String department;
  final String role;
  final String status;
  final String createdBy;
  final bool wasEdited;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.status,
    required this.createdBy,
    required this.wasEdited,
  });

  String get displayName {
    final text = name.trim();
    if (text.contains('-')) {
      final rest = text.split('-').skip(1).join('-').trim();
      if (rest.isNotEmpty && int.tryParse(rest) == null) return rest;
    }
    if (text.isEmpty || text == '$userId') return '';
    return text;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final source = _flattenUser(json);
    return UserModel(
      userId: _readId(source),
      name: _readName(source),
      email: (source['email'] ?? source['Email'] ?? '').toString(),
      department: (source['department'] ??
              source['Department'] ??
              source['departmentName'] ??
              source['DepartmentName'] ??
              '')
          .toString(),
      role: (source['role'] ??
              source['Role'] ??
              source['roleId'] ??
              source['roleName'] ??
              source['RoleName'] ??
              '')
          .toString(),
      status: (source['status'] ?? source['Status'] ?? '').toString(),
      createdBy: (source['createdBy'] ??
              source['CreatedBy'] ??
              source['created_by'] ??
              '')
          .toString(),
      wasEdited: source['wasEdited'] ?? source['WasEdited'] ?? false,
    );
  }

  static Map<String, dynamic> _flattenUser(Map<String, dynamic> json) {
    final merged = <String, dynamic>{};
    for (final key in ['user', 'User', 'staff', 'Staff', 'employee', 'Employee']) {
      final nested = json[key];
      if (nested is Map) {
        merged.addAll(Map<String, dynamic>.from(nested));
      }
    }
    merged.addAll(json);
    return merged;
  }

  static int _readId(Map<String, dynamic> json) {
    for (final key in [
      'userId',
      'UserId',
      'id',
      'Id',
      'staffId',
      'StaffId',
      'employeeId',
      'EmployeeId',
    ]) {
      final value = json[key];
      if (value is int && value > 0) return value;
      final parsed = int.tryParse('${value ?? ''}');
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  static String _readName(Map<String, dynamic> json) {
    for (final key in [
      'name',
      'Name',
      'staffName',
      'StaffName',
      'userName',
      'UserName',
      'fullName',
      'FullName',
      'employeeName',
      'EmployeeName',
    ]) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }
}


class UsersDetails {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String department;
  final String createdBy;
  final String status;
  final int totalEmployees;
  final int totalTasksAssignedTo;
  final int totalTasksAssignedBy;
  final bool wasEdited; 

  UsersDetails({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.createdBy,
    required this.status,
    required this.totalEmployees,
    required this.totalTasksAssignedTo,
    required this.totalTasksAssignedBy, 
    required this.wasEdited,
  });

  factory UsersDetails.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'];

    return UsersDetails(
      userId: admin['userId'],
      name: admin['name'],
      email: admin['email'],
      role: (admin['role'] ?? admin['Role'] ?? admin['roleId'] ?? '').toString(),
      department: admin['department'] ?? '',
      createdBy: admin['created_by'] ?? admin['createdBy'] ?? '',
      status: admin['status'] ?? '',
      totalEmployees: json['totalEmployees'],
      totalTasksAssignedTo: json['totalTasksAssignedTo'],
      totalTasksAssignedBy: json['totalTasksAssignedBy'], 
      wasEdited: admin['wasEdited'] ?? false,
    );
  }
}
