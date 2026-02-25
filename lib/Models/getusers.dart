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

factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    userId: json['userId'] ?? json['id'] ?? 0,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    department: json['department'] ?? '',
    role: json['role'] ?? '',
    status: json['status'] ?? '',
    createdBy: json['createdBy'] ?? json['created_by'] ?? '', 
    wasEdited: json['wasEdited'] ?? false,
  );
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
      role: admin['role'],
      department: admin['department'],
      createdBy: admin['created_by'],
      status: admin['status'],
      totalEmployees: json['totalEmployees'],
      totalTasksAssignedTo: json['totalTasksAssignedTo'],
      totalTasksAssignedBy: json['totalTasksAssignedBy'], 
      wasEdited: admin['wasEdited'] ?? false,
    );
  }
}
