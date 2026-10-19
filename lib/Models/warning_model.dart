import 'package:staff_work_track/core/constant/division_config.dart';

class WarningModel {
  final int id;
  final int senderId;
  final int receiverId;

  final String senderName;
  final String senderRole;
  final String receiverName;
  final String receiverRole;

  final String title;
  final String message;
  final String severity;
  final int escalationLevel;
  final DateTime createdDate;
  final bool isRead;
  final String senderDept;
  final String receiverDept;

  WarningModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderRole,
    required this.receiverName,
    required this.receiverRole,
    required this.title,
    required this.message,
    required this.severity,
    required this.escalationLevel,
    required this.createdDate,
    required this.isRead,
    this.senderDept = '',
    this.receiverDept = '',
  });

  factory WarningModel.fromJson(Map<String, dynamic> json) {
    return WarningModel(
      id: _asInt(json['warningId'] ?? json['WarningId'] ?? json['id'] ?? json['Id']),
      senderId: _asInt(json['senderId'] ?? json['SenderId']),
      receiverId: _asInt(json['receiverId'] ?? json['ReceiverId']),
      senderName: (json['senderName'] ?? json['SenderName'] ?? '').toString(),
      senderRole: (json['senderRole'] ?? json['SenderRole'] ?? '').toString(),
      receiverName: (json['receiverName'] ?? json['ReceiverName'] ?? '').toString(),
      receiverRole: (json['receiverRole'] ?? json['ReceiverRole'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      severity: (json['severity'] ?? json['Severity'] ?? '').toString(),
      escalationLevel: _asInt(json['escalationLevel'] ?? json['EscalationLevel']),
      createdDate: DateTime.tryParse(
            (json['createdDate'] ?? json['CreatedDate'] ?? '').toString(),
          ) ??
          DateTime.now(),
      isRead: json['isRead'] == true || json['IsRead'] == true,
      senderDept: (json['senderDept'] ?? json['SenderDept'] ?? '').toString(),
      receiverDept: (json['receiverDept'] ?? json['ReceiverDept'] ?? '').toString(),
    );
  }

  bool belongsToDepartment(String department) {
    return DivisionConfig.isAllowedDepartment(receiverDept, [department]);
  }

  bool belongsToUser(int userId, {String name = ''}) {
    if (userId > 0 && receiverId == userId) return true;
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return false;
    final value = receiverName.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == wanted) return true;
    String tail(String text) {
      return text.contains('-') ? text.split('-').last.trim() : text;
    }

    final valueTail = tail(value);
    final wantedTail = tail(wanted);
    return valueTail.isNotEmpty &&
        (valueTail == wantedTail || value == wantedTail || valueTail == wanted);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}