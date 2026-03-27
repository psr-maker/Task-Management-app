class ReportTask {
  final int userId;
  final String name;
  final String department;
  final String role;

  final String taskCode;
  final String task;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? completedDate;
  final int members;
  final String assignBy;
  final bool isOverdue;

  ReportTask({
    required this.userId,
    required this.name,
    required this.department,
    required this.role,
    required this.taskCode,
    required this.task, 
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.dueDate,
    required this.completedDate,
    required this.members,
    required this.assignBy,
    required this.isOverdue,
  });

  factory ReportTask.fromJson(Map<String, dynamic> json) {
    return ReportTask(
      userId: json['userId'] ?? 0,
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      role: json['role'] ?? '',
      taskCode: json['taskCode'] ?? '',
      task: json['task'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      createdAt: json['created_At'] != null
          ? DateTime.parse(json['created_At'])
          : DateTime.now(),
      dueDate: json['due_Date'] != null
          ? DateTime.parse(json['due_Date'])
          : DateTime.now(),
      completedDate: json['completed_Date'] != null
          ? DateTime.parse(json['completed_Date'])
          : null,
      members: json['members'] ?? 0,
      assignBy: json['assign_By'] ?? '',
      isOverdue: json['isOverdue'] ?? false,
    );
  }
}

class MonthlyData {
  final int month;
  final int progress;

  MonthlyData({required this.month, required this.progress});
}
