import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';

class AdaptiveGoalCards extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool shrinkWrap;

  const AdaptiveGoalCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    if (AppLayout.isMobile(context)) {
      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppLayout.goalColumns(constraints.maxWidth);
        const gap = 16.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final wrap = Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (var i = 0; i < itemCount; i++)
              SizedBox(
                width: itemWidth,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: itemBuilder(context, i),
                ),
              ),
          ],
        );

        if (shrinkWrap) return wrap;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: wrap,
        );
      },
    );
  }
}
