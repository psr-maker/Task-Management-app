import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
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
  Role? selectedRole;
  String loginRole = "";

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  List<String> departments = [];
  List<Role> roles = [];

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
    _loadLoginRoleAndRoles();
    usernameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    selectedDepartment = widget.user.department;
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadLoginRoleAndRoles() async {
    final token = await AuthService.getToken();
    if (token != null) {
      loginRole = JwtHelper.getRole(token)?.toString().trim() ?? "";
    }
    await _loadRoles();
  }

  List<Role> get _availableRoles {
    if (loginRole == "3") {
      return roles.where((role) => role.id.toString() != "1").toList();
    }
    return List<Role>.from(roles);
  }

  Role? _matchRole(List<Role> list, dynamic raw) {
    final value = raw?.toString().trim() ?? "";
    if (value.isEmpty) return null;

    for (final role in list) {
      if (role.id.toString() == value) return role;
    }

    final lower = value.toLowerCase();
    for (final role in list) {
      if (role.name.toLowerCase() == lower) return role;
    }
    return null;
  }

  void _syncSelectedRole() {
    selectedRole = _matchRole(_availableRoles, widget.user.role);

    if (selectedRole != null) return;

    selectedRole = _matchRole(roles, widget.user.role);
  }

  Future<void> _fetchDepartments() async {
    try {
      final deptList = await SuperAdminService().getDepartments();
      if (!mounted) return;
      setState(() {
        departments = deptList.map((d) => d.departmentName).toSet().toList();
        if (selectedDepartment != null &&
            !departments.contains(selectedDepartment)) {
          departments = [...departments, selectedDepartment!];
        }
      });
    } catch (e) {
      debugPrint("Failed to fetch departments: $e");
      showTopMessage("Failed to load departments", isError: true);
    }
  }

  Future<void> _loadRoles() async {
    try {
      final rolesList = await SuperAdminService.getRoles();
      if (!mounted) return;
      setState(() {
        roles = rolesList;
        _syncSelectedRole();
      });
    } catch (e) {
      debugPrint("Failed to fetch Roles: $e");
      if (!mounted) return;
      showTopMessage("Failed to load roles", isError: true);
    }
  }

  Future<void> updateUser() async {
    if (selectedDepartment == null) {
      showTopMessage("Please select department", isError: true);
      return;
    }

    if (selectedRole == null) {
      showTopMessage("Please select role", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SuperAdminService.updateUser(
        userId: widget.user.userId,
        name: usernameController.text.trim(),
        email: emailController.text.trim(),
        department: selectedDepartment!,
        role: selectedRole!.id.toString(),
      );

      if (response['message'] == "User updated successfully") {
        showTopMessage("User updated successfully", isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context, {
          "name": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "department": selectedDepartment,
          "role": selectedRole!.id.toString(),
        });
      } else {
        showTopMessage("Failed to update user", isError: true);
      }
    } catch (e) {
      showTopMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var roleItems = _availableRoles;
    if (selectedRole != null &&
        !roleItems.any((role) => role.id == selectedRole!.id)) {
      roleItems = [selectedRole!, ...roleItems];
    }

    Role? selectedValue;
    if (selectedRole != null) {
      for (final role in roleItems) {
        if (role.id == selectedRole!.id) {
          selectedValue = role;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Edit User"),
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
                  const SizedBox(height: 20),
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
                            value:
                                departments.contains(selectedDepartment)
                                    ? selectedDepartment
                                    : null,
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
                          const SizedBox(height: 20),
                          DropdownButtonFormField<Role>(
                            style: Theme.of(context).textTheme.bodyLarge,
                            value: selectedValue,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Role",
                            ),
                            items: roleItems
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(
                                      role.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedRole = value);
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
