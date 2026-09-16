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
  final String departmentName;
  final int departmentId;

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
    this.departmentName = '',
    this.departmentId = 0,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      auditId: _asInt(json['auditId'] ?? json['id'] ?? json['Id']),
      entityType: _firstString(json, ['entityType', 'EntityType']),
      entityId: _firstString(json, ['entityId', 'EntityId']),
      action: _firstString(json, ['action', 'Action']),
      fieldChanged: _firstString(json, ['fieldChanged', 'FieldChanged', 'Fieldchanged']),
      oldValue: _firstString(json, ['oldValue', 'OldValue', 'Oldvalue']),
      newValue: _firstString(json, ['newValue', 'NewValue', 'Newvalue']),
      editedById: _firstString(json, ['editedById', 'editedUid', 'EditedUid']),
      editedByName: _firstString(json, ['editedByName', 'editedName', 'EditedByName']),
      editedRole: _firstString(json, ['editedRole', 'EditedRole']),
      taskCode: _firstString(json, ['taskCode', 'TaskCode']),
      taskName: _firstString(json, [
        'taskName',
        'TaskName',
        'task',
        'Task',
      ]),
      changeDateTime: _parseDate(
        json['changeDateTime'] ??
            json['changeDateAndTime'] ??
            json['ChangeDateAndTime'] ??
            json['ChangeDateandTime'],
      ),
      departmentName: _firstString(json, [
        'departmentName',
        'DepartmentName',
        'department',
        'Department',
      ]),
      departmentId: _asInt(
        json['departmentId'] ?? json['DepartmentId'] ?? json['deptId'],
      ),
    );
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      return text;
    }
    return '';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
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
