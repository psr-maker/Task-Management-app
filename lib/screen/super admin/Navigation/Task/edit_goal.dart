import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class EditGoalPage extends StatefulWidget {
  final Map goal;

  const EditGoalPage({super.key, required this.goal});

  @override
  State<EditGoalPage> createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  final TextEditingController goalTitleController = TextEditingController();
  final TextEditingController goalStartController = TextEditingController();
  final TextEditingController goalDueController = TextEditingController();

  String? selectedPriority;
  bool isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();

    goalTitleController.text = widget.goal["title"] ?? "";

    goalStartController.text = AppHelpers.formatDate(widget.goal["startDate"]);
    goalDueController.text = AppHelpers.formatDate(widget.goal["dueDate"]);

    selectedPriority = widget.goal["priority"];
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

  /// ✅ Common Date Picker
  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  /// ✅ Update
  Future<void> updateGoal() async {
    setState(() => isLoading = true);

    final data = {
      "title": goalTitleController.text,
      "dueDate": goalDueController.text,
      "priority": selectedPriority,
    };

    bool success = await SuperAdminService.updateGoal(
      widget.goal["goalCode"],
      data,
    );

    setState(() => isLoading = false);
    if (success) {
      showTopMessage("Goal updated successfully", isError: false);
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, true);
    } else {
      showTopMessage("Failed to update goal");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Goal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
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
                  onTap: null,
                  enabled: false,
                ),
                const SizedBox(height: 20),
                CustomFormWidgets.label(context, "Due Date"),
                const SizedBox(height: 8),
                CustomFormWidgets.dateField(
                  controller: goalDueController,
                  onTap: () => _pickDate(goalDueController),
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
                const SizedBox(height: 30),

                Center(
                  child: AppButton(
                    text: "Update Goal",
                    isLoading: isLoading,
                    onPressed: isLoading ? null : updateGoal,

                    color: Theme.of(context).colorScheme.secondary,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            if (_showTopMessage && _topMessage != null)
              Positioned(
                top: _showTopMessage ? 40 : -120,
                left: 16,
                right: 16,
                child: Msgsnackbar(
                  context,
                  message: _topMessage!,
                  isError: _isErrorMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
