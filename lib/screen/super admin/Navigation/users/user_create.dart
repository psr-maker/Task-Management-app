import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class CreateUsers extends StatefulWidget {
  const CreateUsers({super.key});

  @override
  State<CreateUsers> createState() => _CreateUsersState();
}

class _CreateUsersState extends State<CreateUsers> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();

  List departments = [];
  List<Role> roles = [];

  bool _isLoading = false;

  String? selectedDepartment;
  Role? selectedRole;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _loadRoles();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void showTopMessage(
    String message, {
    bool isError = true,
  }) {
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
      showTopMessage(
        "Please enter username",
        isError: true,
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showTopMessage(
        "Please enter email",
        isError: true,
      );
      return;
    }

    if (selectedDepartment == null) {
      showTopMessage(
        "Please select department",
        isError: true,
      );
      return;
    }

    if (selectedRole == null) {
      showTopMessage(
        "Please select role",
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService().createUser(
        name: usernameController.text.trim(),
        email: emailController.text.trim(),
        department: selectedDepartment!,

        // IMPORTANT:
        // Send Role ID, not Role Name
        role: selectedRole!.id.toString(),
      );

      showTopMessage(
        response['message'] ??
            "User created successfully 🎉",
        isError: false,
      );

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      showTopMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final deptList =
          await SuperAdminService().getDepartments();

      if (!mounted) return;

      setState(() {
        departments = deptList
            .map((d) => d.departmentName)
            .toSet()
            .toList();
      });
    } catch (e) {
      debugPrint(
        "Failed to fetch departments: $e",
      );

      if (!mounted) return;

      showTopMessage(
        "Failed to load departments",
        isError: true,
      );
    }
  }

  Future<void> _loadRoles() async {
    try {
      final rolesList =
          await SuperAdminService.getRoles();

      if (!mounted) return;

      setState(() {
        roles = rolesList;
      });
    } catch (e) {
      debugPrint(
        "Failed to fetch Roles: $e",
      );

      if (!mounted) return;

      showTopMessage(
        "Failed to load roles",
        isError: true,
      );
    }
  }

  InputDecoration _field(BuildContext context, String label) {
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
      hintStyle: TextStyle(color: WebTheme.mutedOf(context), fontSize: 14),
    );
  }

  Widget _message(BuildContext context) {
    if (_topMessage == null || !_showTopMessage) return const SizedBox.shrink();
    final color = _isErrorMessage ? WebTheme.danger : const Color(0xFF166534);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          _topMessage!,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _fields(BuildContext context, bool web) {
    final ink = WebTheme.inkOf(context);
    final name = TextField(
      controller: usernameController,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: _field(context, 'Name'),
    );
    final email = TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: _field(context, 'Email'),
    );
    final department = DropdownButtonFormField<String>(
      value: departments.contains(selectedDepartment) ? selectedDepartment : null,
      isExpanded: true,
      decoration: _field(context, 'Department'),
      dropdownColor: WebTheme.surfaceOf(context),
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      items: [
        for (final dept in departments)
          DropdownMenuItem(value: dept.toString(), child: Text(dept.toString())),
      ],
      onChanged: (value) => setState(() => selectedDepartment = value),
    );
    final role = DropdownButtonFormField<Role>(
      value: roles.contains(selectedRole) ? selectedRole : null,
      isExpanded: true,
      decoration: _field(context, 'Role'),
      dropdownColor: WebTheme.surfaceOf(context),
      style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600),
      items: [
        for (final item in roles)
          DropdownMenuItem(value: item, child: Text(item.name)),
      ],
      onChanged: (value) => setState(() => selectedRole = value),
    );
    if (!web) {
      return Column(
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
    }
    return Column(
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
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
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
            text: 'Create user',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : createUser,
            color: WebTheme.brand,
            txtcolor: Colors.white,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final web = WebPushedChrome.isWeb(context);
    final fields = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: _fields(context, web),
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
                        'Add user',
                        style: TextStyle(
                          color: WebTheme.inkOf(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a staff account',
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
        _message(context),
        if (web)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
            child: fields,
          )
        else
          Expanded(child: fields),
        _actions(context),
      ],
    );
    if (web) {
      return Material(color: WebTheme.surfaceOf(context), child: body);
    }
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        title: const Text('Add New User'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: body,
    );
  }
}