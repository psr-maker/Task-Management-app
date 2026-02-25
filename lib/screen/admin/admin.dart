import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/worklog.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/dashboard.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/employee.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/mywork.dart';
import 'package:staff_work_track/core/widgets/curved_bottom_nav.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int _currentIndex = 0;
  String department = "";
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadAdminDepartment();
  }

  Future<int> getAdminIdFromToken() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final decodedToken = JwtDecoder.decode(token);

    return int.parse(decodedToken['UserId'].toString());
  }

  Future<void> loadAdminDepartment() async {
    try {
      final adminId = await getAdminIdFromToken();
      final adminDetails = await SuperAdminService.getAdminDetails(adminId);

      if (!mounted) return;

      setState(() {
        department = adminDetails.department;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      isLoading = false;
    }
  }

@override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final pages = [
    AdminDashboard(department: department),
    const Employeelist(),
    const Mywork(),
    const Worklog(),
  ];

  return Scaffold(
    body: pages[_currentIndex],
    bottomNavigationBar: CurvedBottomNav(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      role: UserRole.admin,
    ),
  );
}
}