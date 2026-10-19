import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';

/// Keeps a page full width on a phone and a comfortable width on the website.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    if (AppLayout.isMobile(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// One column on a phone. On the website, [columnsForWidth] chooses the row count.
class ResponsiveWrapList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final int Function(double width)? columnsForWidth;

  const ResponsiveWrapList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.spacing = 12,
    this.columnsForWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (AppLayout.isMobile(context)) {
      return ListView.separated(
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: spacing),
        itemBuilder: itemBuilder,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (columnsForWidth ?? _defaultColumns)(constraints.maxWidth);
        final pad = padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
        final inner = constraints.maxWidth - pad.horizontal;
        final width = (inner - spacing * (columns - 1)) / columns;
        return SingleChildScrollView(
          padding: padding,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              for (var i = 0; i < itemCount; i++)
                SizedBox(
                  width: width.clamp(160, inner),
                  child: itemBuilder(context, i),
                ),
            ],
          ),
        );
      },
    );
  }

  static int _defaultColumns(double width) => width >= 1100 ? 3 : 2;
}
