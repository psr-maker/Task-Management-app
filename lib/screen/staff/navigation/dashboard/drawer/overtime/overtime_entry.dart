import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class ApplyOvertime extends StatefulWidget {
  const ApplyOvertime({super.key});

  @override
  State<ApplyOvertime> createState() => _ApplyOvertimeState();
}

class _ApplyOvertimeState extends State<ApplyOvertime> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _dateController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _reasonController = TextEditingController();

  List<UserModel> filteredUsers = [];
  List<UserModel> users = [];
  UserModel? selectedUser;

  bool showEmployeeList = false;
  bool _loading = false;
  bool _loadingUsers = true;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  String? _topMessage;
  int? selectedUid;
  String? selectedDept;


  @override
  void initState() {
    super.initState();
    _loadUsers();
    filteredUsers = users;
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

  Future<void> _loadUsers() async {
    try {
      final result = await SuperAdminService.getAllUsers();

      setState(() {
        users = result;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _loadingUsers = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedUid == null) {
      showTopMessage("Please select an employee", isError: true);
      return;
    }

    try {
      setState(() => _loading = true);

      await AdminService.applyOvertime(
        uid: selectedUid!,
        dept: selectedDept!,
        date: _dateController.text,
        startTime: _startController.text,
        endTime: _endController.text,
        reason: _reasonController.text,
      );

      if (!mounted) return;

      showTopMessage("Overtime request submitted successfully", isError: false);
      Navigator.pop(context);

      setState(() {
        _dateController.clear();
        _startController.clear();
        _endController.clear();
        _reasonController.clear();
        _nameController.clear();
        _deptController.clear();
        selectedUid = null;
        selectedDept = null;
      });
    } catch (e) {
      showTopMessage(
        "Error submitting overtime request: ${e.toString()}",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.secondary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      _dateController.text =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.secondary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      controller.text =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _startController.dispose();
    _endController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      validator: validator,
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(
        hintStyle: Theme.of(context).textTheme.headlineSmall,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Overtime Entry"),
      ),
      body: _loadingUsers
          ? const Center(child: RotatingFlower())
          : Stack(
              children: [
                Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CustomFormWidgets.label(context, "Name"),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_drop_down),
                            onPressed: () {
                              setState(() {
                                showEmployeeList = !showEmployeeList;
                                filteredUsers = List.from(users);
                              });
                            },
                          ),
                          hintStyle: Theme.of(context).textTheme.headlineSmall,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 25, 77, 38),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 25, 77, 38),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            showEmployeeList = true;

                            filteredUsers = users.where((u) {
                              return u.name.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ) ||
                                  u.department.toLowerCase().contains(
                                    value.toLowerCase(),
                                  );
                            }).toList();
                          });
                        },
                        validator: (v) => v!.isEmpty ? "Select employee" : null,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      if (showEmployeeList)
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];

                              return ListTile(
                                title: Text(
                                  "${user.name} - ${user.department}",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedUid = user.userId;
                                    selectedDept = user.department;

                                    _nameController.text = user.name;
                                    _deptController.text = user.department;

                                    showEmployeeList = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 15),
                      CustomFormWidgets.label(context, "Department"),
                      const SizedBox(height: 5),

                      CustomFormWidgets.textField(
                        context,
                        _deptController,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 15),
                      CustomFormWidgets.label(context, "Date"),
                      const SizedBox(height: 5),
                      _buildField(
                        label: "Date",
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        validator: (v) => v!.isEmpty ? "Select date" : null,
                      ),

                      const SizedBox(height: 15),
                      CustomFormWidgets.label(context, "From Time"),
                      const SizedBox(height: 5),
                      _buildField(
                        label: "From Time",
                        controller: _startController,
                        readOnly: true,
                        onTap: () => _pickTime(_startController),
                        validator: (v) =>
                            v!.isEmpty ? "Select from time" : null,
                      ),

                      const SizedBox(height: 15),
                      CustomFormWidgets.label(context, "To Time"),
                      const SizedBox(height: 5),
                      _buildField(
                        label: "To Time",
                        controller: _endController,
                        readOnly: true,
                        onTap: () => _pickTime(_endController),
                        validator: (v) => v!.isEmpty ? "Select to time" : null,
                      ),

                      const SizedBox(height: 15),
                      CustomFormWidgets.label(context, "Reason"),
                      const SizedBox(height: 5),
                      _buildField(
                        label: "Reason",
                        controller: _reasonController,
                        maxLines: 4,
                        validator: (v) =>
                            v!.trim().isEmpty ? "Enter reason" : null,
                      ),

                      const SizedBox(height: 25),
                      Center(
                        child: AppButton(
                          text: "Submit",
                          isLoading: _loading,
                          onPressed: _loading ? null : _submit,
                          color: Theme.of(context).colorScheme.secondary,
                          txtcolor: Theme.of(context).colorScheme.onPrimary,
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
    );
  }
}
