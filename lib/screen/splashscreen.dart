import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/version_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/screen/admin/admin.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/screen/staff/staff.dart';
import 'package:staff_work_track/screen/super%20admin/superadmin.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Future<void> checkLogin() async {
  //   final token = await AuthService.getToken();
  //   await Future.delayed(const Duration(seconds: 2));
  //   if (token == null || token.isEmpty || JwtHelper.isExpired(token)) {
  //     _go(const LoginSelection());
  //     return;
  //   }
  //   final role = JwtHelper.getRole(token);
  //   if (role == "1") {
  //     _go(const SuperAdmin());
  //   } else if (role == "2") {
  //     _go(const Admin());
  //   } else {
  //     _go(const Staff());
  //   }
  // }
  Future<void> checkLogin() async {
    // 1. Check application version
    final versionResult = await VersionService.checkVersion();

    if (versionResult != null) {
      final currentVersion = versionResult['currentVersion'];
      final latestVersion = versionResult['latestVersion'];

      final updateAvailable = VersionService.isNewerVersion(
        currentVersion,
        latestVersion,
      );

      // 2. If new version exists, show update dialog
      if (updateAvailable) {
        if (!mounted) return;

        await _showUpdateDialog(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          downloadUrl: versionResult['downloadUrl'],
        );
      }
    }

    // 3. Continue with your existing login logic
    final token = await AuthService.getToken();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (token == null || token.isEmpty || JwtHelper.isExpired(token)) {
      _go(const LoginSelection());
      return;
    }

    final role = JwtHelper.getRole(token);

    if (role == "1") {
      _go(const SuperAdmin());
    } else if (role == "2") {
      _go(const Admin());
    } else {
      _go(const Staff());
    }
  }

  Future<void> _showUpdateDialog({
    required String currentVersion,
    required String latestVersion,
    required String downloadUrl,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            'A new version of WorkPulse is available.\n\n'
            'Current version: $currentVersion\n'
            'Latest version: $latestVersion',
          ),
          actions: [
            // TextButton(
            //   onPressed: () {
            //     Navigator.pop(context);
            //   },
            //   child: const Text('Later'),
            // ),
            AppButton(
              text: 'Update Now',
              onPressed: () async {
                final uri = Uri.parse(downloadUrl);

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      },
    );
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
              "Performance Tracking",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
