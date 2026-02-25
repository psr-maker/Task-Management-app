import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/theme/theme_provider.dart';
import 'package:staff_work_track/screen/admin/admin.dart';
import 'package:staff_work_track/screen/splashscreen.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/worklog.dart';
import 'package:staff_work_track/screen/staff/staff.dart';
import 'package:staff_work_track/screen/super%20admin/superadmin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            // home: const Staff(),
            // home: const Admin(),
            home: const Worklog(),
            // home: const SuperAdmin(),

            // home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
