import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/task_assign_users.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';

class EditTask extends StatefulWidget {
  final TaskModel task;

  const EditTask({super.key, required this.task});

  @override
  State<EditTask> createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriController = TextEditingController();
  final TextEditingController createdDateController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  String? selectedPriority;
  DateTime? dueDate;

  bool _isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  List<UserModel> assignedUsers = [];

  @override
  void initState() {
    super.initState();
    _setInitialData();
  }

  void _setInitialData() {
    nameController.text = widget.task.task ?? '';
    descriController.text = widget.task.description ?? '';
    selectedPriority = widget.task.priority;

    if (widget.task.createdAt != null) {
      createdDateController.text = widget.task.createdAt!.split("T").first;
    }

    if (widget.task.dueDate != null) {
      dueDate = DateTime.tryParse(widget.task.dueDate!);
      dueDateController.text = widget.task.dueDate!.split("T").first;
    }

    // SAFE assigned users parsing
    assignedUsers = (widget.task.assignedTo ?? [])
        .whereType<Map<String, dynamic>>()
        .map((u) => UserModel.fromJson(u))
        .toList();
  }

  Future<void> _selectDueDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dueDate = picked;
        dueDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
      setState(() => _showTopMessage = false);
    });
  }

Future<void> _assignUsers() async {
  final users = await SuperAdminService.getAllUsers();

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AssignUsersPage(
        users: users,
        selectedUsers: assignedUsers,
      ),
    ),
  );

  if (result != null && result is List<UserModel>) {
    setState(() {
      assignedUsers = result;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Task"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _assignUsers,
                        icon: const Icon(
                          Icons.person_add,
                       
                        ),
                        label:  Text(
                          "Assign Users",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  CustomFormWidgets.label(context, "Task Name"),
                  CustomFormWidgets.textField(context, nameController),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Description"),
                  CustomFormWidgets.textField(
                    context,
                    descriController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Priority"),
                  CustomFormWidgets.dropdown(
                    context: context,
                    value: selectedPriority,
                    items: ["Normal", "Medium", "High"],
                    onChanged: (v) => setState(() => selectedPriority = v),
                  ),
                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Start Date"),
                  CustomFormWidgets.dateField(
                    controller: createdDateController,
                    onTap: () {},
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Due Date"),
                  CustomFormWidgets.dateField(
                    controller: dueDateController,
                    onTap: _selectDueDate,
                  ),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Assigned Members"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignedUsers.map((user) {
                      return Chip(
                        label: Text(user.name),
                        deleteIcon: const Icon(Icons.close,color: Colors.white,),
                        onDeleted: () {
                          setState(() {
                            assignedUsers.removeWhere(
                              (u) => u.userId == user.userId,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: AppButton(
                      text: "Update Task",
                      isLoading: _isLoading,
                      onPressed: () async {
                        if (assignedUsers.isEmpty) {
                          showTopMessage("Please assign at least one user");
                          return;
                        }

                        setState(() => _isLoading = true);

                        final success = await SuperAdminService.updateTask(
                          EditTaskRequest(
                            taskCode: widget.task.taskCode!,
                            task: nameController.text.trim(),
                            description: descriController.text.trim(),
                            priority: selectedPriority!,
                            dueDate: dueDate!,
                            assignedToIds: assignedUsers
                                .map((u) => u.userId)
                                .toList(),
                          ),
                        );

                        setState(() => _isLoading = false);

                        if (success) {
                          showTopMessage(
                            "Task updated successfully",
                            isError: false,
                          );
                          await Future.delayed(const Duration(seconds: 1));
                          Navigator.pop(context, true);
                        } else {
                          showTopMessage("Failed to update task");
                        }
                      },

                   color: Theme.of(context).colorScheme.secondary,
                                txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

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
}
