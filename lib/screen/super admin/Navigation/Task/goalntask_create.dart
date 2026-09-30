import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/role_hierarchy.dart';
import 'package:staff_work_track/widgets/staff_picker.dart';
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
  final TextEditingController goalQuantityController = TextEditingController();
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
  final Set<int> _taskAssignedIds = {};
  final List<_QuantityShare> _quantityShares = [];
  final List<_MonthlySubGoal> _subGoals = [];
  bool _monthsWereGenerated = false;

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final upper = value.trim().toUpperCase();
    if (upper.endsWith('AM') || upper.endsWith('PM')) {
      final isPm = upper.endsWith('PM');
      final hm = upper.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      if (hm.length < 2) return null;
      var hour = int.tryParse(hm[0].trim());
      final minute = int.tryParse(hm[1].trim());
      if (hour == null || minute == null) return null;
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    final parts = value.split(':');
    if (parts.length < 2) return null;
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
      createdDateController.text = TimeUtils.formatDate(createdDate!);
    }

    dueDate = widget.initialDueDate;
    if (dueDate != null) {
      dueDateController.text = TimeUtils.formatDate(dueDate!);
    }

    startTime = _parseTimeOfDay(widget.initialStartTime);
    if (widget.initialStartTime != null) {
      startTimeController.text = TimeUtils.formatTime12(widget.initialStartTime);
    }

    endTime = _parseTimeOfDay(widget.initialEndTime);
    if (widget.initialEndTime != null) {
      endTimeController.text = TimeUtils.formatTime12(widget.initialEndTime);
    }

    loadGoals();
    _monthlyAssignedIds.addAll(widget.assignedToIds);
    _taskAssignedIds.addAll(widget.assignedToIds);
    _loadAssignableUsers();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriController.dispose();
    createdDateController.dispose();
    dueDateController.dispose();
    goalTitleController.dispose();
    goalQuantityController.dispose();
    goalStartController.dispose();
    goalDueController.dispose();
    quantityController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    for (final share in _quantityShares) {
      share.dispose();
    }
    for (final goal in _subGoals) {
      goal.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAssignableUsers() async {
    try {
      final token = await AuthService.getToken();
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

      final ownDepartment = department?.trim() ?? "";
      List<UserModel> users = [];
      if (ownDepartment.isNotEmpty) {
        try {
          users = await AdminService.getEmployeesByDepartments([ownDepartment]);
        } catch (_) {}

        final ownKey = ownDepartment.toLowerCase();
        if (users.isEmpty) {
          try {
            final allUsers = await SuperAdminService.getAllUsers();
            users = allUsers
                .where(
                  (user) => user.department.trim().toLowerCase() == ownKey,
                )
                .toList();
          } catch (_) {}
        } else {
          users = users
              .where((user) => user.department.trim().toLowerCase() == ownKey)
              .toList();
        }
      }

      final active = users
          .where((user) => user.status.toLowerCase() != 'inactive')
          .toList();
      final assignable = await keepAssignableUsers(active);
      if (!mounted) return;
      setState(() {
        _assignableUsers = assignable;
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

    final previousPriority = {
      for (final goal in _subGoals)
        if (goal.titleController.text.trim().isNotEmpty)
          goal.titleController.text.trim(): goal.priority,
    };

    for (final goal in _subGoals) {
      goal.dispose();
    }
    final generated = _buildMonthGoals();
    for (final goal in generated) {
      final kept = previousPriority[goal.titleController.text.trim()];
      if (kept != null && kept.isNotEmpty) {
        goal.priority = kept;
      }
    }
    _subGoals
      ..clear()
      ..addAll(generated);
    _monthsWereGenerated = true;
  }

  Future<void> _pickUsers(Set<int> target, {String? title}) async {
    final picker = StaffPicker(
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
      // No goal selected â†’ use today's date
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
          TimeUtils.formatDate(picked);

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

    final quantitySplits = <Map<String, dynamic>>[];
    if (selectedPerformanceType == "Qty" && _quantityShares.isNotEmpty) {
      final taskQuantity = int.tryParse(quantityController.text);
      var splitTotal = 0;
      for (var i = 0; i < _quantityShares.length; i++) {
        final share = _quantityShares[i];
        final shareQuantity = int.tryParse(share.quantityController.text.trim());
        if (shareQuantity == null || shareQuantity <= 0) {
          showTopMessage(
            "Enter a quantity greater than 0 for share ${i + 1}",
            isError: true,
          );
          return;
        }
        if (share.memberIds.isEmpty) {
          showTopMessage("Assign members for share ${i + 1}", isError: true);
          return;
        }
        splitTotal += shareQuantity;
        quantitySplits.add({
          "quantity": shareQuantity,
          "memberIds": share.memberIds.toList(),
        });
      }
      if (taskQuantity != null && splitTotal != taskQuantity) {
        showTopMessage(
          "Share quantities (${formatGoalQty(splitTotal)}) must equal the task quantity (${formatGoalQty(taskQuantity)})",
          isError: true,
        );
        return;
      }
      _taskAssignedIds
        ..clear()
        ..addAll(quantitySplits.expand((share) => (share["memberIds"] as List).cast<int>()));
    }

    if (_taskAssignedIds.isEmpty) {
      showTopMessage("Assign at least one staff member", isError: true);
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
      assignedToIds: _taskAssignedIds.toList(),
      quantitySplits: quantitySplits,
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
          TimeUtils.formatDate(picked);

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

    final yearlyQuantityText = goalQuantityController.text.trim();
    int? targetQuantity;
    if (yearlyQuantityText.isNotEmpty) {
      targetQuantity = int.tryParse(yearlyQuantityText);
      if (targetQuantity == null || targetQuantity <= 0) {
        showTopMessage("Enter a target quantity greater than 0", isError: true);
        return;
      }
    }

    List<Map<String, dynamic>>? monthlyGoals;
    List<int>? assignedUserIds;

    if (_goalType == 'Yearly') {
      if (_subGoals.isEmpty) {
        showTopMessage("Add at least one monthly sub-goal", isError: true);
        return;
      }

      var splitTotal = 0;
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
            goal.dueDate == null ||
            goal.priority.trim().isEmpty) {
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
        final monthQuantityText = goal.quantityController.text.trim();
        if (monthQuantityText.isNotEmpty) {
          final monthQuantity = int.tryParse(monthQuantityText);
          if (monthQuantity == null || monthQuantity <= 0) {
            showTopMessage(
              "Enter a quantity greater than 0 for sub-goal ${i + 1}",
              isError: true,
            );
            return;
          }
          splitTotal += monthQuantity;
        }
      }

      if (targetQuantity != null && splitTotal > targetQuantity) {
        showTopMessage(
          "Monthly quantities (${formatGoalQty(splitTotal)}) are more than the yearly target (${formatGoalQty(targetQuantity)})",
          isError: true,
        );
        return;
      }

      monthlyGoals = _subGoals.map((goal) {
        final item = <String, dynamic>{
          "title": goal.titleController.text.trim(),
          "priority": goal.priority,
          "startDate": goal.startDate!.toIso8601String(),
          "dueDate": goal.dueDate!.toIso8601String(),
          "assignedUserIds": goal.assignedUserIds.toList(),
        };
        final monthQuantity = int.tryParse(goal.quantityController.text.trim());
        if (monthQuantity != null && monthQuantity > 0) {
          item["targetQuantity"] = monthQuantity;
        }
        return item;
      }).toList();
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
        targetQuantity: targetQuantity,
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

  Widget _quantitySplitSection() {
    final taskQuantity = int.tryParse(quantityController.text.trim()) ?? 0;
    var splitTotal = 0;
    for (final share in _quantityShares) {
      splitTotal += int.tryParse(share.quantityController.text.trim()) ?? 0;
    }
    final left = taskQuantity - splitTotal;
    final status = _quantityShares.isEmpty
        ? "Optional"
        : left == 0
            ? "${formatGoalQty(splitTotal)} of ${formatGoalQty(taskQuantity)}"
            : left > 0
                ? "${formatGoalQty(left)} left"
                : "${formatGoalQty(left.abs())} over";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Shares",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() => _quantityShares.add(_QuantityShare()));
              },
              child: const Text("Add share"),
            ),
          ],
        ),
        for (var i = 0; i < _quantityShares.length; i++) _quantityShareRow(i),
      ],
    );
  }

  Widget _quantityShareRow(int index) {
    final share = _quantityShares[index];
    final brand = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              "Share ${index + 1}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: share.quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Qty",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                isDense: true,
                filled: true,
                fillColor: _softFill(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: brand),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: share.memberIds.isEmpty
                ? Text(
                    "No members",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: share.memberIds.map((id) {
                      return Text(
                        _userLabel(id),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Add members",
            onPressed: () => _pickUsers(
              share.memberIds,
              title: "Assign share ${index + 1}",
            ),
            icon: Icon(Icons.person_add_alt_1, size: 18, color: brand),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Remove share",
            onPressed: () {
              setState(() {
                final removed = _quantityShares.removeAt(index);
                removed.dispose();
              });
            },
            icon: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
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
          const SizedBox(height: 12),
          _quantitySplitSection(),
        ],

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomFormWidgets.label(context, "Assigned members"),
            ),
            IconButton(
              tooltip: "Add members",
              onPressed: () => _pickUsers(
                _taskAssignedIds,
                title: "Assign members",
              ),
              icon: Icon(
                Icons.person_add_alt_1,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        _assignedStaffBox(
          ids: _taskAssignedIds,
          onAdd: () => _pickUsers(
            _taskAssignedIds,
            title: "Assign members",
          ),
        ),
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
            optional: true,
          ),
          _labeled(
            "Due Time",
            CustomFormWidgets.timeField(
              controller: endTimeController,
              onTap: () => _pickTime(isStart: false),
            ),
            optional: true,
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

  Widget _labeled(String label, Widget child, {bool optional = false}) {
    final labelStyle = optional
        ? Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          )
        : Theme.of(context).textTheme.headlineLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: labelStyle,
            children: optional
                ? [
                    TextSpan(
                      text: "  Optional",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ]
                : null,
          ),
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
        startTimeController.text = TimeUtils.formatTime12(
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}",
        );
      } else {
        endTime = picked;
        endTimeController.text = TimeUtils.formatTime12(
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}",
        );
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
        CustomFormWidgets.label(
          context,
          _goalType == 'Yearly' ? "Yearly priority" : "Priority",
        ),
        const SizedBox(height: 8),
        CustomFormWidgets.dropdown(
          context: context,
          value: selectedPriority,
          items: ["Normal", "Medium", "High"],
          onChanged: (v) => setState(() => selectedPriority = v),
          hint: "Select Priority",
        ),
        const SizedBox(height: 20),
        _labeled(
          _goalType == 'Yearly' ? "Yearly target quantity" : "Target quantity",
          _quantityInput(goalQuantityController),
          optional: true,
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
        _quantitySummary(),
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
              avatar: Icon(Icons.add, size: 18, color: Colors.white),
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

  Widget _quantityInput(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      style: Theme.of(context).textTheme.headlineMedium,
      decoration: InputDecoration(
        hintText: "Enter quantity",
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
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

  Widget _quantitySummary() {
    final target = int.tryParse(goalQuantityController.text.trim());
    final hasTarget = target != null && target > 0;
    final split = _subGoals.fold<int>(0, (total, goal) {
      return total + (int.tryParse(goal.quantityController.text.trim()) ?? 0);
    });
    final left = hasTarget ? target - split : null;
    final remaining = left ?? 0;
    final over = left != null && left < 0;
    final fraction = hasTarget ? (split / target).clamp(0.0, 1.0) : 0.0;
    final brand = Theme.of(context).colorScheme.secondary;
    final barColor = over ? Theme.of(context).colorScheme.error : brand;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softFill(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryFigure(
                  "Target",
                  hasTarget ? formatGoalQty(target) : "â€”",
                ),
              ),
              Expanded(
                child: _summaryFigure("Assigned", formatGoalQty(split)),
              ),
              Expanded(
                child: _summaryFigure(
                  over ? "Over" : "Left",
                  left == null
                      ? "â€”"
                      : formatGoalQty(over ? remaining.abs() : remaining),
                  emphasize: over,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: hasTarget ? fraction : 0,
              backgroundColor: Colors.grey.shade300,
              color: barColor,
            ),
          ),
          if (hasTarget) ...[
            const SizedBox(height: 6),
            Text(
              over
                  ? "Monthly quantities are ${formatGoalQty(remaining.abs())} over the yearly target."
                  : remaining == 0
                      ? "The full yearly quantity is split across the months."
                      : "${formatGoalQty(remaining)} is still not assigned to a month.",
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: over
                    ? Theme.of(context).colorScheme.error
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryFigure(String label, String value, {bool emphasize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: emphasize ? Theme.of(context).colorScheme.error : null,
          ),
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
                child: Text('â€“', style: TextStyle(color: Colors.grey.shade600)),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: "Quantity",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                children: [
                  TextSpan(
                    text: "  Optional",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: goal.quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Enter quantity",
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              filled: true,
              fillColor: _softFill(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _monthPriority(goal),
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

  Widget _monthPriority(_MonthlySubGoal goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Month priority',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _softFill(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: goal.priority,
              isExpanded: true,
              isDense: true,
              items: const ["Normal", "Medium", "High"]
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => goal.priority = value);
              },
            ),
          ),
        ),
      ],
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

class _QuantityShare {
  final TextEditingController quantityController = TextEditingController();
  final Set<int> memberIds = {};

  void dispose() {
    quantityController.dispose();
  }
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
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController dueController = TextEditingController();
  DateTime? startDate;
  DateTime? dueDate;
  String priority = 'Normal';
  final Set<int> assignedUserIds;

  void dispose() {
    titleController.dispose();
    quantityController.dispose();
    startController.dispose();
    dueController.dispose();
  }
}
