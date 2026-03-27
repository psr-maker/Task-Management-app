class TaskModel {
  final String taskCode;
  final int totalTasks;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final String task;
  final String description;
  final String priority;
  final String status;
  final String createdAt;
  final String? dueDate;
  final String? completed_date;
  final int totalMembers;
  final String? assignedBy;
  final String? assignerRole;
  final String? assignerDepartment;
  final List assignedTo;
  final bool wasEdited;
  TaskModel({
    required this.taskCode,
    required this.task,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.dueDate,
    required this.totalMembers,
    required this.assignedTo,
    required this.assignedBy,
    this.assignerRole,
    this.assignerDepartment,
    required this.totalTasks,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.wasEdited,
    this.completed_date,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskCode: json['taskCode'],
      task: json['task'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      createdAt: json['createdAt'],
      dueDate: json['dueDate'],
      totalMembers: json['totalMembers'],
      assignedTo: json['assignedTo'],
      assignerRole: json['assignerRole'],
      assignerDepartment: json['assignerDepartment'],
      assignedBy: json['assignedBy'] as String?,
      totalTasks: json["totalTasks"] ?? 0,
      pendingCount: json["pendingCount"] ?? 0,
      inProgressCount: json["inProgressCount"] ?? 0,
      completedCount: json["completedCount"] ?? 0,
      wasEdited: json["wasEdited"] ?? false,
      completed_date: json['completed_date'],
    );
  }
}

class EditTaskRequest {
  final String taskCode;
  final String task;
  final String description;
  final String priority;
  final DateTime dueDate;
  final List<int> assignedToIds;

  EditTaskRequest({
    required this.taskCode,
    required this.task,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.assignedToIds,
  });

  Map<String, dynamic> toJson() {
    return {
      "taskCode": taskCode,
      "task": task,
      "description": description,
      "priority": priority,
      "due_Date": dueDate.toIso8601String(),
      "assignedToIds": assignedToIds,
    };
  }
}
