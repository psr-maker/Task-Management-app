import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/task_assign_users.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
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
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  List<RemovedUser> removedUsers = [];
  String? selectedPriority;
  DateTime? dueDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

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

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;

    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  void _setInitialData() {
    nameController.text = widget.task.task;
    descriController.text = widget.task.description;
    selectedPriority = widget.task.priority;

    createdDateController.text = widget.task.createdAt.split("T").first;

    if (widget.task.dueDate != null) {
      dueDate = DateTime.tryParse(widget.task.dueDate!);
      dueDateController.text = widget.task.dueDate!.split("T").first;
    }

    if (widget.task.startTime != null) {
      startTime = _parseTimeOfDay(widget.task.startTime);
      startTimeController.text = widget.task.startTime!;
    }

    if (widget.task.endTime != null) {
      endTime = _parseTimeOfDay(widget.task.endTime);
      endTimeController.text = widget.task.endTime!;
    }

    // Quantity
    if (widget.task.quantity != null) {
      quantityController.text = widget.task.quantity.toString();
    }

    // SAFE assigned users parsing
    assignedUsers = (widget.task.assignedTo)
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

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart
        ? startTime ?? const TimeOfDay(hour: 9, minute: 0)
        : endTime ?? const TimeOfDay(hour: 10, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
          startTimeController.text =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        } else {
          endTime = picked;
          endTimeController.text =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
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
      setState(() => _showTopMessage = false);
    });
  }

  Future<void> _assignUsers() async {
    final users = await SuperAdminService.getAllUsers();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AssignUsersPage(users: users, selectedUsers: assignedUsers),
      ),
    );

    if (result != null && result is List<UserModel>) {
      setState(() {
        assignedUsers = result;

        removedUsers.removeWhere(
          (removed) => assignedUsers.any(
            (assigned) => assigned.userId == removed.userId,
          ),
        );
      });
    }
  }

  Future<String?> showReasonDialog() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Removal Reason"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Enter reason"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> showQuantityReductionDialog({
    required int oldQuantity,
    required int newQuantity,
  }) async {
    final remaining = oldQuantity - newQuantity;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Quantity Reduced"),
          content: Text(
            "Original quantity: $oldQuantity\n"
            "New quantity: $newQuantity\n"
            "Remaining quantity: $remaining\n\n"
            "Do you want to create a new task for the remaining "
            "$remaining quantity?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _assignUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.person_add),
                        label: const Text("Assign Users"),
                      ),
                    ],
                  ),
                  CustomFormWidgets.label(context, "Task Name"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.textField(context, nameController),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Description"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.textField(
                    context,
                    descriController,
                    maxLines: 4,
                  ),
                  if (widget.task.performanceType.toLowerCase() == "qty") ...[
                    const SizedBox(height: 20),

                    CustomFormWidgets.label(context, "Quantity"),

                    const SizedBox(height: 10),

                    CustomFormWidgets.textField(
                      context,
                      quantityController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Priority"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.dropdown(
                    context: context,
                    value: selectedPriority,
                    items: ["Normal", "Medium", "High"],
                    onChanged: (v) => setState(() => selectedPriority = v),
                  ),
                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Start Date"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.dateField(
                    controller: createdDateController,
                    onTap: () {},
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Due Date"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.dateField(
                    controller: dueDateController,
                    onTap: _selectDueDate,
                  ),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Start Time"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.timeField(
                    controller: startTimeController,
                    onTap: () => _selectTime(true),
                  ),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "End Time"),
                  const SizedBox(height: 10),
                  CustomFormWidgets.timeField(
                    controller: endTimeController,
                    onTap: () => _selectTime(false),
                  ),

                  const SizedBox(height: 20),
                  CustomFormWidgets.label(context, "Assigned Members"),
                  const SizedBox(height: 10),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignedUsers.map((user) {
                      return Chip(
                        label: Text(user.name),
                        deleteIcon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onDeleted: () async {
                          final reason = await showReasonDialog();

                          if (reason == null) return;

                          setState(() {
                            removedUsers.add(
                              RemovedUser(userId: user.userId, reason: reason),
                            );

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

                        // Check quantity reduction
                        bool createRemainingTask = false;
                        if (widget.task.performanceType.toLowerCase() == "qty") {
                          final oldQuantity = widget.task.quantity ?? 0;

                          final newQuantity = int.tryParse(
                            quantityController.text.trim(),
                          );

                          if (newQuantity == null) {
                            showTopMessage("Please enter a valid quantity");
                            return;
                          }

                          if (newQuantity <= 0) {
                            showTopMessage("Quantity must be greater than 0");
                            return;
                          }

                          // Quantity was reduced
                          if (newQuantity < oldQuantity) {
                            final result = await showQuantityReductionDialog(
                              oldQuantity: oldQuantity,
                              newQuantity: newQuantity,
                            );

                            // User closed dialog
                            if (result == null) {
                              return;
                            }

                            createRemainingTask = result;
                          }
                        }
                        setState(() => _isLoading = true);

                        final success = await SuperAdminService.updateTask(
                          EditTaskRequest(
                            taskCode: widget.task.taskCode,
                            task: nameController.text.trim(),
                            description: descriController.text.trim(),
                            priority: selectedPriority!,
                            dueDate: dueDate!,
                            quantity:
                                widget.task.performanceType.toLowerCase() ==
                                    "qty"
                                ? int.tryParse(quantityController.text.trim())
                                : null,
                            startTime: startTimeController.text.isNotEmpty
                                ? startTimeController.text
                                : null,
                            endTime: endTimeController.text.isNotEmpty
                                ? endTimeController.text
                                : null,
                            assignedToIds: assignedUsers
                                .map((u) => u.userId)
                                .toList(),
                            removedUsers: removedUsers,
                          ),
                        );

                        setState(() => _isLoading = false);

                        if (success) {
                          if (createRemainingTask &&
                              widget.task.performanceType.toLowerCase() ==
                                  "qty") {
                            final oldQuantity = widget.task.quantity ?? 0;
                            final newQuantity = int.tryParse(
                              quantityController.text.trim(),
                            );
                            final remaining = oldQuantity - (newQuantity ?? 0);

                            if (remaining > 0) {
                              final initialAssignedAt =
                                  DateTime.tryParse(widget.task.createdAt.split("T").first) ??
                                      DateTime.now();

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Createtask(
                                    assignedToIds: assignedUsers
                                        .map((u) => u.userId)
                                        .toList(),
                                    initialTaskName: nameController.text.trim(),
                                    initialDescription: descriController.text.trim(),
                                    initialGoalCode: widget.task.goalCode,
                                    initialPriority: selectedPriority,
                                    initialPerformanceType:
                                        widget.task.performanceType,
                                    initialQuantity: remaining,
                                    initialAssignedAt: initialAssignedAt,
                                    initialDueDate: dueDate,
                                    initialStartTime:
                                        startTimeController.text.isNotEmpty
                                            ? startTimeController.text
                                            : null,
                                    initialEndTime: endTimeController.text.isNotEmpty
                                        ? endTimeController.text
                                        : widget.task.endTime,
                                    initialIsTask: true,
                                  ),
                                ),
                              );
                            }
                          }

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
