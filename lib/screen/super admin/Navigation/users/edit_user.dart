import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

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

    final web = WebPushedChrome.isWeb(context);
    final ink = WebTheme.inkOf(context);
    InputDecoration field(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: WebTheme.canvasOf(context),
        labelStyle: TextStyle(
          color: WebTheme.mutedOf(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: WebTheme.brandOf(context),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: WebTheme.lineOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: WebTheme.brandOf(context), width: 1.4),
        ),
      );
    }

    final name = TextField(
      controller: usernameController,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: field('Name'),
    );
    final email = TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: field('Email'),
    );
    final department = DropdownButtonFormField<String>(
      value: departments.contains(selectedDepartment) ? selectedDepartment : null,
      isExpanded: true,
      decoration: field('Department'),
      dropdownColor: WebTheme.surfaceOf(context),
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      items: [
        for (final item in departments)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) => setState(() => selectedDepartment = value),
    );
    final role = DropdownButtonFormField<Role>(
      value: selectedValue,
      isExpanded: true,
      decoration: field('Role'),
      dropdownColor: WebTheme.surfaceOf(context),
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      items: [
        for (final item in roleItems)
          DropdownMenuItem(value: item, child: Text(item.name)),
      ],
      onChanged: (value) => setState(() => selectedRole = value),
    );
    final fields = web
        ? Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 12),
                  Expanded(child: email),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: department),
                  const SizedBox(width: 12),
                  Expanded(child: role),
                ],
              ),
            ],
          )
        : Column(
            children: [
              name,
              const SizedBox(height: 14),
              email,
              const SizedBox(height: 14),
              department,
              const SizedBox(height: 14),
              role,
            ],
          );
    final message = _topMessage == null || !_showTopMessage
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (_isErrorMessage ? WebTheme.danger : const Color(0xFF166534))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _topMessage!,
                style: TextStyle(
                  color: _isErrorMessage ? WebTheme.danger : const Color(0xFF166534),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
    final actions = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: WebTheme.mutedOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            text: 'Save changes',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : updateUser,
            color: WebTheme.brand,
            txtcolor: Colors.white,
          ),
        ],
      ),
    );
    final scrolled = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: fields,
    );
    final body = Column(
      mainAxisSize: web ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (web)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit user',
                        style: TextStyle(
                          color: WebTheme.inkOf(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usernameController.text.trim().isEmpty
                            ? 'Update account details'
                            : usernameController.text.trim(),
                        style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: WebTheme.inkOf(context)),
                ),
              ],
            ),
          ),
        message,
        if (web)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
            child: scrolled,
          )
        else
          Expanded(child: scrolled),
        actions,
      ],
    );
    if (web) {
      return Material(color: WebTheme.surfaceOf(context), child: body);
    }
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text('Edit User'),
      ),
      body: body,
    );
  }
}
