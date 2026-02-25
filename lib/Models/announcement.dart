class Announcement {
  final int id;
  final String title;
  final String? description;
  final String fileType;
  final String? filePath;
  final String? fileName; 
  final String? jsonData;
  final String createdBy;
  final DateTime createdDate;

  Announcement({
    required this.id,
    required this.title,
    this.description,
    required this.fileType,
    this.filePath,
    this.fileName, 
    this.jsonData,
    required this.createdBy,
    required this.createdDate,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      fileType: json['fileType'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      jsonData: json['jsonData'],
      createdBy: json['createdBy'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}