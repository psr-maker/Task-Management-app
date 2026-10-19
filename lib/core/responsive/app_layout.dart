import 'package:flutter/material.dart';

class AppLayout {
  static const double mobileMax = 600;
  static const double tabletMax = 1100;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) => widthOf(context) < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = widthOf(context);
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= tabletMax;

  static bool isWide(BuildContext context) => !isMobile(context);

  static double sidebarWidth(BuildContext context, {bool expanded = true}) {
    if (isTablet(context) && !expanded) return 80;
    if (isTablet(context)) return 200;
    return 248;
  }

  static int goalColumns(double width) {
    if (width < 520) return 1;
    if (width < 980) return 2;
    return 3;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.fromLTRB(16, 8, 16, 16);
    }
    if (isTablet(context)) {
      return const EdgeInsets.fromLTRB(12, 8, 12, 12);
    }
    return const EdgeInsets.all(15);
  }

  static EdgeInsets shellInset(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.fromLTRB(8, 8, 8, 8);
    }
    if (isTablet(context)) {
      return const EdgeInsets.fromLTRB(6, 6, 6, 6);
    }
    return EdgeInsets.zero;
  }

  static double dialogMaxWidth(BuildContext context, {double preferred = 720}) {
    final available = widthOf(context) - (isTablet(context) ? 32 : 56);
    if (available < preferred) return available.clamp(280, preferred);
    return preferred;
  }
}
