import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class CreateUsers extends StatefulWidget {
  final String role;
  const CreateUsers({super.key, required this.role});

  @override
  State<CreateUsers> createState() => _CreateUsersState();
}

class _CreateUsersState extends State<CreateUsers> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  List<String> departments = [];
  bool _isLoading = false;

  String? selectedDepartment;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

  Future<void> createUser() async {
    if (usernameController.text.trim().isEmpty) {
      showTopMessage("Please enter username", isError: true);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showTopMessage("Please enter email", isError: true);
      return;
    }

    if (selectedDepartment == null) {
      showTopMessage("Please select department", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService().createUser(
        name: usernameController.text.trim(),
        email: emailController.text.trim(),
        department: selectedDepartment!,
        role: widget.role,
      );

      showTopMessage(
        response['message'] ?? "User created successfully 🎉",
        isError: false,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showTopMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New ${widget.role}"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Stack(
            children: [
              Column(
                children: [
                  Center(child: Icon(Icons.person_add, size: 65)),
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Enter UserName",
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(controller: usernameController),
                            const SizedBox(height: 20),

                            Text(
                              "Enter Email",
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: emailController,
                              isEmail: true,
                            ),
                            const SizedBox(height: 20),

                            Text(
                              "Select Department",
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: selectedDepartment,
                                isExpanded: true,
                                underline: const SizedBox(),
                                hint: Text(
                                  "Select Department",
                                        style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                       style: Theme.of(context).textTheme.headlineSmall,
                                items: departments.map((dept) {
                                  return DropdownMenuItem(
                                    value: dept,
                                    child: Text(
                                      dept,
                                           style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => selectedDepartment = value);
                                },
                              ),
                            ),

                            const SizedBox(height: 40),

                            Center(
                              child: AppButton(
                                text: "Create ${widget.role}",
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : createUser,
                                color: Theme.of(context).colorScheme.secondary,
                                txtcolor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    iconColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
