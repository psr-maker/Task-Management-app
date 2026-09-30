import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class GreetingHeader extends StatelessWidget {
  final String? subtitle;

  const GreetingHeader({
    super.key,
    this.subtitle = "Here's your performance overview for today.",
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _name(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'there';
        final greeting = JwtHelper.greetingForNow();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$greeting, $name',
              style: TextStyle(
                fontSize: AppLayout.isDesktop(context) ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: WebTheme.inkOf(context),
                letterSpacing: -0.4,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.mutedOf(context),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static Future<String> _name() async {
    final token = await AuthService.getToken();
    if (token == null) return 'there';
    return JwtHelper.displayName(token);
  }
}
