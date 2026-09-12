class Role {
  final int id;
  final String name;
  final int position;
  final bool status;

  Role({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? json['roleId'] ?? 0,
      name: json['roleName'] ?? json['name'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Role && other.id == id;

  @override
  int get hashCode => id.hashCode;
}