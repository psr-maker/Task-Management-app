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

      colorScheme: const ColorScheme.light(
        primary: Color.fromARGB(255, 68, 99, 80),
        secondary: deepGreen,
        tertiary: Colors.white54,
        onPrimary: Colors.white,
        background: Color.fromARGB(255, 134, 170, 136),
        error: Colors.red,
      ),

      splashColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.1),
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
    );
  }

  ThemeData get darkTheme {
    const deepGreen = Color.fromARGB(255, 25, 77, 38);
    const darkBackground = const Color.fromARGB(255, 6, 33, 4);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: Color.fromARGB(255, 30, 45, 38),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 20),
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 18),
      primaryColor: deepGreen,
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 68, 99, 80),
        onPrimary: Colors.white,
        secondary: Color.fromARGB(255, 97, 124, 95),
        tertiary: Colors.white54,
        background: Color.fromARGB(255, 134, 170, 136),
        error: Colors.red,
      ),
      splashColor: deepGreen.withOpacity(0.3),
      highlightColor: deepGreen.withOpacity(0.1),

      cardTheme: const CardThemeData(
        color: Color.fromARGB(255, 15, 35, 20), // dark card background
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),

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
          color: deepGreen,
        ),

        bodySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: deepGreen,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color.fromARGB(255, 50, 70, 60),
        selectedColor: deepGreen,
        disabledColor: Colors.grey,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white70),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        brightness: Brightness.dark,
      ),
    );
  }
}
