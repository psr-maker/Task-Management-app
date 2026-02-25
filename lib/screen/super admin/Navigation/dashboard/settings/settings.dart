import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/theme/theme_provider.dart';
import 'package:staff_work_track/screen/authen/logout.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/add_dept.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Dark/Light Theme Card
            Card(
              child: ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                title: Text(
                  themeProvider.isDarkMode ? "Dark Mode" : "Light Mode",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? "Currently using dark theme"
                      : "Currently using light theme",
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Add Department Card
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.apartment,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                title: const Text(
                  "Add Department",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text("Create a new department"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddDepartmentPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Logout Card
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text("Sign out from the app"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Logout()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
