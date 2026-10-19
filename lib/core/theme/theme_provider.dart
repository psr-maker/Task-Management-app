import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  TimePickerThemeData _timePickerTheme({
    required Color selected,
    required Color onSelected,
    required Color idleText,
  }) {
    return TimePickerThemeData(
      dayPeriodBorderSide: BorderSide(color: selected),
      dayPeriodColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return selected;
        return Colors.transparent;
      }),
      dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return onSelected;
        return idleText;
      }),
      dayPeriodTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void applyRole(String? role) {
    final next = RolePalette.forRole(role);
    if (WebTheme.palette.name == next.name) return;
    WebTheme.palette = next;
    notifyListeners();
  }

  ThemeData get lightTheme {
    final deepGreen = WebTheme.brand;
    final background = Colors.white;

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      appBarTheme: AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      iconTheme: IconThemeData(color: deepGreen, size: 18),

      primaryColor: deepGreen,

      colorScheme: ColorScheme.light(
        primary: deepGreen,
        secondary: deepGreen,
        tertiary: Colors.white54,
        onPrimary: Colors.white,
        surface: Colors.white,
        error: Colors.red,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepGreen,
          foregroundColor: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepGreen,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
      ),
      timePickerTheme: _timePickerTheme(
        selected: deepGreen,
        onSelected: Colors.white,
        idleText: deepGreen,
      ),

      splashColor: Colors.white,
      highlightColor: Colors.white,

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: WebTheme.dark, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: deepGreen,
        selectedColor: deepGreen,
        disabledColor: Colors.grey,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white70),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        brightness: Brightness.dark,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        headlineLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        headlineSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        titleLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        titleMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final staff = WebTheme.palette.name == 'staff';
    final manager = WebTheme.palette.name == 'manager';
    final division = WebTheme.palette.name == 'divisionHead';
    final accent = staff
        ? WebTheme.staffDarkAccent
        : manager
            ? WebTheme.managerDarkAccent
            : division
                ? WebTheme.divisionDarkAccent
                : WebTheme.brand;
    final onAccent = staff
        ? WebTheme.staffDarkOnAccent
        : manager
            ? const Color(0xFF052E16)
            : division
                ? WebTheme.divisionDarkOnAccent
                : Colors.white;
    final ink = staff ? WebTheme.staffDarkInk : Colors.white;
    final muted = staff ? WebTheme.staffDarkMuted : Colors.white70;
    final headline = staff || manager || division ? accent : Colors.white;
    final secondary = manager || division ? WebTheme.brand : accent;
    final onSecondary = manager || division ? Colors.white : onAccent;

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: WebTheme.darkCanvas,

      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: secondary,
        tertiary: staff ? muted : Colors.white,
        onPrimary: onAccent,
        onSecondary: onSecondary,
        surface: WebTheme.darkSurface,
        onSurface: ink,
        error: Colors.redAccent,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
      ),
      timePickerTheme: _timePickerTheme(
        selected: accent,
        onSelected: onAccent,
        idleText: ink,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: WebTheme.darkHeader,
        foregroundColor: ink,
        elevation: 0,
        iconTheme: IconThemeData(color: ink, size: 20),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      iconTheme: IconThemeData(color: ink, size: 18),

      cardTheme: CardThemeData(
        color: WebTheme.darkSurface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: WebTheme.darkBrandSoft,
        selectedColor: manager || division ? WebTheme.brand : accent,
        disabledColor: Colors.grey,
        labelStyle: TextStyle(color: ink),
        secondaryLabelStyle: TextStyle(color: muted),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        brightness: Brightness.dark,
      ),

      splashColor: accent.withValues(alpha: 0.2),
      highlightColor: accent.withValues(alpha: 0.1),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: headline,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: headline,
        ),
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: headline,
        ),
        headlineLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink),
        bodySmall: TextStyle(
          fontSize: 18,
          color: muted,
          fontWeight: FontWeight.bold,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: staff ? accent : WebTheme.brandSoft,
        ),
      ),
    );
  }
}
