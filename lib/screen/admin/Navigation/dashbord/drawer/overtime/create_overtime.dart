import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class ManagerOvertimeCreate extends StatefulWidget {
  final String dept;
  const ManagerOvertimeCreate({super.key, required this.dept});

  @override
  State<ManagerOvertimeCreate> createState() => _ManagerOvertimeCreateState();
}

class _ManagerOvertimeCreateState extends State<ManagerOvertimeCreate> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _deptController = TextEditingController();

  final _dateController = TextEditingController();

  final _startController = TextEditingController();

  final _endController = TextEditingController();

  final _reasonController = TextEditingController();

  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];

  int? selectedUid;
  String? selectedDept;
  String? managerDepartment;
  bool showEmployeeList = false;
  bool loadingUsers = true;
  bool loading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final result = await SuperAdminService.getAllUsers();

      if (!mounted) return;

      final departmentUsers = result.where((user) {
        return user.department.trim().toLowerCase() ==
            widget.dept.trim().toLowerCase();
      }).toList();

      setState(() {
        users = departmentUsers;
        filteredUsers = departmentUsers;
        loadingUsers = false;
      });
    } catch (e) {
      debugPrint("Load department employees error: $e");

      if (!mounted) return;

      setState(() {
        loadingUsers = false;
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedUid == null) {
      showTopMessage("Please select an employee", isError: true);
      return;
    }

    if (!_isValidTimeRange()) {
      showTopMessage("To time must be after From time", isError: true);
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      // API expects HH:mm:ss for TimeSpan
      final fromTime = _startController.text.length == 5
          ? "${_startController.text}:00"
          : _startController.text;

      final toTime = _endController.text.length == 5
          ? "${_endController.text}:00"
          : _endController.text;

      await OvertimeService.createOvertime(
        uid: selectedUid!,
        dept: selectedDept!,
        date: DateTime.parse(_dateController.text),
        fromTime: fromTime,
        toTime: toTime,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      showTopMessage("Overtime request sent successfully", isError: false);
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Create overtime error: $e");

      if (!mounted) return;
      showTopMessage(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
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

  bool _isValidTimeRange() {
    try {
      final start = _startController.text.split(":");

      final end = _endController.text.split(":");

      final startMinutes = int.parse(start[0]) * 60 + int.parse(start[1]);

      final endMinutes = int.parse(end[0]) * 60 + int.parse(end[1]);

      return endMinutes > startMinutes;
    } catch (_) {
      return true;
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    _dateController.text =
        "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    setState(() {});
  }

  Future<void> pickTime(TextEditingController controller) async {
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

    if (time == null) return;

    controller.text =
        "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}";

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _dateController.dispose();
    _startController.dispose();
    _endController.dispose();
    _reasonController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Overtime Request"),
      ),
      body: Stack(
        children: [
          loadingUsers
              ? const Center(child: RotatingFlower())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CustomFormWidgets.label(context, 'Staff'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _nameController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: _inputDecoration(
                        "Select employee",
                        Icons.person,
                        suffix: Icons.keyboard_arrow_down,
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedUid = null;
                          selectedDept = null;
                          _deptController.clear();
              
                          showEmployeeList = true;
              
                          filteredUsers = users.where((user) {
                            return user.name.toLowerCase().contains(
                              value.toLowerCase(),
                            );
                          }).toList();
                        });
                      },
                      validator: (value) {
                        if (selectedUid == null) {
                          return "Select employee";
                        }
                        return null;
                      },
                    ),
              
                    if (showEmployeeList)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
              
                            return ListTile(
                              leading: const CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.person, size: 15),
                              ),
                              title: Text(
                                user.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              subtitle: Text(
                                user.department,
                                style: Theme.of(context).textTheme.labelSmall,
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
              
                    const SizedBox(height: 18),
                    CustomFormWidgets.label(context, 'Department'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _deptController,
                      readOnly: true,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: _inputDecoration(
                        "Department",
                        Icons.business_outlined,
                      ),
                    ),
              
                    const SizedBox(height: 18),
              
                    CustomFormWidgets.label(context, 'Overtime Date'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: pickDate,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: _inputDecoration(
                        "Select date",
                        Icons.calendar_today_outlined,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Select date"
                          : null,
                    ),
              
                    const SizedBox(height: 18),
              
                    CustomFormWidgets.label(context, 'From Time'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _startController,
                      readOnly: true,
                      style: Theme.of(context).textTheme.headlineLarge,
                      onTap: () => pickTime(_startController),
                      decoration: _inputDecoration(
                        "Select start time",
                        Icons.schedule_outlined,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Select start time"
                          : null,
                    ),
              
                    const SizedBox(height: 18),
              
                    CustomFormWidgets.label(context, 'To Time'),
              
                    TextFormField(
                      controller: _endController,
                      readOnly: true,
                      style: Theme.of(context).textTheme.headlineLarge,
                      onTap: () => pickTime(_endController),
                      decoration: _inputDecoration(
                        "Select end time",
                        Icons.schedule_outlined,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Select end time"
                          : null,
                    ),
              
                    const SizedBox(height: 18),
              
                    CustomFormWidgets.label(context, 'Reason'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: _inputDecoration(
                        "Enter overtime reason",
                        Icons.note_alt_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Enter reason";
                        }
              
                        return null;
                      },
                    ),
              
                    const SizedBox(height: 28),
              
                    AppButton(
                      text: "Send Request",
                      isLoading: loading,
                      onPressed: loading ? null : submit,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 20 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Msgsnackbar(
               context,
                message: _topMessage!,
                isError: _isErrorMessage,
                backgroundColor: _isErrorMessage
                    ? Colors.red
                    : Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    IconData? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.labelSmall,
      prefixIcon: Icon(icon, size: 15),
      suffixIcon: suffix != null ? Icon(suffix) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 25, 77, 38)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 25, 77, 38),
          width: 1.5,
        ),
      ),
    );
  }
}
