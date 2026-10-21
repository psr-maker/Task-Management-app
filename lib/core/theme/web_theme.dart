import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';

class RolePalette {
  final String name;
  final Color brand;
  final Color primary;
  final Color brandSoft;
  final Color dark;
  final Color darkHeader;
  final Color darkCanvas;
  final Color darkSurface;
  final Color darkBrandSoft;
  final Color darkLine;

  const RolePalette({
    required this.name,
    required this.brand,
    required this.primary,
    required this.brandSoft,
    required this.dark,
    required this.darkHeader,
    required this.darkCanvas,
    required this.darkSurface,
    required this.darkBrandSoft,
    required this.darkLine,
  });

  static const manager = RolePalette(
    name: 'manager',
    brand: Color(0xFF166534),
    primary: Color.fromARGB(255, 68, 99, 80),
    brandSoft: Color(0xFFDCFCE7),
    dark: Color(0xFF14532D),
    darkHeader: Color(0xFF102418),
    darkCanvas: Color(0xFF0C1610),
    darkSurface: Color(0xFF1B3124),
    darkBrandSoft: Color(0xFF234233),
    darkLine: Color(0xFF3F6B50),
  );

  static const director = RolePalette(
    name: 'director',
    brand: Color(0xFF0A2540),
    primary: Color(0xFF12355B),
    brandSoft: Color(0xFFE6EEF6),
    dark: Color(0xFF071A2E),
    darkHeader: Color(0xFF051422),
    darkCanvas: Color(0xFF04101C),
    darkSurface: Color(0xFF0E2740),
    darkBrandSoft: Color(0xFF163552),
    darkLine: Color(0xFF1E4568),
  );

  static const divisionHead = RolePalette(
    name: 'divisionHead',
    brand: Color(0xFF0F766E),
    primary: Color(0xFF115E59),
    brandSoft: Color(0xFFCCFBF1),
    dark: Color(0xFF115E59),
    darkHeader: Color(0xFF042F2E),
    darkCanvas: Color(0xFF071615),
    darkSurface: Color(0xFF132E2C),
    darkBrandSoft: Color(0xFF1A3F3C),
    darkLine: Color(0xFF2F6F69),
  );

  static const staff = RolePalette(
    name: 'staff',
    brand: Color(0xFF8A5A12),
    primary: Color(0xFF6F4710),
    brandSoft: Color(0xFFF8F1E3),
    dark: Color(0xFF3A2A16),
    darkHeader: Color(0xFF1A140E),
    darkCanvas: Color(0xFF100E0B),
    darkSurface: Color(0xFF1C1813),
    darkBrandSoft: Color(0xFF2C2418),
    darkLine: Color(0xFF3A3228),
  );

  static const assistant = RolePalette(
    name: 'assistant',
    brand: Color(0xFF9A3412),
    primary: Color(0xFFC2410C),
    brandSoft: Color(0xFFFFEDD5),
    dark: Color(0xFF7C2D12),
    darkHeader: Color(0xFF431407),
    darkCanvas: Color(0xFF1C1008),
    darkSurface: Color(0xFF7C2D12),
    darkBrandSoft: Color(0xFF9A3412),
    darkLine: Color(0xFFC2410C),
  );

  static const fiveS = RolePalette(
    name: 'fiveS',
    brand: Color(0xFF6D28D9),
    primary: Color(0xFF5B21B6),
    brandSoft: Color(0xFFEDE9FE),
    dark: Color(0xFF4C1D95),
    darkHeader: Color(0xFF2E1065),
    darkCanvas: Color(0xFF1E1033),
    darkSurface: Color(0xFF4C1D95),
    darkBrandSoft: Color(0xFF5B21B6),
    darkLine: Color(0xFF6D28D9),
  );

  static RolePalette forRole(String? role) {
    final value = (role ?? '').trim();
    if (value.isEmpty) return manager;
    if (AppRoles.isDirector(value)) return director;
    if (AppRoles.isDivisionHead(value)) return divisionHead;
    if (AppRoles.isFiveS(value)) return fiveS;
    if (AppRoles.isAssistantManager(value)) return assistant;
    if (AppRoles.isManager(value)) return manager;
    return staff;
  }
}

class WebTheme {
  static RolePalette palette = RolePalette.manager;

  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
  static const Color canvas = Color(0xFFF5F7F6);
  static Color get brand => palette.brand;
  static Color get brandSoft => palette.brandSoft;
  static const Color header = Colors.white;
  static Color get dark => palette.dark;
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static Color get darkCanvas => palette.darkCanvas;
  static Color get darkHeader => palette.darkHeader;
  static const Color darkInk = Color(0xFFF3F4F6);
  static const Color darkMuted = Color(0xFF9CA3AF);
  static const Color staffDarkAccent = Color(0xFFE4C07A);
  static const Color staffDarkInk = Color(0xFFF6F0E6);
  static const Color staffDarkMuted = Color(0xFFC9BBA8);
  static const Color staffDarkOnAccent = Color(0xFF1A1208);
  static const Color managerDarkAccent = Color(0xFF86EFAC);
  static const Color divisionDarkAccent = Color(0xFF5EEAD4);
  static const Color divisionDarkOnAccent = Color(0xFF042F2E);

  static bool get _staffDarkPalette => palette.name == 'staff';
  static bool get _managerDarkPalette => palette.name == 'manager';
  static bool get _divisionDarkPalette => palette.name == 'divisionHead';
  static Color get darkLine => palette.darkLine;
  static Color get darkSurface => palette.darkSurface;
  static Color get darkBrandSoft => palette.darkBrandSoft;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvasOf(BuildContext context) =>
      isDark(context) ? darkCanvas : canvas;

  static Color headerOf(BuildContext context) =>
      isDark(context) ? darkHeader : header;

  static Color inkOf(BuildContext context) {
    if (isDark(context) && _staffDarkPalette) return staffDarkInk;
    return isDark(context) ? darkInk : ink;
  }

  static Color mutedOf(BuildContext context) {
    if (isDark(context) && _staffDarkPalette) return staffDarkMuted;
    return isDark(context) ? darkMuted : muted;
  }

  static Color brandOf(BuildContext context) {
    if (isDark(context) && _staffDarkPalette) return staffDarkAccent;
    if (isDark(context) && _managerDarkPalette) return managerDarkAccent;
    if (isDark(context) && _divisionDarkPalette) return divisionDarkAccent;
    return brand;
  }

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
