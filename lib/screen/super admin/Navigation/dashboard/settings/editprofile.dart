import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _contactGroupController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();

  String? _selectedGender;

  @override
  late Future<Map<String, dynamic>> _profileFuture;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  bool isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.getMyProfile();
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      await AuthService.updateProfile(
        _nameController.text.trim(),
        _emailController.text.trim(),
      );
      showTopMessage("Profile updated successfully", isError: false);
    } catch (e) {
      showTopMessage("Failed to update Profile", isError: true);
    }
    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading profile",
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }
          final data = snapshot.data!;
          _nameController.text = data["name"] ?? "";
          _emailController.text = data["email"] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Stack(
                children: [
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Center(
                  //       child: CircleAvatar(
                  //         radius: 45,
                  //         backgroundColor: Theme.of(
                  //           context,
                  //         ).primaryColor.withOpacity(0.1),
                  //         child: Icon(
                  //           Icons.person,
                  //           size: 45,
                  //           color: Theme.of(context).primaryColor,
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(height: 20),
                  //     Text(
                  //       "UserName",
                  //       style: Theme.of(context).textTheme.headlineLarge,
                  //     ),
                  //     const SizedBox(height: 8),
                  //     CustomTextField(controller: _nameController),
                  //     const SizedBox(height: 20),

                  //     Text(
                  //       "Email",
                  //       style: Theme.of(context).textTheme.headlineLarge,
                  //     ),
                  //     const SizedBox(height: 8),
                  //     CustomTextField(
                  //       controller: _emailController,
                  //       isEmail: true,
                  //     ),
                  //     const SizedBox(height: 30),

                  //     Center(
                  //       child: AppButton(
                  //         text: "Save Changes",
                  //         isLoading: _isLoading,
                  //         onPressed: isSaving ? null : _saveProfile,
                  //         color: Theme.of(context).colorScheme.secondary,
                  //         txtcolor: Theme.of(context).colorScheme.onPrimary,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 👤 PROFILE IMAGE
                      Center(
                        child: Stack(
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
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// 🧾 PERSONAL DETAILS TITLE
                      Text(
                        "Personal Details",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const SizedBox(height: 15),

                      /// NAME
                      Text(
                        "Name",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(controller: _nameController),

                      const SizedBox(height: 16),

                      /// EMAIL
                      Text(
                        "Email",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _emailController,
                        isEmail: true,
                      ),

                      const SizedBox(height: 16),

                      /// BLOOD GROUP
                      Text(
                        "Blood Group",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(controller: _bloodGroupController),

                      const SizedBox(height: 16),

                      /// CONTACT NUMBER
                      Text(
                        "Contact Number",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(
                        keyboardType: TextInputType.phone,
                        controller: _contactGroupController,
                      ),

                      const SizedBox(height: 16),

                      /// DOB
                      Text(
                        "Date of Birth",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(controller: _dobController),

                      const SizedBox(height: 16),

                      /// EMERGENCY CONTACT
                      Text(
                        "Emergency Contact",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      CustomTextField(
                        keyboardType: TextInputType.phone,
                        controller: _emergencyContactController,
                      ),

                      const SizedBox(height: 16),

                      /// GENDER
                      Text(
                        "Gender",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ["Male", "Female", "Other"]
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),

                      const SizedBox(height: 30),

                      /// SAVE BUTTON
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
                  if (_topMessage != null)
                    AnimatedPositioned(
                      top: _showTopMessage ? 0 : -120,
                      left: 16,
                      right: 16,
                      duration: const Duration(milliseconds: 300),
                      child: Msgsnackbar(
                        context,
                        message: _topMessage!,
                        isError: _isErrorMessage,
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
