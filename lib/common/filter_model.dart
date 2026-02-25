class TaskFilterModel {
  String? status;
  String? priority;
  String? department;
  String? assignedTo;
    String? role; // Add this


  TaskFilterModel({
    this.status,
    this.priority,
    this.department,
    this.assignedTo,
      this.role

  });

  bool get hasFilter =>
      status != null ||
      priority != null ||
      department != null ||
      assignedTo != null||
      role != null;

  void clear() {
    status = null;
    priority = null;
    department = null;
    assignedTo = null;
    role=null;
  }
}
