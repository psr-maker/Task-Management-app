import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';

class PunchCorrection extends StatefulWidget {
  const PunchCorrection({super.key});

  @override
  State<PunchCorrection> createState() => _PunchCorrectionState();
}

class _PunchCorrectionState extends State<PunchCorrection> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  String correctionType = "morning";
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  final TextEditingController reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
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
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
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

  Future<void> submitRequest() async {
    if (selectedTime == null) {
      showTopMessage("Please select punch time", isError: true);
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      showTopMessage("Please enter a reason", isError: true);
      return;
    }

    // Convert UI value to API value
    final String apiCorrectionType = correctionType == "morning"
        ? "Forgot Punch In"
        : "Forgot Punch Out";

    // Convert TimeOfDay to HH:mm:ss
    final String punchTime =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:"
        "${selectedTime!.minute.toString().padLeft(2, '0')}:00";

    final bool success = await AdminService.createPunchCorrection(
      date: selectedDate,
      correctionType: apiCorrectionType,
      punchTime: punchTime,
      reason: reasonController.text.trim(),
    );

    if (success) {
      showTopMessage("Punch correction submitted successfully", isError: false);
      Navigator.pop(context, true);
      setState(() {
        reasonController.clear();
        selectedTime = null;
        correctionType = "morning";
      });
    } else {
      showTopMessage("Failed to submit punch correction", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Punch Correction"),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  _sectionTitle("Date"),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: selectDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xff194d26),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              formatDate(selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Correction type
                  _sectionTitle("What did you forget?"),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _correctionCard(
                          type: "morning",
                          icon: Icons.wb_sunny_outlined,
                          title: "Forgot Punch In",
                          subtitle: "Morning",
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _correctionCard(
                          type: "evening",
                          icon: Icons.nights_stay_outlined,
                          title: "Forgot Punch Out",
                          subtitle: "Evening",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Time
                  _sectionTitle("Punch Time"),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: selectTime,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            color: Color(0xff194d26),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              selectedTime == null
                                  ? "Select punch time"
                                  : selectedTime!.format(context),
                              style: TextStyle(
                                fontSize: 15,
                                color: selectedTime == null
                                    ? Colors.grey
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reason
                  _sectionTitle("Reason"),

                  const SizedBox(height: 10),

                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Enter reason for missing punch...",
                      hintStyle: Theme.of(context).textTheme.labelSmall,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xff194d26),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  Center(
                    child: AppButton(
                      text: "Submit",
                      onPressed: submitRequest,
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),

                  // Submit
                  const SizedBox(height: 20),
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

  Widget _sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineLarge);
  }

  Widget _correctionCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = correctionType == type;

    return InkWell(
      onTap: () {
        setState(() {
          correctionType = type;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        height: 120,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff194d26).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xff194d26) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? const Color(0xff194d26)
                      : Colors.grey.shade600,
                  size: 28,
                ),

                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xff194d26),
                    size: 20,
                  ),
              ],
            ),

            const Spacer(),

            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xff194d26) : Colors.black87,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
