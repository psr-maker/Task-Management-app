import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class DashboardActionIcons extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onReports;
  final VoidCallback? onSettings;

  const DashboardActionIcons({
    super.key,
    this.notificationCount = 0,
    this.onNotifications,
    this.onReports,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final color = WebTheme.inkOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onNotifications != null)
          _icon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            color: notificationCount > 0 ? WebTheme.danger : color,
            badge: notificationCount,
            onTap: onNotifications,
          ),
        if (onReports != null)
          _icon(
            icon: Icons.bar_chart_rounded,
            tooltip: 'Reports',
            color: color,
            onTap: onReports,
          ),
        if (onSettings != null)
          _icon(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            color: color,
            onTap: onSettings,
          ),
      ],
    );
  }

  Widget _icon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback? onTap,
    int badge = 0,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color, size: 22),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const BoxDecoration(
                  color: WebTheme.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
