import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;

  const StatusBadge(this.label, {super.key});

  static ({Color fg, Color bg}) _tone(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('overdue') ||
        value.contains('reject') ||
        value.contains('inactive') ||
        value.contains('block') ||
        value.contains('fail')) {
      return (fg: WebTheme.danger, bg: const Color(0xFFFEE2E2));
    }
    if (value.contains('pending') ||
        value.contains('pause') ||
        value.contains('wait') ||
        value.contains('review')) {
      return (fg: WebTheme.warning, bg: const Color(0xFFFEF3C7));
    }
    if (value.contains('progress') ||
        value.contains('process') ||
        value.contains('active') ||
        value.contains('open')) {
      return (fg: const Color(0xFF0284C7), bg: const Color(0xFFE0F2FE));
    }
    if (value.contains('complete') ||
        value.contains('approv') ||
        value.contains('done') ||
        value.contains('success')) {
      return (fg: WebTheme.success, bg: const Color(0xFFDCFCE7));
    }
    return (fg: WebTheme.muted, bg: const Color(0xFFF1F5F9));
  }

  @override
  Widget build(BuildContext context) {
    final text = label.trim().isEmpty ? 'Unknown' : label.trim();
    final tone = _tone(text);
    final dark = WebTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? tone.fg.withValues(alpha: 0.16) : tone.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.fg.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? tone.fg : tone.fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
