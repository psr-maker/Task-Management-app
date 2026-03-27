import 'package:flutter/material.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/screen/admin/admin.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/screen/staff/staff.dart';
import 'package:staff_work_track/screen/super%20admin/superadmin.dart';
import 'package:staff_work_track/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    checkLogin();
  }

  void _go(Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> checkLogin() async {
    final token = await AuthService.getToken();
    await Future.delayed(const Duration(seconds: 2));
    if (token == null || token.isEmpty || JwtHelper.isExpired(token)) {
      _go(const LoginSelection());
      return;
    }
    final role = JwtHelper.getRole(token);
    if (role == "Director") {
      _go(const SuperAdmin());
    } else if (role == "Manager") {
      _go(const Admin());
    } else {
      _go(const Staff());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Staff Work Tracking",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RotationTransition(
              turns: _controller,
              child: Image.asset(
                'assets/flower.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
