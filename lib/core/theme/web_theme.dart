import 'package:flutter/material.dart';

class WebTheme {
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
  static const Color canvas = Color(0xFFF5F7F6);
  static const Color brand = Color(0xFF166534);
  static const Color brandSoft = Color(0xFFDCFCE7);
  static const Color header = Colors.white;
  static const Color dark = Color(0xFF163824);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color darkCanvas = Color(0xFF0F1A14);
  static const Color darkHeader = Color(0xFF132A1B);
  static const Color darkInk = Color(0xFFF3F4F6);
  static const Color darkMuted = Color(0xFF9CA3AF);
  static const Color darkLine = Color(0xFF244233);
  static const Color darkSurface = Color(0xFF163824);
  static const Color darkBrandSoft = Color(0xFF1E3A2F);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvasOf(BuildContext context) =>
      isDark(context) ? darkCanvas : canvas;

  static Color headerOf(BuildContext context) =>
      isDark(context) ? darkHeader : header;

  static Color inkOf(BuildContext context) => isDark(context) ? darkInk : ink;

  static Color mutedOf(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color lineOf(BuildContext context) =>
      isDark(context) ? darkLine : line;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color brandSoftOf(BuildContext context) =>
      isDark(context) ? darkBrandSoft : brandSoft;

  static List<BoxShadow> cardShadow(BuildContext context) {
    if (isDark(context)) {
      return const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ];
  }

  static BoxDecoration card(BuildContext context, {double radius = 14}) {
    return BoxDecoration(
      color: surfaceOf(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: lineOf(context)),
      boxShadow: cardShadow(context),
    );
  }

  static ThemeData overlay(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    return base.copyWith(
      scaffoldBackgroundColor: dark ? darkCanvas : canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? darkHeader : brand,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 22,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? darkSurface : Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: dark ? darkLine : line),
        ),
      ),
      dividerColor: dark ? darkLine : line,
      splashColor: dark ? darkBrandSoft : brandSoft,
      highlightColor: dark ? darkBrandSoft : brandSoft,
    );
  }
}
