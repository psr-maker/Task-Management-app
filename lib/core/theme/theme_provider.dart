import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ThemeData get lightTheme {
    const deepGreen = Color.fromARGB(255, 25, 77, 38);
    const background = Colors.white;

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      // APPBAR
      appBarTheme: const AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // BODY ICON
      iconTheme: const IconThemeData(color: deepGreen, size: 18),

      primaryColor: deepGreen,

      // COLORS THEME
      colorScheme: const ColorScheme.light(
        primary: Color.fromARGB(255, 68, 99, 80),
        secondary: deepGreen,
        tertiary: Colors.white54,
        onPrimary: Colors.white,
        background: Color.fromARGB(255, 134, 170, 136),
        error: Colors.red,
      ),

      splashColor: Colors.white,
      highlightColor: Colors.white,

      // CARD THEME
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: Color.fromARGB(255, 15, 35, 20), width: 2),
        ),
      ),

      // CHIP  THEME
      chipTheme: const ChipThemeData(
        backgroundColor: deepGreen,
        selectedColor: deepGreen,
        disabledColor: Colors.grey,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white70),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        brightness: Brightness.dark,
      ),

      // TEXT THEME
      textTheme: const TextTheme(
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
    const deepGreen = Color.fromARGB(255, 25, 77, 38);
    const darkBg = Color(0xFF0B1F14);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      scaffoldBackgroundColor: darkBg,

      // COLOR SCHEME
      colorScheme: const ColorScheme.dark(
        primary: deepGreen,
        secondary: Color(0xFF4CAF50),
        surface: Color(0xFF132A1B),
        background: darkBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        error: Colors.redAccent,
      ),

      primaryColor: deepGreen,

      // APPBAR
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF132A1B),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ICON
      iconTheme: const IconThemeData(color: Colors.white, size: 18),

      // CARD
      cardTheme: CardThemeData(
        color: const Color(0xFF132A1B),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // CHIP
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF1E3A2F),
        selectedColor: deepGreen,
        disabledColor: Colors.grey,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white70),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        brightness: Brightness.dark,
      ),

      splashColor: deepGreen.withOpacity(0.2),
      highlightColor: deepGreen.withOpacity(0.1),

      // TEXT THEME (FIXED CONTRAST)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),

        headlineLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),

        titleLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),

        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white70),

        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white60,
        ),
      ),
    );
  }
}
