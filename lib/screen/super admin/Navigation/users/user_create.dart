import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/rolesmodel.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

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

  // =========================
  // CREATE USER
  // =========================

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

  // =========================
  // FETCH DEPARTMENTS
  // =========================

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

  // =========================
  // FETCH ROLES
  // =========================

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

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New User"),

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 40,
        ),

        child: SingleChildScrollView(
          child: Stack(
            children: [

              Column(
                children: [

                  // USER ICON
                  const Center(
                    child: Icon(
                      Icons.person_add,
                      size: 65,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(10),

                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        width: 2,
                      ),
                    ),

                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          // =====================
                          // USERNAME
                          // =====================

                          Text(
                            "Enter UserName",
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge,
                          ),

                          const SizedBox(height: 8),

                          CustomTextField(
                            controller:
                                usernameController,
                          ),

                          const SizedBox(height: 20),

                          // =====================
                          // EMAIL
                          // =====================

                          Text(
                            "Enter Email",
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge,
                          ),

                          const SizedBox(height: 8),

                          CustomTextField(
                            controller:
                                emailController,
                            isEmail: true,
                          ),

                          const SizedBox(height: 20),

                          // =====================
                          // DEPARTMENT
                          // =====================

                          Text(
                            "Select Department",
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge,
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                            ),

                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius
                                      .circular(8),

                              border: Border.all(
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .primary,
                              ),
                            ),

                            child:
                                DropdownButton<String>(
                              value:
                                  selectedDepartment,

                              isExpanded: true,

                              underline:
                                  const SizedBox(),

                              hint: Text(
                                "Select Department",
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .headlineSmall,
                              ),

                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .headlineSmall,

                              items: departments
                                  .map((dept) {
                                return DropdownMenuItem<
                                    String>(
                                  value: dept,

                                  child: Text(
                                    dept,

                                    style: Theme.of(
                                      context,
                                    )
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                );
                              }).toList(),

                              onChanged: (value) {
                                setState(() {
                                  selectedDepartment =
                                      value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // =====================
                          // ROLE
                          // =====================

                          Text(
                            "Select Role",
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge,
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                            ),

                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius
                                      .circular(8),

                              border: Border.all(
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .primary,
                              ),
                            ),

                            child:
                                DropdownButton<Role>(
                              value: selectedRole,

                              isExpanded: true,

                              underline:
                                  const SizedBox(),

                              hint: Text(
                                "Select Role",
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .headlineSmall,
                              ),

                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .headlineSmall,

                              items: roles.map((role) {
                                return DropdownMenuItem<
                                    Role>(
                                  value: role,

                                  child: Text(
                                    role.name,

                                    style: Theme.of(
                                      context,
                                    )
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                );
                              }).toList(),

                              onChanged: (value) {
                                setState(() {
                                  selectedRole =
                                      value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 40),

                          // =====================
                          // CREATE BUTTON
                          // =====================

                          Center(
                            child: AppButton(
                              text: "Create User",

                              isLoading:
                                  _isLoading,

                              onPressed: _isLoading
                                  ? null
                                  : createUser,

                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .secondary,

                              txtcolor: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // =========================
              // TOP MESSAGE
              // =========================

              if (_topMessage != null)
                AnimatedPositioned(
                  top: _showTopMessage
                      ? 0
                      : -120,

                  left: 16,
                  right: 16,

                  duration:
                      const Duration(
                    milliseconds: 300,
                  ),

                  child: Msgsnackbar(
                    context,

                    message:
                        _topMessage!,

                    isError:
                        _isErrorMessage,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}