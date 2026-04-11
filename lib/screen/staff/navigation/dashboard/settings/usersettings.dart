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
}

class _SettingsState extends State<UsersSettings> {
  bool _isLoading = false;
  late Future<Map<String, dynamic>> _profileFuture;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.getMyProfile();
  }

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Settings"),
          actions: [
            /// Theme toggle
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              onPressed: themeProvider.toggleTheme,
            ),

            /// Edit profile
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
            ),
          ],
        ),

        body: Column(
          children: [
            const SizedBox(height: 20),

            /// 👤 PROFILE
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "John Doe",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "john@email.com",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔘 TAB BAR
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: "Personal Details"),
                Tab(text: "Employment Details"),
              ],
            ),

            /// 📄 TAB CONTENT
            Expanded(
              child: TabBarView(
                children: [
                  /// PERSONAL DETAILS
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _infoTile(context, "Name", "John Doe"),
                      _infoTile(context, "Email", "john@email.com"),
                      _infoTile(context, "Blood Group", "O+"),
                      _infoTile(context, "Contact Number", "9876543210"),
                      _infoTile(context, "D.O.B", "12/08/1998"),
                      _infoTile(context, "Emergency Contact", "9123456780"),
                      _infoTile(context, "Gender", "Male"),
                    ],
                  ),

                  /// EMPLOYMENT DETAILS
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _infoTile(context, "Employee ID", "EMP001"),
                      _infoTile(context, "Designation", "Developer"),
                      _infoTile(context, "Department", "IT"),
                      _infoTile(context, "Date of Joining", "01/01/2023"),
                      _infoTile(context, "Reporting Manager", "Manager Name"),
                    ],
                  ),
                ],
              ),
            ),

            /// 🚪 LOGOUT BUTTON (fixed bottom feel)
            Padding(
              padding: const EdgeInsets.all(16),
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
                        if (confirmed == true) logout();
                      },
                color: Theme.of(context).colorScheme.secondary,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoTile(BuildContext context, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
