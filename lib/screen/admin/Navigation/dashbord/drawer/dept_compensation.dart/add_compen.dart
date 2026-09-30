import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class CreateExtraWorkPage extends StatefulWidget {
  final String department;
  final bool forLeaders;

  const CreateExtraWorkPage({
    super.key,
    required this.department,
    this.forLeaders = false,
  });

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
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  String? selectedWorkType;

  List<UserModel> staffList = [];

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
      final List<UserModel> result;
      if (widget.forLeaders) {
        final users = await SuperAdminService.getAllUsers();
        result = users.where((user) {
          if (!AppRoles.isScoreLeader(user.role)) return false;
          return user.status.trim().toLowerCase() != "inactive";
        }).toList()
          ..sort((a, b) {
            final roleCompare = AppRoles.leaderLabel(
              a.role,
            ).compareTo(AppRoles.leaderLabel(b.role));
            if (roleCompare != 0) return roleCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
      } else {
        result = await AdminService.getEmployeesByDepartment(
          widget.department,
        );
      }

      if (!mounted) return;

      setState(() {
        staffList = result;
      });
    } catch (e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showTopMessage(
          widget.forLeaders
              ? "Failed to load managers and division heads: ${e.toString()}"
              : "Failed to load staff: ${e.toString()}",
          isError: true,
        );
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
      final result = widget.forLeaders
          ? await _tasksForLeader(staffId)
          : await AdminService.getAdminTasks(staffId);

      if (!mounted) return;

      setState(() {
        taskList = result;
      });
    } catch (e) {
      if (!mounted) return;

      showTopMessage("Failed to load tasks: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTasks = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _tasksForLeader(int staffId) async {
    try {
      return await AdminService.getAdminTasks(staffId);
    } catch (_) {}

    final data = await SuperAdminService.getAllTasks();
    final raw = data['tasks'] ??
        data['Tasks'] ??
        data['result'] ??
        data['Result'] ??
        data['data'] ??
        data['Data'];
    if (raw is! List) return [];

    bool assignedTo(Map<String, dynamic> task) {
      final people = task['assignedTo'] ?? task['AssignedTo'];
      if (people is List) {
        for (final person in people) {
          if (person is! Map) continue;
          final id = int.tryParse(
            '${person['userId'] ?? person['UserId'] ?? person['id'] ?? ''}',
          );
          if (id == staffId) return true;
        }
      }
      final direct = int.tryParse(
        '${task['userId'] ?? task['staffId'] ?? task['employeeId'] ?? ''}',
      );
      return direct == staffId;
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(assignedTo)
        .toList();
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
      showTopMessage(
        widget.forLeaders
            ? "Please select a department manager or division head"
            : "Please select staff",
        isError: true,
      );
      return;
    }
    if (selectedTaskCode == null) {
      showTopMessage("Please select task", isError: true);
      return;
    }

    if (selectedDate == null) {
      showTopMessage("'Please select work date", isError: true);
      return;
    }

    if (selectedWorkType == null) {
      showTopMessage("Please select work type", isError: true);
      return;
    }

    if (startTime == null) {
      showTopMessage("Please select start time", isError: true);
      return;
    }

    if (endTime == null) {
      showTopMessage("Please select end time", isError: true);
      return;
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    if (endMinutes <= startMinutes) {
      showTopMessage("End time must be after start time", isError: true);
      return;
    }

    final expectedHours = double.tryParse(expectedHoursController.text);

    if (expectedHours == null || expectedHours <= 0) {
      showTopMessage('Expected hours could not be calculated', isError: true);
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
        asDirector: widget.forLeaders,
      );

      if (!mounted) return;

      showTopMessage("Compensation request sent successfully", isError: false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      showTopMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.forLeaders ? 'Compensation Work' : 'Create Extra Work',
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CustomFormWidgets.label(
                  context,
                  widget.forLeaders
                      ? 'Department Manager / Division Head'
                      : 'Staff',
                ),

                const SizedBox(height: 8),

                _dropdownContainer(
                  child: DropdownButtonFormField<int>(
                    value: selectedStaffId,
                    isExpanded: true,
                    itemHeight: widget.forLeaders ? 72 : kMinInteractiveDimension,
                    decoration: _inputDecoration(
                      widget.forLeaders
                          ? 'Select manager or division head'
                          : 'Select Staff',
                      Icons.person_outline_rounded,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                    selectedItemBuilder: widget.forLeaders
                        ? (context) {
                            return staffList.map((staff) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  staff.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          }
                        : null,
                    hint: Text(
                      isLoadingStaff
                          ? (widget.forLeaders
                                ? 'Loading managers and division heads...'
                                : 'Loading staff...')
                          : staffList.isEmpty && widget.forLeaders
                          ? 'No department managers or division heads'
                          : widget.forLeaders
                          ? 'Select manager or division head'
                          : 'Select staff',
                    ),
                    items: staffList.map((staff) {
                      if (!widget.forLeaders) {
                        return DropdownMenuItem<int>(
                          value: staff.userId,
                          child: Text(
                            staff.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }

                      final department = staff.department.trim();

                      return DropdownMenuItem<int>(
                        value: staff.userId,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              staff.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (department.isNotEmpty)
                              Text(
                                department,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
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
                        return widget.forLeaders
                            ? 'Select manager or division head'
                            : 'Select staff';
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
                      selectedStaffId == null ||
                          isLoadingTasks ||
                          taskList.isEmpty
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
