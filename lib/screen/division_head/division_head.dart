import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:staff_work_track/core/widgets/curved_bottom_nav.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/my%20work/mywork.dart';
import 'package:staff_work_track/screen/division_head/div_dashboard.dart';
import 'package:staff_work_track/screen/division_head/div_users.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/worklog.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class DivisionHead extends StatefulWidget {
  const DivisionHead({super.key});

  @override
  State<DivisionHead> createState() => _DivisionHeadState();
}

class _DivisionHeadState extends State<DivisionHead> {
  int _currentIndex = 0;
  String department = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token not found");
      }

      final decodedToken = JwtDecoder.decode(token);
      final id = int.parse(decodedToken['UserId'].toString());

      String dept = JwtHelper.getDepartment(token) ?? "";
      try {
        final details = await SuperAdminService.getAdminDetails(id);
        dept = details.department;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        department = dept;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: RotatingFlower()));
    }

    final pages = [
      DivDashboard(department: department),
      DivUsers(department: department),
      const Mywork(),
      const Worklog(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: CurvedBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          role: UserRole.divisionHead,
        ),
      ),
    );
  }
}
