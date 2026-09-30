import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class Createtask extends StatefulWidget {
  final List<int> assignedToIds;
  final List<String>? assignedDepartments;
  final String? initialTaskName;
  final String? initialDescription;
  final String? initialGoalCode;
  final String? initialPriority;
  final String initialPerformanceType;
  final int? initialQuantity;
  final DateTime? initialAssignedAt;
  final DateTime? initialDueDate;
  final String? initialStartTime;
  final String? initialEndTime;
  final bool initialIsTask;

  const Createtask({
    super.key,
    required this.assignedToIds,
    this.assignedDepartments,
    this.initialTaskName,
    this.initialDescription,
    this.initialGoalCode,
    this.initialPriority,
    this.initialPerformanceType = "Default",
    this.initialQuantity,
    this.initialAssignedAt,
    this.initialDueDate,
    this.initialStartTime,
    this.initialEndTime,
    this.initialIsTask = false,
  });

  @override
  State<Createtask> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<Createtask> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriController = TextEditingController();
  final TextEditingController createdDateController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  final TextEditingController goalTitleController = TextEditingController();
  final TextEditingController goalStartController = TextEditingController();
  final TextEditingController goalDueController = TextEditingController();

  String? selectedGoalCode;
  List<dynamic> goals = [];
  bool isGoalLoading = false;

  DateTime? goalStartDate;
  DateTime? goalDueDate;
  String? selectedPriority;
  late String selectedPerformanceType;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool _isLoading = false;
  DateTime? createdDate;
  DateTime? dueDate;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  bool isTask = false;
  List<dynamic> goalsList = [];
  String _goalType = 'Monthly';
  bool _loadingUsers = true;
  List<UserModel> _assignableUsers = [];
  final Set<int> _monthlyAssignedIds = {};
  final List<_MonthlySubGoal> _subGoals = [];
  bool _monthsWereGenerated = false;

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(":");
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void initState() {
    super.initState();

    isTask =
        widget.initialIsTask ||
        widget.initialTaskName != null ||
        widget.initialGoalCode != null ||
        widget.initialQuantity != null ||
        widget.initialAssignedAt != null ||
        widget.initialDueDate != null;

    selectedPerformanceType = widget.initialPerformanceType;
    selectedGoalCode = widget.initialGoalCode;
    selectedPriority = widget.initialPriority ?? "Normal";
    quantityController.text = widget.initialQuantity?.toString() ?? "";
    nameController.text = widget.initialTaskName ?? "";
    descriController.text = widget.initialDescription ?? "";

    createdDate = widget.initialAssignedAt;
    if (createdDate != null) {
      createdDateController.text =
          "${createdDate!.year}-${createdDate!.month.toString().padLeft(2, '0')}-${createdDate!.day.toString().padLeft(2, '0')}";
    }

    dueDate = widget.initialDueDate;
    if (dueDate != null) {
      dueDateController.text =
          "${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}";
    }

    startTime = _parseTimeOfDay(widget.initialStartTime);
    if (widget.initialStartTime != null) {
      startTimeController.text = widget.initialStartTime!;
    }

    endTime = _parseTimeOfDay(widget.initialEndTime);
    if (widget.initialEndTime != null) {
      endTimeController.text = widget.initialEndTime!;
    }

    loadGoals();
    _monthlyAssignedIds.addAll(widget.assignedToIds);
    _loadAssignableUsers();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriController.dispose();
    createdDateController.dispose();
    dueDateController.dispose();
    goalTitleController.dispose();
    goalStartController.dispose();
    goalDueController.dispose();
    quantityController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    for (final goal in _subGoals) {
      goal.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAssignableUsers() async {
    try {
      final token = await AuthService.getToken();
      final role = token != null ? JwtHelper.getRole(token) : null;
      var department =
          (token != null ? JwtHelper.getDepartment(token) : null)?.trim();
      final loginUserId = int.tryParse(
        (token != null ? JwtHelper.getuid(token) : null)?.toString() ?? '',
      );

      if ((department == null || department.isEmpty) && loginUserId != null) {
        try {
          final details = await SuperAdminService.getAdminDetails(loginUserId);
          if (details.department.trim().isNotEmpty) {
            department = details.department.trim();
          }
        } catch (_) {}
      }

      final isDirector =
          role == AppRoles.director ||
          (role ?? '').toLowerCase() == 'director';
      final isDivisionHead = AppRoles.isDivisionHead(role);

      var allowedDepartments = <String>[
        ...?widget.assignedDepartments
            ?.map((d) => d.trim())
            .where((d) => d.isNotEmpty),
      ];

      if (!isDirector) {
        final ownDepartments = <String>{
          if (department != null && department.isNotEmpty) department,
          if (isDivisionHead) ...DivisionConfig.childDepartments(department),
        };

        if (allowedDepartments.isEmpty) {
          allowedDepartments = ownDepartments.toList();
        } else {
          allowedDepartments = allowedDepartments
              .where(
                (dept) => DivisionConfig.isAllowedDepartment(
                  dept,
                  ownDepartments.toList(),
                ),
              )
              .toList();
          if (allowedDepartments.isEmpty) {
            allowedDepartments = ownDepartments.toList();
          }
        }
      }

      List<UserModel> users = [];
      if (isDirector && allowedDepartments.isEmpty) {
        try {
          users = await SuperAdminService.getAllUsers();
        } catch (_) {
          users = await SuperAdminService.getEmployees();
        }
      } else if (allowedDepartments.isNotEmpty) {
        try {
          users = await AdminService.getEmployeesByDepartments(
            allowedDepartments,
          );
        } catch (_) {}

        if (users.isEmpty) {
          try {
            final allUsers = await SuperAdminService.getAllUsers();
            users = allUsers
                .where(
                  (user) => DivisionConfig.isAllowedDepartment(
                    user.department,
                    allowedDepartments,
                  ),
                )
                .toList();
          } catch (_) {}
        } else if (!isDirector) {
          users = users
              .where(
                (user) => DivisionConfig.isAllowedDepartment(
                  user.department,
                  allowedDepartments,
                ),
              )
              .toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _assignableUsers = users
            .where((user) => user.status.toLowerCase() != 'inactive')
            .toList();
        _loadingUsers = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => _loadingUsers = false);
    }
  }

  String _userLabel(int id) {
    for (final user in _assignableUsers) {
      if (user.userId == id) return user.name;
    }
    return 'User $id';
  }

  Color _softFill() {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF4F6F5);
  }

  _MonthlySubGoal _newSubGoal({String? title}) {
    return _MonthlySubGoal(
      title: title,
      startDate: goalStartDate,
      dueDate: goalDueDate,
      assignedUserIds: {
        ...widget.assignedToIds,
        ..._monthlyAssignedIds,
      },
    );
  }

  void _setGoalType(String type) {
    setState(() {
      _goalType = type;
      if (type == 'Yearly') {
        _applyGeneratedMonths(force: _subGoals.isEmpty);
      }
    });
  }

  Set<int> get _defaultStaffIds => {
        ...widget.assignedToIds,
        ..._monthlyAssignedIds,
      };

  List<_MonthlySubGoal> _buildMonthGoals() {
    final start = goalStartDate!;
    final due = goalDueDate!;
    final goals = <_MonthlySubGoal>[];
    var year = start.year;
    var month = start.month;
    final staff = _defaultStaffIds;

    while (goals.length < 24) {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);
      final sliceStart = monthStart.isBefore(start) ? start : monthStart;
      final sliceEnd = monthEnd.isAfter(due) ? due : monthEnd;
      if (sliceEnd.isBefore(sliceStart)) break;

      goals.add(
        _MonthlySubGoal(
          title: '${_monthName(month)} $year',
          startDate: sliceStart,
          dueDate: sliceEnd,
          assignedUserIds: staff,
        ),
      );

      if (year == due.year && month == due.month) break;
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
    }
    return goals;
  }

  void _applyGeneratedMonths({bool force = false}) {
    if (goalStartDate == null || goalDueDate == null) return;
    if (!force && !_monthsWereGenerated && _subGoals.isNotEmpty) return;

    for (final goal in _subGoals) {
      goal.dispose();
    }
    _subGoals
      ..clear()
      ..addAll(_buildMonthGoals());
    _monthsWereGenerated = true;
  }

  Future<void> _pickUsers(Set<int> target, {String? title}) async {
    final picker = _StaffPicker(
      users: _assignableUsers,
      selectedIds: target,
      title: title ?? 'Assign staff',
    );

    final result = AppLayout.isMobile(context)
        ? await showModalBottomSheet<Set<int>>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.78,
                child: picker,
              ),
            ),
          )
        : await showDialog<Set<int>>(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(width: 520, height: 620, child: picker),
            ),
          );

    if (result == null || !mounted) return;
    setState(() {
      target
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isCreated,
  ) async {
    final today = DateTime.now();

    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    DateTime initialDate = today;
    if (isTask && goalStartDate != null && goalDueDate != null) {
      firstDate = DateTime(
        goalStartDate!.year,
        goalStartDate!.month,
        goalStartDate!.day,
      );

      lastDate = DateTime(
        goalDueDate!.year,
        goalDueDate!.month,
        goalDueDate!.day,
      );

      if (isCreated) {
        // Task Start Date
        initialDate = firstDate;
      } else {
        // Task Due Date
        if (createdDate != null && createdDate!.isAfter(firstDate)) {
          firstDate = DateTime(
            createdDate!.year,
            createdDate!.month,
            createdDate!.day,
          );
        }

        initialDate = firstDate;
      }
    }
    else if (isTask) {
      // No goal selected → use today's date
      initialDate = today;

      if (!isCreated && createdDate != null) {
        // Due date cannot be before task start date
        firstDate = DateTime(
          createdDate!.year,
          createdDate!.month,
          createdDate!.day,
        );

        if (initialDate.isBefore(firstDate)) {
          initialDate = firstDate;
        }
      }
    }
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        if (isCreated) {
          createdDate = picked;

          // If due date is before new start date, clear it
          if (dueDate != null && dueDate!.isBefore(createdDate!)) {
            dueDate = null;
            dueDateController.clear();
          }
        } else {
          dueDate = picked;
        }
      });
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

  Future<void> _createTask() async {
    if (nameController.text.isEmpty ||
        descriController.text.isEmpty ||
        selectedPriority == null ||
        createdDate == null ||
        dueDate == null ||
        (selectedPerformanceType == "Qty" && quantityController.text.isEmpty)) {
      showTopMessage("Please fill the All Fields", isError: true);
      return;
    }

    if (selectedPerformanceType == "Qty" &&
        int.tryParse(quantityController.text) == null) {
      showTopMessage("Enter a valid quantity", isError: true);
      return;
    }

    if (dueDate!.isBefore(createdDate!)) {
      showTopMessage(
        "Task due date cannot be before start date",
        isError: true,
      );
      return;
    }

    if (startTime != null && endTime != null) {
      final startMinutes = startTime!.hour * 60 + startTime!.minute;
      final endMinutes = endTime!.hour * 60 + endTime!.minute;
      if (endMinutes <= startMinutes) {
        showTopMessage("End time must be after start time", isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    final int? quantity = selectedPerformanceType == "Qty"
        ? int.tryParse(quantityController.text)
        : null;

    bool success = await SuperAdminService.createTask(
      task: nameController.text,
      description: descriController.text,
      priority: selectedPriority!,
      assignedAt: createdDate!,
      dueDate: dueDate!,
      goalCode: selectedGoalCode,
      performanceType: selectedPerformanceType,
      quantity: quantity,
      startTime: startTime != null ? formatTimeOfDay(startTime!) : null,
      endTime: endTime != null ? formatTimeOfDay(endTime!) : null,
      assignedToIds: widget.assignedToIds,
    );

    setState(() => _isLoading = false);

    if (success) {
      showTopMessage("Task Created Succesfully", isError: false);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        context.read<DataRefreshNotifier>().refreshTasks();
        context.read<DataRefreshNotifier>().refreshGoals();
        Navigator.pop(context, true);
      }
    } else {
      showTopMessage("Failed to create Task", isError: true);
    }
  }

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isCreated,
  ) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);

    if (controller == goalDueController && goalStartDate != null) {
      firstDate = goalStartDate!;
      initialDate = goalStartDate!;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        if (controller == goalStartController) {
          goalStartDate = picked;

          if (goalDueDate != null && goalDueDate!.isBefore(goalStartDate!)) {
            goalDueDate = null;
            goalDueController.clear();
          }
        } else if (controller == goalDueController) {
          goalDueDate = picked;
        }
        if (_goalType == 'Yearly') {
          _applyGeneratedMonths(force: _monthsWereGenerated || _subGoals.isEmpty);
        }
      });
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _createGoal() async {
    if (goalTitleController.text.trim().isEmpty ||
        selectedPriority == null ||
        goalStartDate == null ||
        goalDueDate == null) {
      showTopMessage("Please fill the All Fields", isError: true);
      return;
    }

    if (goalDueDate!.isBefore(goalStartDate!)) {
      showTopMessage("Due date cannot be before start date", isError: true);
      return;
    }

    List<Map<String, dynamic>>? monthlyGoals;
    List<int>? assignedUserIds;

    if (_goalType == 'Yearly') {
      if (_subGoals.isEmpty) {
        showTopMessage("Add at least one monthly sub-goal", isError: true);
        return;
      }

      final parentStart = DateTime(
        goalStartDate!.year,
        goalStartDate!.month,
        goalStartDate!.day,
      );
      final parentDue = DateTime(
        goalDueDate!.year,
        goalDueDate!.month,
        goalDueDate!.day,
      );

      for (var i = 0; i < _subGoals.length; i++) {
        final goal = _subGoals[i];
        if (goal.titleController.text.trim().isEmpty ||
            goal.startDate == null ||
            goal.dueDate == null) {
          showTopMessage("Fill all fields for sub-goal ${i + 1}", isError: true);
          return;
        }
        if (goal.dueDate!.isBefore(goal.startDate!)) {
          showTopMessage(
            "Sub-goal ${i + 1} due date cannot be before start date",
            isError: true,
          );
          return;
        }
        final start = DateTime(
          goal.startDate!.year,
          goal.startDate!.month,
          goal.startDate!.day,
        );
        final due = DateTime(
          goal.dueDate!.year,
          goal.dueDate!.month,
          goal.dueDate!.day,
        );
        if (start.isBefore(parentStart) || due.isAfter(parentDue)) {
          showTopMessage(
            "Sub-goal ${i + 1} dates must stay within the yearly dates",
            isError: true,
          );
          return;
        }
        if (goal.assignedUserIds.isEmpty) {
          showTopMessage(
            "Assign staff to sub-goal ${i + 1}",
            isError: true,
          );
          return;
        }
      }

      monthlyGoals = _subGoals
          .map(
            (goal) => {
              "title": goal.titleController.text.trim(),
              "startDate": goal.startDate!.toIso8601String(),
              "dueDate": goal.dueDate!.toIso8601String(),
              "assignedUserIds": goal.assignedUserIds.toList(),
            },
          )
          .toList();
    } else {
      if (_monthlyAssignedIds.isEmpty) {
        showTopMessage("Assign at least one staff member", isError: true);
        return;
      }
      assignedUserIds = _monthlyAssignedIds.toList();
    }

    setState(() => _isLoading = true);

    String? error;
    try {
      error = await SuperAdminService.createGoal(
        goalType: _goalType,
        title: goalTitleController.text.trim(),
        priority: selectedPriority!,
        startDate: goalStartDate!,
        dueDate: goalDueDate!,
        assignedUserIds: assignedUserIds,
        monthlyGoals: monthlyGoals,
        sendParentGoalId: _goalType == 'Monthly',
        parentGoalId: null,
      );
    } catch (e) {
      debugPrint(e.toString());
      error = "Failed to create Goal";
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      showTopMessage("Goal Created Successfully", isError: false);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.read<DataRefreshNotifier>().refreshGoals();
        context.read<DataRefreshNotifier>().refreshTasks();
        Navigator.pop(context, true);
      }
    } else {
      showTopMessage(error, isError: true);
    }
  }

  Future<List<String>> _assigneeDepartments() async {
    final provided = widget.assignedDepartments
            ?.where((d) => d.trim().isNotEmpty)
            .toSet()
            .toList() ??
        [];
    if (provided.isNotEmpty) return provided;

    final departments = <String>{};
    for (final id in widget.assignedToIds) {
      try {
        final details = await SuperAdminService.getAdminDetails(id);
        if (details.department.trim().isNotEmpty) {
          departments.add(details.department);
        }
      } catch (_) {}
    }
    return departments.toList();
  }

  List<dynamic> _uniqueGoals(List<dynamic> goals) {
    final seen = <String>{};
    final unique = <dynamic>[];
    for (final goal in goals) {
      if (goal is! Map) continue;
      final code = (goal['goalCode'] ?? goal['code'] ?? '').toString();
      if (code.isEmpty || !seen.add(code)) continue;
      unique.add(goal);
    }
    return unique;
  }

  Future<List<dynamic>> _loadAssigneeGoals() async {
    final loaded = <dynamic>[];
    final departments = await _assigneeDepartments();

    if (departments.isNotEmpty) {
      final deptGoals = await Future.wait(
        departments.map((department) async {
          try {
            return await AdminService.getGoalsByDepartment(department);
          } catch (_) {
            return <dynamic>[];
          }
        }),
      );
      for (final list in deptGoals) {
        loaded.addAll(list);
      }
    }

    for (final userId in widget.assignedToIds) {
      try {
        loaded.addAll(await AdminService.getusergoalbyid(userId));
      } catch (_) {}
    }

    return loaded;
  }

  Future<void> loadGoals() async {
    if (mounted) setState(() => isGoalLoading = true);

    try {
      var loaded = await _loadAssigneeGoals();

      if (loaded.isEmpty) {
        try {
          loaded = await SuperAdminService.getGoalsname();
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        goalsList = _uniqueGoals(loaded);

        if (selectedGoalCode != null && goalsList.isNotEmpty) {
          final matches = goalsList.where(
            (g) => g['goalCode'].toString() == selectedGoalCode,
          );
          if (matches.isNotEmpty) {
            final selectedGoal = matches.first;
            final start = selectedGoal['startDate'];
            final due = selectedGoal['dueDate'];
            if (start != null) goalStartDate = DateTime.tryParse(start.toString());
            if (due != null) goalDueDate = DateTime.tryParse(due.toString());
          }
        }
      });
    } catch (e) {
      if (mounted) showTopMessage("Failed to load goals");
    }

    if (mounted) setState(() => isGoalLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTask ? "Create Task" : "Create Goal"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Center(
                    child: ToggleButtons(
                      borderRadius: BorderRadius.circular(10),
                      isSelected: [!isTask, isTask],
                      color: Theme.of(context).colorScheme.secondary,
                      selectedColor: Colors.white,
                      fillColor: Theme.of(context).colorScheme.secondary,
                      onPressed: (index) {
                        setState(() {
                          isTask = index == 1; // Task is index 1
                        });
                      },
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            "Goal",
                            style: TextStyle(
                              color: !isTask
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            "Task",
                            style: TextStyle(
                              color: !isTask
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  isTask ? _taskForm() : _goalForm(),
                  const SizedBox(height: 30),
                  Center(
                    child: AppButton(
                      text: "Create",
                      isLoading: _isLoading,
                      onPressed: () {
                        if (isTask) {
                          _createTask();
                        } else {
                          _createGoal();
                        }
                      },
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          // Top message
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 40 : -120,
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

  Widget _taskForm() {
    if (selectedGoalCode != null &&
        goalsList.isNotEmpty &&
        !goalsList.any((g) => g['goalCode'].toString() == selectedGoalCode)) {
      selectedGoalCode = null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Task Name"),
        const SizedBox(height: 8),
        CustomFormWidgets.textField(
          context,
          nameController,
          hint: "Enter task name",
        ),

        const SizedBox(height: 20),
        _row2(
          _labeled(
            "Performance Type",
            CustomFormWidgets.dropdown(
              context: context,
              value: selectedPerformanceType,
              items: ["Default", "Qty"],
              onChanged: (v) => setState(() {
                selectedPerformanceType = v ?? "Default";
                if (selectedPerformanceType != "Qty") {
                  quantityController.clear();
                }
              }),
              hint: "Select Performance Type",
            ),
          ),
          _labeled(
            "Priority",
            CustomFormWidgets.dropdown(
              context: context,
              value: selectedPriority,
              items: ["Normal", "Medium", "High"],
              onChanged: (v) => setState(() => selectedPriority = v),
              hint: "Select Priority",
            ),
          ),
        ),
        if (selectedPerformanceType == "Qty") ...[
          const SizedBox(height: 20),
          CustomFormWidgets.label(context, "Qty"),
          const SizedBox(height: 8),
          CustomFormWidgets.textField(
            context,
            quantityController,
            hint: "Enter quantity",
            maxLines: 1,
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Description"),
        const SizedBox(height: 8),
        CustomFormWidgets.textField(
          context,
          descriController,
          hint: "Enter description",
          maxLines: 4,
        ),
        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Select Goal"),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromARGB(255, 25, 77, 38)),
          ),
          child: isGoalLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
            value: selectedGoalCode,

            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            hint: Text(
              goalsList.isEmpty
                  ? "No goals found for this department"
                  : "Select Goal",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            style: Theme.of(context).textTheme.titleLarge,

            items: goalsList.map<DropdownMenuItem<String>>((goal) {
              return DropdownMenuItem<String>(
                value: goal['goalCode'].toString(),
                child: Text(
                  goal['title'] ?? "",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }).toList(),
            onChanged: goalsList.isEmpty
                ? null
                : (value) {
                    setState(() {
                      selectedGoalCode = value;

                      final selectedGoal = goalsList.firstWhere(
                        (g) => g['goalCode'].toString() == value,
                      );
                      final start = selectedGoal['startDate'];
                      final due = selectedGoal['dueDate'];
                      if (start != null) {
                        goalStartDate = DateTime.tryParse(start.toString());
                      }
                      if (due != null) {
                        goalDueDate = DateTime.tryParse(due.toString());
                      }
                    });
                  },
          ),
        ),

        const SizedBox(height: 20),
        _row2(
          _labeled(
            "Start Date",
            CustomFormWidgets.dateField(
              controller: createdDateController,
              onTap: () => _selectDate(context, createdDateController, true),
            ),
          ),
          _labeled(
            "Due Date",
            CustomFormWidgets.dateField(
              controller: dueDateController,
              onTap: () => _selectDate(context, dueDateController, false),
            ),
          ),
        ),

        const SizedBox(height: 20),
        _row2(
          _labeled(
            "Start Time",
            CustomFormWidgets.timeField(
              controller: startTimeController,
              onTap: () => _pickTime(isStart: true),
            ),
            hint: "(optional)",
          ),
          _labeled(
            "Due Time",
            CustomFormWidgets.timeField(
              controller: endTimeController,
              onTap: () => _pickTime(isStart: false),
            ),
            hint: "(optional)",
          ),
        ),
      ],
    );
  }

  Widget _row2(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _labeled(String label, Widget child, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomFormWidgets.label(context, label),
            if (hint != null) ...[
              const SizedBox(width: 6),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
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
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startTime = picked;
        startTimeController.text = formatTimeOfDay(picked);
      } else {
        endTime = picked;
        endTimeController.text = formatTimeOfDay(picked);
      }
    });
  }

  Widget _goalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _goalTypeField(),
        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Goal Title"),
        const SizedBox(height: 8),
        CustomFormWidgets.textField(
          context,
          goalTitleController,
          hint: "Enter goal title",
        ),
        const SizedBox(height: 20),
        _row2(
          _labeled(
            "Start Date",
            CustomFormWidgets.dateField(
              controller: goalStartController,
              onTap: () => selectDate(context, goalStartController, true),
            ),
          ),
          _labeled(
            "Due Date",
            CustomFormWidgets.dateField(
              controller: goalDueController,
              onTap: () => selectDate(context, goalDueController, false),
            ),
          ),
        ),
        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Priority"),
        const SizedBox(height: 8),
        CustomFormWidgets.dropdown(
          context: context,
          value: selectedPriority,
          items: ["Normal", "Medium", "High"],
          onChanged: (v) => setState(() => selectedPriority = v),
          hint: "Select Priority",
        ),
        const SizedBox(height: 22),
        if (_goalType == 'Monthly') ...[
          Row(
            children: [
              Expanded(
                child: CustomFormWidgets.label(context, "Assigned staff"),
              ),
              IconButton(
                tooltip: 'Add staff',
                onPressed: () => _pickUsers(
                  _monthlyAssignedIds,
                  title: 'Assign staff',
                ),
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          _assignedStaffBox(
            ids: _monthlyAssignedIds,
            onAdd: () => _pickUsers(
              _monthlyAssignedIds,
              title: 'Assign staff',
            ),
          ),
        ] else
          _yearlyBreakdown(),
      ],
    );
  }

  Widget _goalTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormWidgets.label(context, "Goal Type"),
        const SizedBox(height: 8),
        CustomFormWidgets.dropdown(
          context: context,
          value: _goalType,
          items: const ["Monthly", "Yearly"],
          onChanged: (v) {
            if (v != null) _setGoalType(v);
          },
          hint: "Select Goal Type",
        ),
        const SizedBox(height: 8),
        Text(
          _goalType == 'Yearly'
              ? 'Yearly goals are split into months. Assign staff on each month.'
              : 'A single goal for this period, assigned to selected staff.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.35),
        ),
      ],
    );
  }

  Widget _yearlyBreakdown() {
    final brand = Theme.of(context).colorScheme.secondary;
    final canGenerate = goalStartDate != null && goalDueDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monthly breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            if (_subGoals.isNotEmpty)
              Text(
                '${_subGoals.length} months',
                style: TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!canGenerate)
          _hintBox('Pick start and due dates. Months will be created for you.')
        else if (_subGoals.isEmpty)
          _hintBox('Tap Generate months to create one goal per month.')
        else
          ...List.generate(_subGoals.length, (index) {
            return _monthRow(index, _subGoals[index]);
          }),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (canGenerate && _subGoals.isEmpty)
              ActionChip(
                avatar: Icon(Icons.auto_awesome, size: 16, color: brand),
                label: const Text('Generate months'),
                onPressed: () {
                  setState(() => _applyGeneratedMonths(force: true));
                },
              ),
            ActionChip(
              avatar: Icon(Icons.add, size: 18, color: brand),
              label: const Text('Add month'),
              onPressed: canGenerate
                  ? () {
                      setState(() {
                        _monthsWereGenerated = false;
                        _subGoals.add(_newSubGoal());
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _hintBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _softFill(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
      ),
    );
  }

  Widget _monthRow(int index, _MonthlySubGoal goal) {
    final brand = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: brand.withValues(alpha: 0.12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: brand,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: goal.titleController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Month title',
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              if (_subGoals.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove',
                  onPressed: () {
                    setState(() {
                      _monthsWereGenerated = false;
                      final removed = _subGoals.removeAt(index);
                      removed.dispose();
                    });
                  },
                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _miniDate(
                  goal.startDate,
                  onTap: () => _selectSubGoalDate(goal, isStart: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('–', style: TextStyle(color: Colors.grey.shade600)),
              ),
              Expanded(
                child: _miniDate(
                  goal.dueDate,
                  onTap: () => _selectSubGoalDate(goal, isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _assignedStaffBox(
            ids: goal.assignedUserIds,
            onAdd: () => _pickUsers(
              goal.assignedUserIds,
              title: goal.titleController.text.trim().isEmpty
                  ? 'Assign month ${index + 1}'
                  : 'Assign ${goal.titleController.text.trim()}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniDate(DateTime? date, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _softFill(),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.event, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date == null ? 'Date' : _friendlyDate(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: date == null ? Colors.grey.shade500 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignedStaffBox({
    required Set<int> ids,
    required VoidCallback onAdd,
  }) {
    final brand = Theme.of(context).colorScheme.secondary;
    const border = Color.fromARGB(255, 25, 77, 38);

    if (_loadingUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ids.isEmpty
                ? Text(
                    'No staff assigned',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ids.map((id) {
                      return InputChip(
                        label: Text(
                          _userLabel(id),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onDeleted: () => setState(() => ids.remove(id)),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.black54),
                        backgroundColor: brand.withValues(alpha: 0.08),
                        side: BorderSide(color: brand.withValues(alpha: 0.3)),
                      );
                    }).toList(),
                  ),
          ),
          IconButton(
            tooltip: 'Add staff',
            onPressed: onAdd,
            icon: Icon(Icons.add, color: brand),
          ),
        ],
      ),
    );
  }

  Future<void> _selectSubGoalDate(
    _MonthlySubGoal goal, {
    required bool isStart,
  }) async {
    if (goalStartDate == null || goalDueDate == null) {
      showTopMessage("Set yearly start and due dates first", isError: true);
      return;
    }
    DateTime firstDate = goalStartDate ?? DateTime(2000);
    DateTime lastDate = goalDueDate ?? DateTime(2100);
    if (!isStart && goal.startDate != null && goal.startDate!.isAfter(firstDate)) {
      firstDate = goal.startDate!;
    }

    DateTime initialDate = isStart
        ? (goal.startDate ?? firstDate)
        : (goal.dueDate ?? goal.startDate ?? firstDate);

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        goal.startDate = picked;
        goal.startController.text = _formatGoalDate(picked);
        if (goal.dueDate != null && goal.dueDate!.isBefore(picked)) {
          goal.dueDate = null;
          goal.dueController.clear();
        }
      } else {
        goal.dueDate = picked;
        goal.dueController.text = _formatGoalDate(picked);
      }
    });
  }
}

String _formatGoalDate(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

String _friendlyDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[month - 1];
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  final last = parts.last.isEmpty ? parts.first[0] : parts.last[0];
  return (parts.first[0] + last).toUpperCase();
}

class _MonthlySubGoal {
  _MonthlySubGoal({
    String? title,
    this.startDate,
    this.dueDate,
    Iterable<int>? assignedUserIds,
  }) : assignedUserIds = {...?assignedUserIds} {
    if (title != null && title.isNotEmpty) {
      titleController.text = title;
    }
    final start = startDate;
    final due = dueDate;
    if (start != null) {
      startController.text = _formatGoalDate(start);
    }
    if (due != null) {
      dueController.text = _formatGoalDate(due);
    }
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController dueController = TextEditingController();
  DateTime? startDate;
  DateTime? dueDate;
  final Set<int> assignedUserIds;

  void dispose() {
    titleController.dispose();
    startController.dispose();
    dueController.dispose();
  }
}

class _StaffPicker extends StatefulWidget {
  final List<UserModel> users;
  final Set<int> selectedIds;
  final String title;

  const _StaffPicker({
    required this.users,
    required this.selectedIds,
    required this.title,
  });

  @override
  State<_StaffPicker> createState() => _StaffPickerState();
}

class _StaffPickerState extends State<_StaffPicker> {
  late final Set<int> _selected;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  UserModel? _userById(int id) {
    for (final user in widget.users) {
      if (user.userId == id) return user;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.users.where((user) {
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.department.toLowerCase().contains(query);
    }).toList();
    final brand = Theme.of(context).colorScheme.secondary;
    const fieldBorder = Color.fromARGB(255, 25, 77, 38);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            _selected.isEmpty
                ? 'Select the people for this goal'
                : '${_selected.length} selected',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: 'Search name',
              hintStyle: Theme.of(context).textTheme.headlineSmall,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: fieldBorder),
              ),
            ),
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected.map((id) {
                final name = _userById(id)?.name ?? 'User $id';
                return InputChip(
                  label: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDeleted: () => setState(() => _selected.remove(id)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.black54),
                  backgroundColor: brand.withValues(alpha: 0.08),
                  side: BorderSide(color: brand.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.users.isEmpty
                          ? 'No staff in this department'
                          : 'No matching staff',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final checked = _selected.contains(user.userId);
                      return Material(
                        color: checked
                            ? brand.withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (checked) {
                                _selected.remove(user.userId);
                              } else {
                                _selected.add(user.userId);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: checked ? brand : fieldBorder,
                                width: checked ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: checked
                                      ? brand.withValues(alpha: 0.18)
                                      : brand.withValues(alpha: 0.12),
                                  child: Text(
                                    _initials(user.name),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  checked
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: checked ? brand : Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          AppButton(
            text: "Done",
            onPressed: () => Navigator.pop(context, _selected),
            color: Theme.of(context).colorScheme.secondary,
            txtcolor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}
