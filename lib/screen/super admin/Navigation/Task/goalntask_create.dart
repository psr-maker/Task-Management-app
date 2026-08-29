import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/providers/data_refresh_provider.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class Createtask extends StatefulWidget {
  final List<int> assignedToIds;
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
    selectedPriority = widget.initialPriority;
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
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isCreated,
  ) async {
    DateTime initialDate = DateTime.now();

    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    // Always clamp to the Goal's range first when creating a Task
    if (isTask && goalStartDate != null && goalDueDate != null) {
      firstDate = goalStartDate!;
      lastDate = goalDueDate!;
    }

    if (isCreated) {
      // Selecting TASK START DATE
      // must stay within [goalStartDate, goalDueDate]
      initialDate = firstDate;
    } else {
      // Selecting TASK DUE DATE
      // must stay within [max(createdDate, goalStartDate), goalDueDate]
      if (createdDate != null && createdDate!.isAfter(firstDate)) {
        firstDate = createdDate!;
      }
      initialDate = firstDate;
    }

    // Clamp initialDate to both bounds so the picker never throws
    // and always opens on a valid, selectable date
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    DateTime? picked = await showDatePicker(
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

          // If existing due date is now before the new start date, clear it
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
      });
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _createGoal() async {
    if (goalTitleController.text.isEmpty ||
        selectedPriority == null ||
        goalStartDate == null ||
        goalDueDate == null) {
      showTopMessage("Please fill the All Fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    bool success = await SuperAdminService.createGoal(
      title: goalTitleController.text,
      priority: selectedPriority!,
      startDate: goalStartDate!,
      dueDate: goalDueDate!,
      assignTo: widget.assignedToIds.first.toString(),
    );

    setState(() => _isLoading = false);

    if (success) {
      showTopMessage("Goal Created Successfully", isError: false);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.read<DataRefreshNotifier>().refreshGoals();
        context.read<DataRefreshNotifier>().refreshTasks();
        Navigator.pop(context, true);
      }
    } else {
      showTopMessage("Failed to create Goal", isError: true);
    }
  }

  Future<void> loadGoals() async {
    setState(() => isGoalLoading = true);

    try {
      final response = await SuperAdminService.getGoalsname();

      setState(() {
        goalsList = response;

        if (selectedGoalCode != null && goalsList.isNotEmpty) {
          final selectedGoal = goalsList.firstWhere(
            (g) => g['goalCode'].toString() == selectedGoalCode,
            orElse: () => null,
          );

          if (selectedGoal != null) {
            goalStartDate = DateTime.parse(selectedGoal['startDate']);
            goalDueDate = DateTime.parse(selectedGoal['dueDate']);
          }
        }
      });
    } catch (e) {
      showTopMessage("Failed to load goals");
    }

    setState(() => isGoalLoading = false);
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
        CustomFormWidgets.label(context, "Performance Type"),
        const SizedBox(height: 8),
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
          child: DropdownButtonFormField<String>(
            value: selectedGoalCode,

            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            hint: Text(
              "Select Goal",
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
            onChanged: (value) {
              setState(() {
                selectedGoalCode = value;

                final selectedGoal = goalsList.firstWhere(
                  (g) => g['goalCode'].toString() == value,
                );
                goalStartDate = DateTime.parse(selectedGoal['startDate']);
                goalDueDate = DateTime.parse(selectedGoal['dueDate']);
              });
            },
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

        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Start Date"),
        const SizedBox(height: 8),
        CustomFormWidgets.dateField(
          controller: createdDateController,
          onTap: () => _selectDate(context, createdDateController, true),
        ),

        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Due Date"),
        const SizedBox(height: 8),
        CustomFormWidgets.dateField(
          controller: dueDateController,
          onTap: () => _selectDate(context, dueDateController, false),
        ),

        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "Start Time"),
        const SizedBox(height: 8),
        CustomFormWidgets.timeField(
          controller: startTimeController,
          onTap: () async {
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
            if (picked != null) {
              setState(() {
                startTime = picked;
                startTimeController.text = formatTimeOfDay(picked);
              });
            }
          },
        ),

        const SizedBox(height: 20),
        CustomFormWidgets.label(context, "End Time"),
        const SizedBox(height: 8),
        CustomFormWidgets.timeField(
          controller: endTimeController,
          onTap: () async {
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
            if (picked != null) {
              setState(() {
                endTime = picked;
                endTimeController.text = formatTimeOfDay(picked);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _goalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFormWidgets.label(context, "Goal Title"),
        const SizedBox(height: 8),
        CustomFormWidgets.textField(
          context,
          goalTitleController,
          hint: "Enter goal title",
        ),

        const SizedBox(height: 20),

        CustomFormWidgets.label(context, "Start Date"),
        const SizedBox(height: 8),
        CustomFormWidgets.dateField(
          controller: goalStartController,
          onTap: () => selectDate(context, goalStartController, true),
        ),

        const SizedBox(height: 20),

        CustomFormWidgets.label(context, "Due Date"),
        const SizedBox(height: 8),
        CustomFormWidgets.dateField(
          controller: goalDueController,
          onTap: () => selectDate(context, goalDueController, false),
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
      ],
    );
  }
}
