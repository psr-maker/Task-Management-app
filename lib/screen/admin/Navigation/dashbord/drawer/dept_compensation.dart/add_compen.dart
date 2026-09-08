import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class CreateExtraWorkPage extends StatefulWidget {
  final String department;

  const CreateExtraWorkPage({super.key, required this.department});

  @override
  State<CreateExtraWorkPage> createState() => _CreateExtraWorkPageState();
}

class _CreateExtraWorkPageState extends State<CreateExtraWorkPage> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> taskList = [];
  final TextEditingController expectedHoursController = TextEditingController();

  final TextEditingController reasonController = TextEditingController();

  int? selectedStaffId;

  String? selectedTaskCode;
  DateTime? selectedDate;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  String? selectedWorkType;

  List<dynamic> staffList = [];

  bool isLoadingStaff = false;
  bool isLoadingTasks = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStaff();
    });
  }

  @override
  void dispose() {
    expectedHoursController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    if (!mounted) return;

    setState(() {
      isLoadingStaff = true;
    });

    try {
      final result = await AdminService.getEmployeesByDepartment(
        widget.department,
      );

      if (!mounted) return;

      setState(() {
        staffList = result;
      });
    } catch (e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showMessage('Failed to load staff: ${e.toString()}');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoadingStaff = false;
      });
    }
  }

  Future<void> _loadTasksForStaff(int staffId) async {
    setState(() {
      isLoadingTasks = true;
      taskList = [];
      selectedTaskCode = null;
    });

    try {
      final result = await AdminService.getAdminTasks(staffId);

      if (!mounted) return;

      setState(() {
        taskList = result;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to load tasks: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTasks = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
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
      setState(() {
        startTime = time;
      });

      _calculateExpectedHours();
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay.now(),
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
      setState(() {
        endTime = time;
      });

      _calculateExpectedHours();
    }
  }

  void _calculateExpectedHours() {
    if (startTime == null || endTime == null) {
      expectedHoursController.clear();
      return;
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    final difference = endMinutes - startMinutes;

    if (difference <= 0) {
      expectedHoursController.clear();
      return;
    }

    final hours = difference / 60;

    setState(() {
      expectedHoursController.text = hours.toStringAsFixed(2);
    });
  }

  Future<void> _submit() async {
    if (isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedStaffId == null) {
      _showMessage('Please select staff');
      return;
    }
    if (selectedTaskCode == null) {
      _showMessage('Please select task');
      return;
    }

    if (selectedDate == null) {
      _showMessage('Please select work date');
      return;
    }

    if (selectedWorkType == null) {
      _showMessage('Please select work type');
      return;
    }

    if (startTime == null) {
      _showMessage('Please select start time');
      return;
    }

    if (endTime == null) {
      _showMessage('Please select end time');
      return;
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    if (endMinutes <= startMinutes) {
      _showMessage('End time must be after start time');
      return;
    }

    final expectedHours = double.tryParse(expectedHoursController.text);

    if (expectedHours == null || expectedHours <= 0) {
      _showMessage('Expected hours could not be calculated');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Backend TimeSpan format
      final startTimeString =
          '${startTime!.hour.toString().padLeft(2, '0')}:'
          '${startTime!.minute.toString().padLeft(2, '0')}:00';

      final endTimeString =
          '${endTime!.hour.toString().padLeft(2, '0')}:'
          '${endTime!.minute.toString().padLeft(2, '0')}:00';

      await OvertimeService.createExtraWork(
        staffId: selectedStaffId!,
        taskId: selectedTaskCode!,
        workType: selectedWorkType!,
        workDate: selectedDate!,
        expectedHours: expectedHours,
        startTime: startTimeString,
        endTime: endTimeString,
        reason: reasonController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Extra work request sent successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Extra Work'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CustomFormWidgets.label(context, 'Staff'),

            const SizedBox(height: 8),

            _dropdownContainer(
              child: DropdownButtonFormField<int>(
                value: selectedStaffId,
                isExpanded: true,
                decoration: _inputDecoration(
                  'Select Staff',
                  Icons.person_outline_rounded,
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                hint: Text(
                  isLoadingStaff ? 'Loading staff...' : 'Select staff',
                ),
                items: staffList.map((staff) {
                  return DropdownMenuItem<int>(
                    value: staff.userId,
                    child: Text(staff.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: isLoadingStaff
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          selectedStaffId = value;
                          selectedTaskCode = null;
                          taskList = [];
                        });

                        _loadTasksForStaff(value);
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Select staff';
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(height: 18),

            CustomFormWidgets.label(context, 'Task'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTaskCode,
              isExpanded: true,
              decoration: _inputDecoration('Task', Icons.task_alt_outlined),
              style: Theme.of(context).textTheme.headlineSmall,
              hint: Text(
                selectedStaffId == null
                    ? 'Select staff first'
                    : isLoadingTasks
                    ? 'Loading tasks...'
                    : taskList.isEmpty
                    ? 'No tasks found'
                    : 'Select task',
              ),
              items: taskList
                  .map((task) {
                    final taskCode = task['taskCode']?.toString();

                    if (taskCode == null || taskCode.isEmpty) {
                      return null;
                    }

                    return DropdownMenuItem<String>(
                      value: taskCode,
                      child: Text(
                        task['task']?.toString() ?? 'Untitled Task',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .whereType<DropdownMenuItem<String>>()
                  .toList(),
              onChanged:
                  selectedStaffId == null || isLoadingTasks || taskList.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        selectedTaskCode = value;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Select task';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            CustomFormWidgets.label(context, 'Work Date'),

            const SizedBox(height: 8),

            _dateField(),

            const SizedBox(height: 18),

            CustomFormWidgets.label(context, 'Work Type'),

            const SizedBox(height: 8),

            _dropdownContainer(
              child: DropdownButtonFormField<String>(
                value: selectedWorkType,
                isExpanded: true,
                decoration: _inputDecoration(
                  'Select Work Type',
                  Icons.work_history_outlined,
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                hint: const Text('Select work type'),
                items: [
                  DropdownMenuItem(
                    value: 'WeeklyOff',
                    child: Text(
                      'Weekly Off',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'PublicHoliday',
                    child: Text(
                      'Public Holiday',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'CompanyHoliday',
                    child: Text(
                      'Company Holiday',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text(
                      'Other',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedWorkType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Select work type';
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(height: 18),

            CustomFormWidgets.label(context, 'Work Time'),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: 'Start Time',
                    icon: Icons.login_rounded,
                    time: startTime,
                    onTap: _selectStartTime,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _timeField(
                    label: 'End Time',
                    icon: Icons.logout_rounded,
                    time: endTime,
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            CustomFormWidgets.label(context, 'Expected Hours'),

            const SizedBox(height: 8),
            TextFormField(
              controller: expectedHoursController,
              readOnly: true,
              decoration: _inputDecoration(
                'Expected Hours',
                Icons.timer_outlined,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Select start and end time';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            CustomFormWidgets.label(context, 'Reason'),

            const SizedBox(height: 8),

            TextFormField(
              controller: reasonController,
              maxLines: 4,
              decoration: _inputDecoration(
                'Enter reason',
                Icons.notes_rounded,
              ).copyWith(alignLabelWithHint: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter reason';
                }

                return null;
              },
            ),

            const SizedBox(height: 28),

            AppButton(
              text: 'Send Request',
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : _submit,
              color: Theme.of(context).colorScheme.secondary,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 15),

      filled: true,
      fillColor: Colors.transparent,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 1,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 1,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 1.4,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),

      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: _selectDate,
      child: InputDecorator(
        decoration: _inputDecoration(
          'Work Date',
          Icons.calendar_today_outlined,
        ),
        child: Text(
          selectedDate == null
              ? 'Select work date'
              : DateFormat('dd/MM/yyyy').format(selectedDate!),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: InputDecorator(
        decoration: _inputDecoration(label, icon),
        child: Text(
          time == null ? 'Select time' : time.format(context),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
