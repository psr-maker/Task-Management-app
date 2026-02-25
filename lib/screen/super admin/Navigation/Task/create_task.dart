import 'package:flutter/material.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class Createtask extends StatefulWidget {
  final List<int> assignedToIds;

  const Createtask({super.key, required this.assignedToIds});

  @override
  State<Createtask> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<Createtask> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriController = TextEditingController();
  final TextEditingController createdDateController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  String? selectedPriority;
  bool _isLoading = false;
  DateTime? createdDate;
  DateTime? dueDate;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  Future<void> _selectDate(
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
      // assignedById: 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign New Task"),
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
                  CustomFormWidgets.label(context, "Created Date"),
                  const SizedBox(height: 8),
                  CustomFormWidgets.dateField(
                    controller: createdDateController,
                    onTap: () =>
                        _selectDate(context, createdDateController, true),
                  ),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Due Date"),
                  const SizedBox(height: 8),
                  CustomFormWidgets.dateField(
                    controller: dueDateController,
                    onTap: () => _selectDate(context, dueDateController, false),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: AppButton(
                      text: "Create",
                      isLoading: _isLoading,
                      onPressed: _createTask,
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
                backgroundColor: Theme.of(context).primaryColor,
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
