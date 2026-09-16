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
      id: _asInt(json['id'] ?? json['roleId']),
      name: json['roleName'] ?? json['name'] ?? '',
      position: _asInt(json['position']),
      status: json['status'] == true || json['status'] == 'true',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Role && other.id == id;

  @override
  int get hashCode => id.hashCode;
}