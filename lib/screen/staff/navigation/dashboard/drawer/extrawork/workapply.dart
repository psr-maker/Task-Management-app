import 'package:flutter/material.dart';
import 'package:staff_work_track/services/admin_service.dart';

class ExtraWorkApply extends StatefulWidget {
  const ExtraWorkApply({super.key});

  @override
  State<ExtraWorkApply> createState() =>
      _ExtraWorkApplyState();
}

class _ExtraWorkApplyState
    extends State<ExtraWorkApply> {

  final AdminService _service = AdminService();

  final TextEditingController reasonController =
      TextEditingController();

  DateTime? workedDate;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  String? workType;

  bool isLoading = false;

  final List<Map<String, String>> workTypes = [
    {
      'value': 'WeeklyOff',
      'label': 'Weekly Off',
    },
    {
      'value': 'PublicHoliday',
      'label': 'Public Holiday',
    },
    {
      'value': 'CompanyHoliday',
      'label': 'Company Holiday',
    },
    {
      'value': 'Other',
      'label': 'Other',
    },
  ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // Date Picker
  // --------------------------------------------------

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

  // --------------------------------------------------
  // Start Time
  // --------------------------------------------------

  Future<void> selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 9,
        minute: 0,
      ),
    );

    if (time != null) {
      setState(() {
        startTime = time;
      });
    }
  }

  // --------------------------------------------------
  // End Time
  // --------------------------------------------------

  Future<void> selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 18,
        minute: 0,
      ),
    );

    if (time != null) {
      setState(() {
        endTime = time;
      });
    }
  }

  // --------------------------------------------------
  // Format Date
  // --------------------------------------------------

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Select worked date';
    }

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  // --------------------------------------------------
  // Format Time
  // --------------------------------------------------

  String formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // --------------------------------------------------
  // API Time Format
  // --------------------------------------------------

  String apiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  // --------------------------------------------------
  // Calculate Hours
  // --------------------------------------------------

  String getTotalHours() {
    if (startTime == null || endTime == null) {
      return '0 Hours';
    }

    final startMinutes =
        startTime!.hour * 60 + startTime!.minute;

    final endMinutes =
        endTime!.hour * 60 + endTime!.minute;

    final difference =
        endMinutes - startMinutes;

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

  // --------------------------------------------------
  // Submit
  // --------------------------------------------------

  Future<void> submitExtraWork() async {
    if (workedDate == null) {
      showMessage('Please select worked date');
      return;
    }

    if (workType == null) {
      showMessage('Please select work type');
      return;
    }

    if (startTime == null) {
      showMessage('Please select start time');
      return;
    }

    if (endTime == null) {
      showMessage('Please select end time');
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      showMessage('Please enter reason');
      return;
    }

    final startMinutes =
        startTime!.hour * 60 + startTime!.minute;

    final endMinutes =
        endTime!.hour * 60 + endTime!.minute;

    if (endMinutes <= startMinutes) {
      showMessage(
        'End time must be greater than start time',
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Extra work application submitted successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // --------------------------------------------------
  // Message
  // --------------------------------------------------

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extra Work'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Text(
                'Extra Work Application',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

          

              const SizedBox(height: 15),

              // -----------------------------------------
              // Worked Date
              // -----------------------------------------

              const Text(
                'Worked Date',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
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
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [

                      const Icon(
                        Icons.calendar_month,
                      ),

                      const SizedBox(width: 12),

                      Text(
                        formatDate(workedDate),
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------------------
              // Work Type
              // -----------------------------------------

              const Text(
                'Work Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: workType,
                decoration: InputDecoration(
                  hintText: 'Select work type',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
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

              // -----------------------------------------
              // Start / End Time
              // -----------------------------------------

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


        

              // -----------------------------------------
              // Reason
              // -----------------------------------------

              const Text(
                'Reason',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Enter reason for extra work',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // -----------------------------------------
              // Submit
              // -----------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : submitExtraWork,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [

                Icon(icon, size: 20),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    value,
                    overflow:
                        TextOverflow.ellipsis,
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