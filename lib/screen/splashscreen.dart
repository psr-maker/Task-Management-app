import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/super%20admin/fives/create_fives.dart';
import 'package:staff_work_track/services/version_service.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/screen/admin/admin.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/screen/division_head/division_head.dart';
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


  Future<void> checkLogin() async {
    if (VersionService.shouldCheckUpdate) {
      final versionResult = await VersionService.checkVersion();

      if (versionResult != null) {
        final currentVersion =
            (versionResult['currentVersion'] ?? '').toString();
        final latestVersion =
            (versionResult['latestVersion'] ?? '').toString();

        if (VersionService.isNewerVersion(currentVersion, latestVersion)) {
          if (!mounted) return;

          await _showUpdateDialog(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: (versionResult['downloadUrl'] ?? '').toString(),
          );
          return;
        }
      }
    }

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
    } else if (role == "3") {
      _go(const Admin());
    } else if (AppRoles.isDivisionHead(role)) {
      _go(const DivisionHead());
    } else if (role == "50") {
      _go(const FiveSpoints());
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
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary
                          .withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      size: 34,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A new version of WorkPulse is available.\nPlease update to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _versionRow('Current version', currentVersion),
                  const SizedBox(height: 8),
                  _versionRow('Latest version', latestVersion, highlight: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Update Now',
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                      onPressed: () => _openUpdateLink(downloadUrl),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _versionRow(String label, String version, {bool highlight = false}) {
    final color = highlight
        ? Theme.of(context).colorScheme.secondary
        : Colors.grey.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            version,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpdateLink(String downloadUrl) async {
    final url = downloadUrl.trim();
    if (url.isEmpty) {
      showAppMessage(context, "Update link is missing.");
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      showAppMessage(context, "Invalid update link.");
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      showAppMessage(context, "Could not open the update link.");
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
              "WorkPulse",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Performance Tracking",
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
