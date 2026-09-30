import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class AppLoadError extends StatefulWidget {
  final VoidCallback? onRetry;

  const AppLoadError({super.key, this.onRetry});

  @override
  State<AppLoadError> createState() => _AppLoadErrorState();
}

class _AppLoadErrorState extends State<AppLoadError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: motion,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -8 * motion.value),
                  child: child,
                );
              },
              child: const Text(
                '😢',
                style: TextStyle(fontSize: 72, height: 1),
              ),
            ),
            const SizedBox(height: 10),
            CustomPaint(
              size: const Size(18, 10),
              painter: _SpeechTailPainter(WebTheme.surfaceOf(context)),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: WebTheme.surfaceOf(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: WebTheme.lineOf(context)),
              ),
              child: Text(
                'Something is wrong. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WebTheme.inkOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: widget.onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  final Color color;

  _SpeechTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpeechTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
