import 'package:flutter/material.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/mywork.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/worklog.dart';
import 'package:staff_work_track/core/widgets/curved_bottom_nav.dart';

class Staff extends StatefulWidget {
  const Staff({super.key});

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StaffDashboard(userid: 3, username: 'Myona', role: 'Staff',),
    const Mywork(),
    const Worklog(),
    const Worklog(), 
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        role: UserRole.staff,
      ),
    );
  }
}
