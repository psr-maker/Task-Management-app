import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/task_assign_users.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Task/goalntask_create.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/form_popup.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/utils/time_utils.dart';

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
  String selectedPerformanceType = "Default";
  DateTime? dueDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool _isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  List<UserModel> assignedUsers = [];
  String? _goalTitle;
  bool _loadingGoalTitle = false;

  @override
  void initState() {
    super.initState();
    _setInitialData();
    _loadGoalTitle();
  }

  Future<void> _loadGoalTitle() async {
    final code = widget.task.goalCode;
    if (code == null || code.isEmpty) return;

    setState(() => _loadingGoalTitle = true);
    try {
      List goals = [];
      try {
        goals = await SuperAdminService.getGoalsname();
      } catch (_) {
        goals = await SuperAdminService.getGoals();
      }
      final title = _goalTitleFor(goals, code);
      if (!mounted) return;
      setState(() => _goalTitle = title);
    } catch (_) {}
    if (mounted) setState(() => _loadingGoalTitle = false);
  }

  String? _goalTitleFor(List goals, String code) {
    for (final item in goals) {
      if (item is! Map) continue;
      final itemCode = (item["goalCode"] ?? item["code"] ?? "").toString();
      if (itemCode == code) {
        final title = (item["title"] ?? item["goal"] ?? item["name"] ?? "")
            .toString()
            .trim();
        if (title.isNotEmpty) return title;
      }
      final months = item["monthlyGoals"] ?? item["MonthlyGoals"];
      if (months is List) {
        final nested = _goalTitleFor(months, code);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
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
    selectedPerformanceType =
        widget.task.performanceType.toLowerCase() == "qty" ? "Qty" : "Default";

    createdDateController.text = TimeUtils.formatDateValue(widget.task.createdAt);

    if (widget.task.dueDate != null) {
      dueDate = DateTime.tryParse(widget.task.dueDate!);
      dueDateController.text = TimeUtils.formatDateValue(widget.task.dueDate);
    }

    if (widget.task.startTime != null) {
      startTime = _parseTimeOfDay(widget.task.startTime);
      startTimeController.text = TimeUtils.formatTime12(widget.task.startTime);
    }

    if (widget.task.endTime != null) {
      endTime = _parseTimeOfDay(widget.task.endTime);
      endTimeController.text = TimeUtils.formatTime12(widget.task.endTime);
    }

    // Quantity
    if (widget.task.quantity != null) {
      quantityController.text = widget.task.quantity.toString();
    }

    // SAFE assigned users parsing
    assignedUsers = widget.task.assignedTo.whereType<Map>().map((user) {
      return UserModel.fromJson(Map<String, dynamic>.from(user));
    }).toList();
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
        dueDateController.text = TimeUtils.formatDate(picked);
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
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
      final formattedTime = TimeUtils.formatTime12(
        "${picked.hour.toString().padLeft(2, '0')}:"
        "${picked.minute.toString().padLeft(2, '0')}",
      );

      setState(() {
        if (isStart) {
          startTime = picked;
          startTimeController.text = formattedTime;
        } else {
          endTime = picked;
          endTimeController.text = formattedTime;
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignUsersPage(selectedUsers: assignedUsers, users: [],),
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

  Widget _assignedMembersBox() {
    final brand = Theme.of(context).colorScheme.secondary;
    const border = Color.fromARGB(255, 25, 77, 38);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: assignedUsers.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No staff assigned",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: assignedUsers.map((user) {
                return InputChip(
                  label: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDeleted: () async {
                    final reason = await showReasonDialog();
                    if (reason == null) return;
                    setState(() {
                      removedUsers.add(
                        RemovedUser(userId: user.userId, reason: reason),
                      );
                      assignedUsers.removeWhere(
                        (item) => item.userId == user.userId,
                      );
                    });
                  },
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black54,
                  ),
                  backgroundColor: brand.withValues(alpha: 0.08),
                  side: BorderSide(color: brand.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalCode = widget.task.goalCode;
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
                        items: const ["Default", "Qty"],
                        onChanged: (value) => setState(() {
                          selectedPerformanceType = value ?? "Default";
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
                        items: const ["Normal", "Medium", "High"],
                        onChanged: (value) =>
                            setState(() => selectedPriority = value),
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
                  Row(
                    children: [
                      Expanded(
                        child: CustomFormWidgets.label(
                          context,
                          "Assigned members",
                        ),
                      ),
                      IconButton(
                        tooltip: "Add members",
                        onPressed: _assignUsers,
                        icon: Icon(
                          Icons.person_add_alt_1,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  _assignedMembersBox(),
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
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(255, 25, 77, 38),
                      ),
                    ),
                    child: Text(
                      _loadingGoalTitle
                          ? "Loading goal..."
                          : (_goalTitle != null && _goalTitle!.isNotEmpty)
                              ? _goalTitle!
                              : (goalCode == null || goalCode.isEmpty)
                                  ? "No goal"
                                  : "Goal",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _row2(
                    _labeled(
                      "Start Date",
                      CustomFormWidgets.dateField(
                        controller: createdDateController,
                        onTap: () {},
                        enabled: false,
                      ),
                    ),
                    _labeled(
                      "Due Date",
                      CustomFormWidgets.dateField(
                        controller: dueDateController,
                        onTap: _selectDueDate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _row2(
                    _labeled(
                      "Start Time",
                      CustomFormWidgets.timeField(
                        controller: startTimeController,
                        onTap: () => _selectTime(true),
                      ),
                      hint: "(optional)",
                    ),
                    _labeled(
                      "Due Time",
                      CustomFormWidgets.timeField(
                        controller: endTimeController,
                        onTap: () => _selectTime(false),
                      ),
                      hint: "(optional)",
                    ),
                  ),
                  const SizedBox(height: 30),
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
                        if (widget.task.performanceType.toLowerCase() ==
                            "qty") {
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
                                ? TimeUtils.toApiTime(startTimeController.text)
                                : null,
                            endTime: endTimeController.text.isNotEmpty
                                ? TimeUtils.toApiTime(endTimeController.text)
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
                                  DateTime.tryParse(
                                    widget.task.createdAt.split("T").first,
                                  ) ??
                                  DateTime.now();

                              await openFormPage(
                                context,
                                Createtask(
                                    assignedToIds: assignedUsers
                                        .map((u) => u.userId)
                                        .toList(),
                                    initialTaskName: nameController.text.trim(),
                                    initialDescription: descriController.text
                                        .trim(),
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
                                    initialEndTime:
                                        endTimeController.text.isNotEmpty
                                        ? endTimeController.text
                                        : widget.task.endTime,
                                    initialIsTask: true,
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
