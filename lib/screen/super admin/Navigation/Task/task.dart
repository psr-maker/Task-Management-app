import 'package:flutter/material.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class Ctask extends StatefulWidget {
  final List<int> assignedToIds;

  const Ctask({super.key, required this.assignedToIds});

  @override
  State<Ctask> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<Ctask> {
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
  bool _isLoading = false;
  DateTime? createdDate;
  DateTime? dueDate;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  bool isTask = false;
  List<dynamic> goalsList = [];

  @override
  void initState() {
    super.initState();
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

    // ✅ Apply goal date restriction ONLY for task
    if (isTask && goalStartDate != null && goalDueDate != null) {
      firstDate = goalStartDate!;
      lastDate = goalDueDate!;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        if (isCreated) {
          createdDate = picked;
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
        selectedGoalCode == null ||
        dueDate == null) {
      showTopMessage("Please fill the All Fields", isError: true);
      return;
    }
    setState(() => _isLoading = true);

    bool success = await SuperAdminService.createTask(
      task: nameController.text,
      description: descriController.text,
      priority: selectedPriority!,
      assignedAt: createdDate!,
      dueDate: dueDate!,
      goalCode: selectedGoalCode!,
      assignedToIds: widget.assignedToIds,
    );

    setState(() => _isLoading = false);

    if (success) {
      showTopMessage("Task Created Succesfully", isError: false);
      await Future.delayed(const Duration(seconds: 3));
      Navigator.pop(context, true);
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

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        if (controller == createdDateController) {
          createdDate = picked;
        } else if (controller == dueDateController) {
          dueDate = picked;
        } else if (controller == goalStartController) {
          goalStartDate = picked;
        } else if (controller == goalDueController) {
          goalDueDate = picked;
        }
      });
    }
  }

  
  Future<void> loadGoals() async {
    setState(() => isGoalLoading = true);

    try {
      final response = await SuperAdminService.getGoalsname();

      setState(() {
        goalsList = response;
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
        title: const Text("Create Task"),
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
                  _taskForm(),

                  Center(
                    child: AppButton(
                      text: "Create",
                      isLoading: _isLoading,
                      onPressed: () {
                        _createTask();
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
    if (!goalsList.any((g) => g['goalCode'].toString() == selectedGoalCode)) {
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
      ],
    );
  }
}
