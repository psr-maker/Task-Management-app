import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class WebPushedChrome {
  static bool isWeb(BuildContext context) => !AppLayout.isMobile(context);

  static Color? background(BuildContext context) {
    if (!isWeb(context)) return null;
    return WebTheme.canvasOf(context);
  }

  static Widget body(
    BuildContext context, {
    required Widget child,
    String? title,
    String? subtitle,
    bool panel = true,
  }) {
    if (!isWeb(context)) return child;

    Widget content = child;
    if (panel) {
      content = Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WebTheme.lineOf(context)),
          boxShadow: WebTheme.cardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }

    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            WebPageHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 12),
          ],
          Expanded(child: content),
        ],
      ),
    );
  }
}

class WebPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const WebPageHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: desktop ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: WebTheme.inkOf(context),
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: desktop ? 14 : 13,
              color: WebTheme.mutedOf(context),
            ),
          ),
        ],
      ],
    );
  }
}

class WebSectionTitle extends StatelessWidget {
  final String title;

  const WebSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}

class WebPillTabs extends StatelessWidget {
  final TabController controller;
  final List<Widget> tabs;

  const WebPillTabs({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.isDesktop(context) ? 420 : 360,
        ),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WebTheme.brandSoftOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WebTheme.lineOf(context)),
          ),
          child: TabBar(
            controller: controller,
            tabs: tabs,
            indicator: BoxDecoration(
              color: WebTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
              boxShadow: WebTheme.cardShadow(context),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: WebTheme.brand,
            unselectedLabelColor: WebTheme.mutedOf(context),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class WebChoiceBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const WebChoiceBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: option == selected
                      ? WebTheme.brand
                      : WebTheme.surfaceOf(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: option == selected
                        ? WebTheme.brand
                        : WebTheme.lineOf(context),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: option == selected
                        ? Colors.white
                        : WebTheme.inkOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WebFormFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebFormFrame({super.key, required this.child, this.maxWidth = 880});

  @override
  Widget build(BuildContext context) {
    if (!WebPushedChrome.isWeb(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: WebTheme.card(context),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

class WebPanel {
  static Widget wrap(BuildContext context, Widget child) {
    if (!WebPushedChrome.isWeb(context)) return child;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.isDesktop(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.lineOf(context)),
        boxShadow: WebTheme.cardShadow(context),
      ),
      child: child,
    );
  }
}

class WebResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double minChildWidth;
  final double spacing;
  final double runSpacing;

  const WebResponsiveRow({
    super.key,
    required this.children,
    this.minChildWidth = 200,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (AppLayout.isMobile(context)) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: children[i]),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        var cols = (maxW / minChildWidth).floor();
        if (cols < 1) cols = 1;
        if (cols > children.length) cols = children.length;
        if (AppLayout.isMobile(context) && cols > 2) cols = 2;
        final itemW = (maxW - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final child in children)
              SizedBox(width: itemW, child: child),
          ],
        );
      },
    );
  }
}
