import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/theme/theme_provider.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/editprofile.dart';
import 'package:staff_work_track/services/auth_service.dart';

class UsersSettings extends StatefulWidget {
  const UsersSettings({super.key});

  @override
  State<UsersSettings> createState() => _SettingsState();

  /// SECTION TITLE
  static Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Color.fromARGB(255, 104, 103, 103),
      ),
    );
  }

  /// COMMON TILE
  static Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsState extends State<UsersSettings> {
  bool _isLoading = false;
  Future<void> logout() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginSelection()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// ===== PROFILE CARD =====
          UsersSettings._sectionTitle("Account"),
          const SizedBox(height: 10),

          UsersSettings._buildTile(
            context,
            icon: Icons.person_outline,
            title: "Profile",
            subtitle: "Change name & email",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),

          const SizedBox(height: 30),

          /// ===== APPEARANCE =====
          UsersSettings._sectionTitle("Appearance"),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              value: themeProvider.isDarkMode,
              activeColor: Theme.of(context).primaryColor,
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: Text(
                themeProvider.isDarkMode ? "Dark Mode" : "Light Mode",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                "Toggle application theme",
                style: Theme.of(context).textTheme.labelMedium,
              ),
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 40),

          Center(
            child: AppButton(
              text: "LOGOUT",
              isLoading: _isLoading,
              onPressed: _isLoading
                  ? null
                  : () async {
                      bool? confirmed = await showConfirmDialog(
                        context,
                        "Logout",
                        "this account",
                      );
                      if (confirmed == true) {
                        logout();
                      }
                    },
              color: Theme.of(context).colorScheme.secondary,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
