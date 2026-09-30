import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/adaptive_app_shell.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/Reports.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/dahboard.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/Userstasklist.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/users/Users.dart';

class SuperAdmin extends StatefulWidget {
  const SuperAdmin({super.key});

  @override
  State<SuperAdmin> createState() => _SuperadminState();
}

class _SuperadminState extends State<SuperAdmin> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SuperAdminDashboard(),
    const Usersview(),
    const UsersTasklist(),
    Reports(),
  ];
  @override
  Widget build(BuildContext context) {
    return AdaptiveAppShell(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      role: UserRole.superAdmin,
      pages: _pages,
    );
  }
}
