import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
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
        final theme = Theme.of(context);
        if (theme.brightness == Brightness.dark) return child!;
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.secondary,
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
    showAppMessage(context, message);
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
        ? "Missing Punch In"
        : "Missing Punch Out";

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
    final web = WebPushedChrome.isWeb(context);
    if (web) return _webRequest();
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: web ? null : const Text("Attendance Correction"),
      ),

      body: WebPushedChrome.body(
        context,
        title: 'Attendance Correction',
        subtitle: 'Request a missed punch in or punch out',
        panel: false,
        child: WebFormFrame(
        child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(web ? 24 : 15),
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
                        color: WebTheme.surfaceOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WebTheme.lineOf(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: WebTheme.brandOf(context),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              formatDate(selectedDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: WebTheme.inkOf(context),
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
                  _sectionTitle("What did you Missing?"),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _correctionCard(
                          type: "morning",
                          icon: Icons.wb_sunny_outlined,
                          title: "Missing Punch In",
                          subtitle: "Morning",
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _correctionCard(
                          type: "evening",
                          icon: Icons.nights_stay_outlined,
                          title: "Missing Punch Out",
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
                        color: WebTheme.surfaceOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WebTheme.lineOf(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            color: WebTheme.brandOf(context),
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
                                    ? WebTheme.mutedOf(context)
                                    : WebTheme.inkOf(context),
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
                    style: TextStyle(color: WebTheme.inkOf(context)),
                    decoration: InputDecoration(
                      hintText: "Enter reason for missing punch...",
                      hintStyle: TextStyle(color: WebTheme.mutedOf(context)),
                      filled: true,
                      fillColor: WebTheme.surfaceOf(context),
                      contentPadding: const EdgeInsets.all(16),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: WebTheme.lineOf(context)),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: WebTheme.lineOf(context)),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: WebTheme.brandOf(context),
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
        ),
      ),
    );
  }

  Widget _webRequest() {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: Stack(
        children: [
          Padding(
            padding: AppLayout.pagePadding(context),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, size: 18, color: WebTheme.brandOf(context)),
                    ),
                    Text(
                      'Attendance correction',
                      style: TextStyle(
                        color: WebTheme.brandOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          decoration: BoxDecoration(
                            color: WebTheme.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WebTheme.lineOf(context)),
                          ),
                          child: Column(
                            children: [
                              _webPair(
                                _webDate(),
                                _webDrop(),
                              ),
                              _webTime(),
                              const SizedBox(height: 14),
                              _webReason(),
                              const SizedBox(height: 16),
                              Center(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: WebTheme.brand,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                  ),
                                  onPressed: submitRequest,
                                  child: const Text('Submit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 8 : -120,
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

  Widget _webPair(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _webLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: WebTheme.mutedOf(context),
        ),
      ),
    );
  }

  InputDecoration _webDecoration(IconData icon) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
    );
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      suffixIcon: Icon(icon, size: 18, color: WebTheme.brandOf(context)),
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: WebTheme.brandOf(context))),
    );
  }

  Widget _webDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webLabel('Work date'),
        InkWell(
          onTap: selectDate,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _webDecoration(Icons.calendar_today),
            child: Text(
              formatDate(selectedDate),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WebTheme.brandOf(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _webDrop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webLabel('Type'),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: correctionType,
              isExpanded: true,
              dropdownColor: WebTheme.surfaceOf(context),
              iconEnabledColor: WebTheme.brandOf(context),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WebTheme.brandOf(context)),
              items: [
                DropdownMenuItem(
                  value: 'morning',
                  child: Text(
                    'Punch in',
                    style: TextStyle(fontSize: 14, color: WebTheme.inkOf(context)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'evening',
                  child: Text(
                    'Punch out',
                    style: TextStyle(fontSize: 14, color: WebTheme.inkOf(context)),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => correctionType = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _webTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webLabel('Punch time'),
        InkWell(
          onTap: selectTime,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _webDecoration(Icons.access_time),
            child: Text(
              selectedTime == null ? 'Select time' : selectedTime!.format(context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selectedTime == null ? WebTheme.mutedOf(context) : WebTheme.brandOf(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _webReason() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _webLabel('Reason'),
        TextField(
          controller: reasonController,
          maxLines: 3,
          style: TextStyle(fontSize: 14, color: WebTheme.inkOf(context)),
          decoration: InputDecoration(
            hintText: 'Reason',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(color: WebTheme.brandOf(context))),
          ),
        ),
      ],
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
              ? WebTheme.brandSoftOf(context)
              : WebTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? WebTheme.brandOf(context) : WebTheme.lineOf(context),
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
                      ? WebTheme.brandOf(context)
                      : WebTheme.mutedOf(context),
                  size: 28,
                ),

                if (selected)
                  Icon(
                    Icons.check_circle,
                    color: WebTheme.brandOf(context),
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
                color: selected ? WebTheme.brandOf(context) : WebTheme.inkOf(context),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: WebTheme.mutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}
