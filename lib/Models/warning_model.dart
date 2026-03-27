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
  });

  factory WarningModel.fromJson(Map<String, dynamic> json) {
    return WarningModel(
      id: json['warningId'], // make sure matches backend
      senderId: json['senderId'],
      receiverId: json['receiverId'],

      senderName: json['senderName'] ?? "",
      senderRole: json['senderRole'] ?? "",
      receiverName: json['receiverName'] ?? "",
      receiverRole: json['receiverRole'] ?? "",

      title: json['title'] ?? "",
      message: json['message'] ?? "",
      severity: json['severity'] ?? "",
      escalationLevel: json['escalationLevel'] ?? 0,
      createdDate: DateTime.parse(json['createdDate']),
      isRead: json['isRead'] ?? false,
    );
  }
}