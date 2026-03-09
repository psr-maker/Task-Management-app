import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/screen/admin/Navigation/my work/mywork.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/worklog.dart';
import 'package:staff_work_track/screen/staff/navigation/anouncement.dart';
import 'package:staff_work_track/core/widgets/curved_bottom_nav.dart';

class Staff extends StatefulWidget {
  const Staff({super.key});

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  int _currentIndex = 0;

  int? userId;
  String username = "";
  String role = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final token = await AuthService.getToken();

    if (token == null) return;

    final decodedToken = JwtDecoder.decode(token);

    int id = int.parse(decodedToken['UserId'].toString());
    String userRole = decodedToken['Role'].toString();

    setState(() {
      userId = id;
      role = userRole;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      StaffDashboard(userid: userId!, role: role),
      const Mywork(),
      const Worklog(),
      const Anouncestaff()
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: CurvedBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        role: UserRole.staff,
      ),
    );
  }
}
