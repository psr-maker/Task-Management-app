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
       
        departmentName: json['departmentName'],
        subDepartment: json['subDepartment'],
        zone: json['zone'],
      );

  Map<String, dynamic> toJson() => {
    
        'departmentName': departmentName,
        'subDepartment': subDepartment,
        'zone': zone,
      };

  void operator [](String other) {}
}