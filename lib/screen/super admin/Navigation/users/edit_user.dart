import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class EditUser extends StatefulWidget {
  final dynamic user;

  const EditUser({super.key, required this.user});

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  late TextEditingController usernameController;
  late TextEditingController emailController;

  bool _isLoading = false;
  String? selectedDepartment;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  List<String> departments = [];

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

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    usernameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    selectedDepartment = widget.user.department;
  }

  void _fetchDepartments() async {
    try {
      final deptList = await SuperAdminService().getDepartments();
      setState(() {
        departments = deptList.map((d) => d.departmentName).toSet().toList();
      });
    } catch (e) {
      debugPrint("Failed to fetch departments: $e");
      showTopMessage("Failed to load departments", isError: true);
    }
  }

  Future<void> updateUser() async {
    setState(() => _isLoading = true);

    try {
      final response = await SuperAdminService.updateUser(
        userId: widget.user.userId,
        name: usernameController.text.trim(),
        email: emailController.text.trim(),
        department: selectedDepartment!,
      );

      if (response['message'] == "User updated successfully") {
        showTopMessage("User updated successfully", isError: false);
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      } else {
        showTopMessage("Failed to update user");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text("Edit User"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Icon(
                      Icons.edit,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CustomTextField(controller: usernameController),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: emailController,
                            isEmail: true,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            style: Theme.of(context).textTheme.bodyLarge,
                            value: selectedDepartment,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Department",
                            ),
                            items: departments
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      d,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedDepartment = value);
                            },
                          ),
                          const SizedBox(height: 40),
                          AppButton(
                            text: "Update User",
                            isLoading: _isLoading,
                            onPressed: updateUser,
                            color: Theme.of(context).colorScheme.secondary,
                            txtcolor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  iconColor: Theme.of(context).colorScheme.onPrimary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
