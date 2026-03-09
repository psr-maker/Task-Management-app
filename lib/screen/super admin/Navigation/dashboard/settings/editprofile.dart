// import 'package:flutter/material.dart';
// import 'package:staff_work_track/services/auth_service.dart';

// class EditProfilePage extends StatefulWidget {
//   const EditProfilePage({super.key});

//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }

// class _EditProfilePageState extends State<EditProfilePage> {
//   final _formKey = GlobalKey<FormState>();

// TextEditingController _nameController = TextEditingController();
// TextEditingController _emailController = TextEditingController();

// bool isLoading = false;

//   void _saveProfile() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => isLoading = true);
// await AuthService.updateProfile(
//   _nameController.text.trim(),
//   _emailController.text.trim(),
// );
//     await Future.delayed(const Duration(seconds: 1)); // simulate API

//     setState(() => isLoading = false);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Profile updated successfully")),
//     );

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.vertical,
//             child: Column(
//               children: [
//                 /// ===== PROFILE ICON =====
// CircleAvatar(
//   radius: 45,
//   backgroundColor: Theme.of(
//     context,
//   ).primaryColor.withOpacity(0.1),
//   child: Icon(
//     Icons.person,
//     size: 45,
//     color: Theme.of(context).primaryColor,
//   ),
// ),

//                 const SizedBox(height: 30),

//                 /// ===== NAME FIELD =====
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: InputDecoration(
//                     labelText: "Full Name",
//                     prefixIcon: const Icon(Icons.person_outline),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your name";
//                     }
//                     return null;
//                   },
//                 ),

//                 const SizedBox(height: 20),

//                 /// ===== EMAIL FIELD =====
//                 TextFormField(
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     labelText: "Email Address",
//                     prefixIcon: const Icon(Icons.email_outlined),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return "Please enter your email";
//                     }
//                     if (!value.contains("@")) {
//                       return "Enter valid email";
//                     }
//                     return null;
//                   },
//                 ),

//                 const SizedBox(height: 35),

//                 /// ===== SAVE BUTTON =====
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: isLoading ? null : _saveProfile,
//                     style: ElevatedButton.styleFrom(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     child: isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text(
//                             "Save Changes",
//                             style: TextStyle(fontSize: 16),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late Future<Map<String, dynamic>> _profileFuture;

  bool isSaving = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.getMyProfile();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await AuthService.updateProfile(
        _nameController.text.trim(),
        _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB), // Prevent white flash
      appBar: AppBar(title: const Text("Edit Profile"), elevation: 0),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          /// 🔹 LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }

          /// 🔹 ERROR STATE
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading profile",
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }

          /// 🔹 DATA LOADED
          final data = snapshot.data!;
          _nameController.text = data["name"] ?? "";
          _emailController.text = data["email"] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 45,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                   const SizedBox(height: 20),          
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter your name";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// EMAIL
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter your email";
                      }
                      if (!value.contains("@")) {
                        return "Enter valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),          
                  Center(
                    child: AppButton(
                      text: "Save Changes",
                      isLoading: _isLoading,
                      onPressed: isSaving ? null : _saveProfile,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
