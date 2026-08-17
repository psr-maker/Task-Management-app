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
      id: json['id'] ?? 0,
      name: json['roleName'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'] ?? false,
    );
  }
}