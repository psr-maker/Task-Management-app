import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/status_badge.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';

/// Premium web workspace chrome for HR request flows
/// (leave, permission, attendance, compensation).
class WebWorkspace {
  static bool enabled(BuildContext context) => WebPushedChrome.isWeb(context);

  static Widget page({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
    List<Widget>? actions,
    Widget? toolbar,
    List<WebMetric>? metrics,
  }) {
    if (!enabled(context)) return child;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebTheme.canvasOf(context),
            Color.lerp(WebTheme.canvasOf(context), WebTheme.brandSoftOf(context), 0.35)!,
            WebTheme.canvasOf(context),
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MeshPainter(WebTheme.brand)),
          ),
          Padding(
            padding: AppLayout.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkspaceHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
                if (metrics != null && metrics.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  WebMetricStrip(metrics: metrics),
                ],
                if (toolbar != null) ...[
                  const SizedBox(height: 16),
                  toolbar,
                ],
                const SizedBox(height: 16),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const WebMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

class _WorkspaceHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  const _WorkspaceHeader({
    required this.title,
    required this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isDesktop(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        desktop ? 22 : 16,
        desktop ? 20 : 16,
        desktop ? 22 : 16,
        desktop ? 18 : 14,
      ),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: [
          BoxShadow(
            color: WebTheme.brand.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WebTheme.brand,
                  Color.lerp(WebTheme.brand, WebTheme.dark, 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_motion_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKSPACE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: WebTheme.brand,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: desktop ? 28 : 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: WebTheme.inkOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: desktop ? 14.5 : 13,
                    height: 1.35,
                    color: WebTheme.mutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions!),
          ],
        ],
      ),
    );
  }
}

class WebMetricStrip extends StatelessWidget {
  final List<WebMetric> metrics;

  const WebMetricStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final children = [
          for (final metric in metrics)
            _MetricCard(metric: metric, expanded: wide),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - 10) / 2,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final WebMetric metric;
  final bool expanded;

  const _MetricCard({required this.metric, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final color = metric.color ?? WebTheme.brand;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 16 : 12,
        vertical: expanded ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.mutedOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: WebTheme.inkOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebSegmentControl extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool compact;

  const WebSegmentControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: option == selected
                        ? WebTheme.brand
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: option == selected
                          ? Colors.white
                          : WebTheme.mutedOf(context),
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 12.5 : 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WebFilterBar extends StatelessWidget {
  final List<Widget> leading;
  final List<Widget>? trailing;

  const WebFilterBar({
    super.key,
    required this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(spacing: 10, runSpacing: 8, children: leading),
          if (trailing != null)
            Wrap(spacing: 8, runSpacing: 8, children: trailing!),
        ],
      ),
    );
  }
}

class WebPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const WebPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: WebTheme.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class WebRequestTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? meta;
  final String status;
  final IconData icon;
  final List<WebMetaCell> cells;
  final Widget? details;
  final VoidCallback? onLongPress;
  final List<Widget>? actions;

  const WebRequestTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.meta,
    this.cells = const [],
    this.details,
    this.onLongPress,
    this.actions,
  });

  @override
  State<WebRequestTile> createState() => _WebRequestTileState();
}

class _WebRequestTileState extends State<WebRequestTile> {
  bool _open = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccent(widget.status);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hover
                ? WebTheme.brand.withValues(alpha: 0.35)
                : WebTheme.lineOf(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.07 : 0.03),
              blurRadius: _hover ? 22 : 12,
              offset: Offset(0, _hover ? 10 : 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.details == null
                          ? null
                          : () => setState(() => _open = !_open),
                      onLongPress: widget.onLongPress,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(widget.icon, color: accent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                          color: WebTheme.inkOf(context),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.subtitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: WebTheme.mutedOf(context),
                                        ),
                                      ),
                                      if (widget.meta != null &&
                                          widget.meta!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.meta!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: WebTheme.mutedOf(context),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                StatusBadge(widget.status),
                                if (widget.details != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    _open
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: WebTheme.mutedOf(context),
                                  ),
                                ],
                              ],
                            ),
                            if (widget.cells.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 18,
                                runSpacing: 10,
                                children: [
                                  for (final cell in widget.cells)
                                    _MetaChip(cell: cell),
                                ],
                              ),
                            ],
                            if (_open && widget.details != null) ...[
                              const SizedBox(height: 14),
                              Divider(color: WebTheme.lineOf(context), height: 1),
                              const SizedBox(height: 12),
                              widget.details!,
                            ],
                            if (widget.actions != null &&
                                widget.actions!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.actions!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusAccent(String status) {
    final value = status.toLowerCase();
    if (value.contains('reject')) return WebTheme.danger;
    if (value.contains('approv') || value.contains('complete')) {
      return WebTheme.success;
    }
    if (value.contains('pending') || value.contains('accept')) {
      return WebTheme.warning;
    }
    return WebTheme.brand;
  }
}

class WebMetaCell {
  final String label;
  final String value;
  final IconData icon;

  const WebMetaCell({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _MetaChip extends StatelessWidget {
  final WebMetaCell cell;

  const _MetaChip({required this.cell});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WebTheme.canvasOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cell.icon, size: 15, color: WebTheme.brand),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cell.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.mutedOf(context),
                ),
              ),
              Text(
                cell.value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.inkOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WebMonthLabel extends StatelessWidget {
  final String label;

  const WebMonthLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: WebTheme.mutedOf(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: WebTheme.lineOf(context)),
          ),
        ],
      ),
    );
  }
}

class WebEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const WebEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: WebTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: WebTheme.brandSoftOf(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: WebTheme.brand, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: WebTheme.inkOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: WebTheme.mutedOf(context),
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WebApplyLayout extends StatelessWidget {
  final Widget form;
  final Widget sidePanel;
  final double maxWidth;

  const WebApplyLayout({
    super.key,
    required this.form,
    required this.sidePanel,
    this.maxWidth = 1180,
  });

  @override
  Widget build(BuildContext context) {
    if (!WebWorkspace.enabled(context)) return form;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final split = constraints.maxWidth >= 980;
            if (!split) {
              return ListView(
                children: [
                  _panel(context, form),
                  const SizedBox(height: 14),
                  _panel(context, sidePanel),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _panel(context, form)),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: sidePanel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class WebSideGuide extends StatelessWidget {
  final String title;
  final String body;
  final List<String> points;
  final Widget? footer;

  const WebSideGuide({
    super.key,
    required this.title,
    required this.body,
    required this.points,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebTheme.dark,
            Color.lerp(WebTheme.dark, WebTheme.brand, 0.45)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: WebTheme.brand.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: Colors.white70),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.45,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          for (final point in points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF86EFAC),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

class WebFormSection extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget child;

  const WebFormSection({
    super.key,
    required this.title,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: WebTheme.inkOf(context),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 12.5,
                color: WebTheme.mutedOf(context),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color brand;

  _MeshPainter(this.brand);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brand.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    final orb = Paint()
      ..shader = RadialGradient(
        colors: [
          brand.withValues(alpha: 0.10),
          brand.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.9, size.height * 0.08),
        radius: 220,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.08),
      220,
      orb,
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.brand != brand;
}
