import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/role_hierarchy.dart';
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
  final _staffFocus = FocusNode();

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
    _staffFocus.addListener(() {
      if (!mounted) return;
      if (_staffFocus.hasFocus) {
        setState(() {
          showEmployeeList = true;
          _filterStaff(_nameController.text);
        });
        return;
      }
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || _staffFocus.hasFocus) return;
        setState(() => showEmployeeList = false);
      });
    });
    loadUsers();
  }

  void _filterStaff(String value) {
    final query = value.trim().toLowerCase();
    filteredUsers = users.where((user) {
      final name = user.name.toLowerCase();
      final dept = user.department.toLowerCase();
      return query.isEmpty || name.contains(query) || dept.contains(query);
    }).toList();
  }

  Future<void> loadUsers() async {
    try {
      final result = await SuperAdminService.getAllUsers();
      final eligibility = await loadOvertimeEligibility();

      if (!mounted) return;

      final departmentUsers = result.where((user) {
        return user.department.trim().toLowerCase() ==
                widget.dept.trim().toLowerCase() &&
            !eligibility.excludesUser(user);
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
    _staffFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final web = WebPushedChrome.isWeb(context);
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: web
          ? null
          : AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Overtime Requirement"),
      ),
      body: WebFormPage.adapt(
        context,
        title: 'Add overtime',
        subtitle: 'Request extra hours for a staff member',
        child: Stack(
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
                      focusNode: _staffFocus,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: _inputDecoration(
                        "Staff name",
                        Icons.person,
                        suffix: Icons.keyboard_arrow_down,
                      ),
                      onTap: () {
                        setState(() {
                          showEmployeeList = true;
                          _filterStaff(_nameController.text);
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedUid = null;
                          selectedDept = null;
                          _deptController.clear();
                          showEmployeeList = true;
                          _filterStaff(value);
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
                          color: WebTheme.surfaceOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WebTheme.lineOf(context)),
                        ),
                        child: filteredUsers.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'No staff in this department',
                                  style: TextStyle(color: WebTheme.mutedOf(context)),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      user.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: WebTheme.inkOf(context),
                                      ),
                                    ),
                                    subtitle: Text(
                                      user.department,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: WebTheme.mutedOf(context),
                                      ),
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
                    const SizedBox(height: 16),
                    _fieldPair(
                      _timeField(
                        label: 'From time',
                        controller: _startController,
                        hint: 'From time',
                        empty: 'Select from time',
                      ),
                      _timeField(
                        label: 'To time',
                        controller: _endController,
                        hint: 'To time',
                        empty: 'Select to time',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldPair(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomFormWidgets.label(context, 'Date'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: pickDate,
                            style: Theme.of(context).textTheme.headlineLarge,
                            decoration: _inputDecoration(
                              'Select date',
                              Icons.calendar_today_outlined,
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                ? 'Select date'
                                : null,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomFormWidgets.label(context, 'Reason'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _reasonController,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.headlineLarge,
                            decoration: _inputDecoration(
                              'Enter reason',
                              Icons.note_alt_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter reason';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      text: "Send Request",
                      isLoading: loading,
                      onPressed: loading ? null : submit,
                      color: WebTheme.brand,
                      txtcolor: Colors.white,
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
      ),
    );
  }

  Widget _fieldPair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [left, const SizedBox(height: 16), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _timeField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String empty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormWidgets.label(context, label),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => pickTime(controller),
          style: Theme.of(context).textTheme.headlineLarge,
          decoration: _inputDecoration(hint, Icons.schedule_outlined),
          validator: (value) =>
              value == null || value.isEmpty ? empty : null,
        ),
      ],
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
      filled: true,
      fillColor: WebTheme.surfaceOf(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: WebTheme.brandOf(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: WebTheme.brandOf(context),
          width: 1.5,
        ),
      ),
    );
  }
}
