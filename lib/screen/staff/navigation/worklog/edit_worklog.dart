import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/widgets/customfieldwidget.dart';

class EditWorklogPage extends StatefulWidget {
  final int worklogId;
  final String title;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime workDate;

  const EditWorklogPage({
    super.key,
    required this.worklogId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.workDate,
  });

  @override
  State<EditWorklogPage> createState() => _EditWorklogPageState();
}

class _EditWorklogPageState extends State<EditWorklogPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  late TimeOfDay startTime;
  late TimeOfDay endTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title);
    descriptionController = TextEditingController(text: widget.description);
    startTime = widget.startTime;
    endTime = widget.endTime;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AnnouncementService.editWorkLog(
        workLogId: widget.worklogId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        workDate: widget.workDate,
        startTime: startTime,
        endTime: endTime,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Worklog"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Work Title",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 15),
              CustomTextField(controller: titleController),

              const SizedBox(height: 20),
              Text(
                "Work Description",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(
                  hintText: "Enter Work Description",
                  hintStyle: Theme.of(context).textTheme.headlineSmall,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Work Date: ${widget.workDate.toIso8601String().split("T")[0]}",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(true),
                      child: _timeCard("Start Time", startTime.format(context)),
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
                  text: "Update",
                  isLoading: _isLoading,
                  onPressed: _submit,
                  color: Theme.of(context).colorScheme.secondary,
                  txtcolor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
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
          Text(label, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(time, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
