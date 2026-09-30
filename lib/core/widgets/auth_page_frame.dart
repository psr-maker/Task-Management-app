import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class AuthPageFrame extends StatelessWidget {
  final Widget form;
  final String headline;
  final String subtitle;

  const AuthPageFrame({
    super.key,
    required this.form,
    this.headline = 'WorkPulse',
    this.subtitle = 'Track goals, tasks and performance in one place.',
  });

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isDesktop(context)) {
      return ColoredBox(
        color: const Color(0xFF2C6737),
        child: SafeArea(child: form),
      );
    }

    return ColoredBox(
      color: WebTheme.canvas,
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: WebTheme.line)),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/flower.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.bolt_rounded,
                    color: WebTheme.brand,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  headline,
                  style: const TextStyle(
                    color: WebTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Poornasree Equipments',
                  style: TextStyle(
                    color: WebTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: WebTheme.brandSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'STAFF PERFORMANCE',
                                  style: TextStyle(
                                    color: WebTheme.brand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Run your team\nfrom one workspace.',
                                style: TextStyle(
                                  color: WebTheme.ink,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: WebTheme.muted,
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 480, child: form),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: WebTheme.line)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '© Poornasree Equipments',
                style: TextStyle(color: WebTheme.muted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
