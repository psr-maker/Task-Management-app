import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/dashboard.dart';

/// The same department dashboard a manager opens for this department.
class DepartmentDashboardPage extends StatelessWidget {
  final String department;

  const DepartmentDashboardPage({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return AdminDashboard(
      department: department,
      role: AppRoles.manager,
      mngId: 0,
      onBack: () => Navigator.pop(context),
    );
  }
}
