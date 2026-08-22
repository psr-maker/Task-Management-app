import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';

class ExtraWorkApply extends StatefulWidget {
  const ExtraWorkApply({super.key});

  @override
  State<ExtraWorkApply> createState() => _ExtraWorkApplyState();
}

class _ExtraWorkApplyState extends State<ExtraWorkApply> {
  final AdminService _service = AdminService();

  final TextEditingController reasonController = TextEditingController();

  DateTime? workedDate;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  String? workType;

  bool isLoading = false;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  final List<Map<String, String>> workTypes = [
    {'value': 'WeeklyOff', 'label': 'Weekly Off'},
    {'value': 'PublicHoliday', 'label': 'Public Holiday'},
    {'value': 'CompanyHoliday', 'label': 'Company Holiday'},
    {'value': 'Other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        workedDate = date;
      });
    }
  }

  Future<void> selectStartTime() async {
    final time = await showTimePicker(
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
    if (time != null) {
      setState(() {
        startTime = time;
      });
    }
  }

  Future<void> selectEndTime() async {
    final time = await showTimePicker(
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

    if (time != null) {
      setState(() {
        endTime = time;
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '00-00-0000';
    }

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String apiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  String getTotalHours() {
    if (startTime == null || endTime == null) {
      return '0 Hours';
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    final difference = endMinutes - startMinutes;

    if (difference <= 0) {
      return '0 Hours';
    }

    final hours = difference ~/ 60;
    final minutes = difference % 60;

    if (minutes == 0) {
      return '$hours Hours';
    }

    return '$hours Hours $minutes Minutes';
  }

  Future<void> submitExtraWork() async {
    if (workedDate == null) {
      showTopMessage("Please select worked date", isError: true);
      return;
    }

    if (workType == null) {
      showTopMessage("Please select work type", isError: true);
      return;
    }

    if (startTime == null) {
      showTopMessage("Please select start time", isError: true);
      return;
    }

    if (endTime == null) {
      showTopMessage("Please select end time", isError: true);
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      showTopMessage("Please enter reason", isError: true);
      return;
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    if (endMinutes <= startMinutes) {
      showTopMessage("End time must be greater than start time", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _service.addExtraWork(
        workedDate: workedDate!,
        workType: workType!,
        startTime: apiTime(startTime!),
        endTime: apiTime(endTime!),
        reason: reasonController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showTopMessage(
        "Extra work application submitted successfully",
        isError: false,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      showTopMessage("Failed to submit extra work application", isError: true);

      showMessage(e.toString().replaceFirst('Exception: ', ''));
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

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty Off'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extra Duty Application',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Worked Date',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: selectDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month),

                          const SizedBox(width: 12),

                          Text(
                            formatDate(workedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Work Type',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: workType,
                    decoration: InputDecoration(
                      hintText: 'Select work type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: Theme.of(context).colorScheme.background,
                    style: Theme.of(context).textTheme.labelMedium,
                    items: workTypes.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        workType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _timeField(
                          title: 'Start Time',
                          value: formatTime(startTime),
                          icon: Icons.login,
                          onTap: selectStartTime,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _timeField(
                          title: 'End Time',
                          value: formatTime(endTime),
                          icon: Icons.logout,
                          onTap: selectEndTime,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Reason',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for extra work',
                      hintStyle: Theme.of(context).textTheme.labelSmall,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  Center(
                    child: AppButton(
                      text: "Submit",
                      isLoading: isLoading,
                      onPressed: isLoading ? null : submitExtraWork,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              if (_topMessage != null)
                AnimatedPositioned(
                  top: _showTopMessage ? 20 : -120,
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
      ),
    );
  }

  Widget _timeField({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),

        const SizedBox(height: 10),

        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
