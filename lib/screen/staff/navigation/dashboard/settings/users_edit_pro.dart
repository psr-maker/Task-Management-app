import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class UserEditProfile extends StatefulWidget {
  const UserEditProfile({super.key});

  @override
  State<UserEditProfile> createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _blood = TextEditingController();
  final _dob = TextEditingController();
  final _contact = TextEditingController();
  final _emergency = TextEditingController();
  final _address = TextEditingController();
  final _empId = TextEditingController();
  final _designation = TextEditingController();
  final _department = TextEditingController();
  final _doj = TextEditingController();
  final _manager = TextEditingController();

  late Future<Map<String, dynamic>> _future;
  File? _profileImage;
  String? gender;
  bool _init = false;
  bool _saving = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    _future = AuthService.getMyProfile();
  }

  void _initData(Map<String, dynamic> d) {
    if (_init) return;

    _name.text = d['name'] ?? '';
    _email.text = d['email'] ?? '';
    _blood.text = d['bloodGroup'] ?? '';
    _dob.text = AppHelpers.formatDate(d['dateOfBirth']);
    _contact.text = d['contactNumber'] ?? '';
    _emergency.text = d['emergencyContact'] ?? '';
    _address.text = d['address'] ?? '';

    _empId.text = d['employeeId'] ?? '';
    _designation.text = d['designation'] ?? '';
    _department.text = d['department'] ?? '';
    _doj.text = AppHelpers.formatDate(d['dateOfJoining']);
    _manager.text = d['reportingManager'] ?? '';

    gender = d['gender'];

    _init = true;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await AuthService.updateProfile({
        "name": _name.text.trim(),
        "email": _email.text.trim(),
        "bloodGroup": _blood.text.trim(),

        "dateOfBirth": _dob.text.isEmpty ? null : _dob.text,
        "dateOfJoining": _doj.text.isEmpty ? null : _doj.text,

        "gender": gender ?? "",

        "contactNumber": _contact.text.trim(),
        "emergencyContact": _emergency.text.trim(),
        "address": _address.text.trim(),

        "employeeId": _empId.text.trim(),
        "designation": _designation.text.trim(),
        "department": _department.text.trim(),
        "reportingManager": _manager.text.trim(),
      }, _profileImage);

      showTopMessage("Profile updated", isError: false);
      Navigator.pop(context);
    } catch (e) {
      showTopMessage("Update failed", isError: true);
    }

    if (mounted) setState(() => _saving = false);
  }

Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();

  final picked = await picker.pickImage(
    source: source,

    // reduce size
    imageQuality: 40,
    maxWidth: 800,
    maxHeight: 800,
  );

  if (picked != null) {
    setState(() {
      _profileImage = File(picked.path);
    });
  }
}
  String? getProfileImageUrl(Map<String, dynamic> data) {
    final path = data["profileImage"];
    if (path == null || path.isEmpty) return "";

    final proPath = path.replaceFirst("/uploads/", "");

    return "${ApiConstants.Uploaded}$proPath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (s.hasError) {
            return const Center(child: Text("Error loading profile"));
          }

          final d = s.data ?? {};
          _initData(d);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey.shade300,

                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (getProfileImageUrl(d) != null
                                            ? NetworkImage(
                                                getProfileImageUrl(d)!,
                                              )
                                            : null)
                                        as ImageProvider?,

                              child:
                                  (_profileImage == null &&
                                      getProfileImageUrl(d) == null)
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("Select Image"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.camera_alt,
                                              ),
                                              title: const Text("Camera"),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage(ImageSource.camera);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.photo_library,
                                              ),
                                              title: const Text("Gallery"),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage(ImageSource.gallery);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 15,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// 🔹 PERSONAL DETAILS
                      Text(
                        "Personal Details",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 10),

                      field("Name", _name),
                      field("Email", _email),
                      field("Blood Group", _blood),
                      dateField("Date of Birth", _dob),

                      CustomFormWidgets.label(context, "Gender"),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ["Male", "Female", "Other"]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => gender = v),
                      ),

                      const SizedBox(height: 12),
                      field("Contact Number", _contact),
                      field("Emergency Contact", _emergency),
                      field("Address", _address),

                      const SizedBox(height: 20),

                      /// 🔹 EMPLOYEE DETAILS
                      Text(
                        "Employment Details",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 10),

                      field("Employee ID", _empId),
                      field("Designation", _designation),
                      field("Department", _department),
                      dateField("Date of Joining", _doj),
                      field("Reporting Manager", _manager),

                      const SizedBox(height: 25),

                      /// ✅ SAVE BUTTON (VISIBLE NOW)
                      Center(
                        child: AppButton(
                          text: "Save Changes",
                          isLoading: _saving,
                          onPressed: _saving ? null : _save,
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

  Widget field(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormWidgets.label(context, label),
        const SizedBox(height: 8),
        CustomTextField(controller: c),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget dateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormWidgets.label(context, label),
        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          readOnly: true, // prevent typing
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.calendar_month),
          ),

          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
            );

            if (pickedDate != null) {
              controller.text =
                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
            }
          },
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}
