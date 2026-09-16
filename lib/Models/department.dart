class Department {
  int? id;
  String departmentName;
  String? subDepartment;
  String? zone;

  Department({
    this.id,
    required this.departmentName,
    this.subDepartment,
    this.zone,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: json['id'] ?? json['Id'],
        departmentName:
            (json['departmentName'] ?? json['DepartmentName'] ?? '').toString(),
        subDepartment: json['subDepartment'] ?? json['SubDepartment'],
        zone: json['zone'] ?? json['Zone'],
      );

  Map<String, dynamic> toJson() => {
    
        'departmentName': departmentName,
        'subDepartment': subDepartment,
        'zone': zone,
      };

  void operator [](String other) {}
}