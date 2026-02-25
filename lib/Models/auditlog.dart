class AuditLogModel {
  final int auditId;
  final String entityType;
  final String entityId;
  final String action;
  final String? fieldChanged;
  final String? oldValue;
  final String? newValue;
  final String editedById;
  final String editedByName;
  final String editedRole;
  final String? taskCode;
  final String? taskName;
  final DateTime changeDateTime;

  AuditLogModel({
    required this.auditId,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.fieldChanged,
    this.oldValue,
    this.newValue,
    required this.editedById,
    required this.editedByName,
    required this.editedRole,
    this.taskCode,
    this.taskName,
    required this.changeDateTime,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      auditId: json['auditId'],
      entityType: json['entityType'] ?? "",
      entityId: json['entityId']?.toString() ?? "",
      action: json['action'] ?? "",
      fieldChanged: json['fieldChanged'],
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      editedById: json['editedById']?.toString() ?? "",
      editedByName: json['editedByName'] ?? "",
      editedRole: json['editedRole'] ?? "",
      taskCode: json['taskCode'],
      taskName: json['taskName'],
      changeDateTime: DateTime.parse(json['changeDateTime']),
    );
  }
}


class AuditLogGroupModel {
  final String entityType;
  final String entityId;
  final String action;
  final String editedByName;
  final String editedRole;
  final String department;
  final String? taskCode;
  final String? taskName;
  final DateTime dateTime;
  final List<AuditLogModel> changes;

  AuditLogGroupModel({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.editedByName,
    required this.editedRole,
    required this.department,
    this.taskCode,
    this.taskName,
    required this.dateTime,
    required this.changes,
  });
}
