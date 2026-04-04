import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class AddWorklogPage extends StatefulWidget {
  const AddWorklogPage({super.key});

  @override
  State<AddWorklogPage> createState() => _AddWorklogPageState();
}

class _AddWorklogPageState extends State<AddWorklogPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isLoading = false;

  DateTime selectedDate = DateTime.now();

  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final result = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );

    if (result != null) {
      setState(() {
        isStart ? startTime = result : endTime = result;
      });
    }
  }

  Future<void> _submit(bool isSubmit) async {
    if (titleController.text.trim().isEmpty &&
        descriptionController.text.trim().isEmpty) {
      showTopMessage("Please enter Title or Description", isError: true);

      return;
    }
    setState(() => _isLoading = true);

    try {
      await AnnouncementService.addWorkLog(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        workDate: selectedDate,
        startTime: startTime,
        endTime: endTime,
        isSubmit: isSubmit,
      );

      if (!mounted) return;
      showTopMessage("Worklog added successfully", isError: false);
    } catch (e) {
      showTopMessage(e.toString(), isError: true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add WorkLog"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomFormWidgets.label(context, "Work Title"),
                const SizedBox(height: 10),
                CustomFormWidgets.textField(
                  context,
                  titleController,
                  hint: "Enter Work Title",
                ),

                const SizedBox(height: 15),
                CustomFormWidgets.label(context, "Work Description"),
                const SizedBox(height: 10),
                CustomFormWidgets.textField(
                  context,
                  descriptionController,
                  hint: "Enter Work Description",
                ),

                //  const SizedBox(height: 15),

                /// Date Picker
                ListTile(
                  title: Text(
                    "Work Date",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(true),
                        child: _timeCard(
                          "Start Time",
                          startTime.format(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(false),
                        child: _timeCard("End Time", endTime.format(context)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Center(
                  child: AppButton(
                    text: "Save Draft",
                    isLoading: _isLoading,
                    onPressed: () => _submit(false),
                    color: Theme.of(context).colorScheme.secondary,
                    txtcolor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            if (_topMessage != null)
              AnimatedPositioned(
                top: _showTopMessage ? 0 : -120,
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
      ),
    );
  }

  Widget _timeCard(String label, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(time, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
