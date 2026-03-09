
import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/authen/login_selection.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class Logout extends StatefulWidget {
  const Logout({super.key});

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 99, 49),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 99, 49),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: AppButton(
          text: "Logout",
          isLoading: _isLoading,
          onPressed: _isLoading ? null : logout,
          color: Colors.white, 
        ),
      ),
    );
  }
}