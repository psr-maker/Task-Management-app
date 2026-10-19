import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class Leaveapply extends StatefulWidget {
  const Leaveapply({super.key});

  @override
  State<Leaveapply> createState() => _LeaveapplyState();
}

class _LeaveapplyState extends State<Leaveapply> {
  final nameController = TextEditingController();
  final designationController = TextEditingController();
  final reasonController = TextEditingController();
  final emergencyController = TextEditingController();
  final leavetypController = TextEditingController();
  bool _isLoading = false;
  DateTime? fromDate;
  DateTime? toDate;
  List<Map<String, dynamic>> leaveDays = [];
  double totalLeave = 0;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  String applicationType = "Leave";
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  double totalHours = 0;
  int totalMinutes = 0;

  bool hasApprovedCompensation = false;

  List<Map<String, dynamic>> availableCompensation = [];

  static const List<String> leaveCategories = ["CL", "LOP"];

  @override
  void initState() {
    super.initState();
    checkCompensationEligibility();
  }

  Future<void> checkCompensationEligibility() async {
    try {
      final service = AdminService();
      final data = await service.getMyExtraWork();
      // Only rows that are Approved AND not already consumed by a
      // previous compensation leave should ever be selectable.
      final approvedUnused = data.where((e) {
        final status = (e["status"] ?? "").toString().toLowerCase();
        final used = e["isCompensationUsed"] == true;
        return status == "approved" && !used;
      }).toList();
      if (!mounted) return;
      setState(() {
        hasApprovedCompensation = approvedUnused.isNotEmpty;
        availableCompensation = approvedUnused
            .map(
              (e) => {
                "id": e["id"],
                "date": DateTime.parse(e["workedDate"].toString()),
              },
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasApprovedCompensation = false;
      });
    }
  }

  Future pickFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked;
        generateDays();
      });
    }
  }

  Future pickToDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: fromDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        toDate = picked;
        generateDays();
      });
    }
  }

  void generateDays() {
    if (fromDate == null || toDate == null) return;
    leaveDays.clear();
    DateTime current = fromDate!;
    while (!current.isAfter(toDate!)) {
      leaveDays.add({
        "date": current,
        "type": "Full Day", // Full Day / First Half / Second Half / Holiday
        "leavetyp": "CL", // CL / LOP / Compensation
        "compensationId":
            null, // ExtraWork.Id selected when leavetyp == Compensation
      });
      current = current.add(const Duration(days: 1));
    }
    calculateTotal();
  }

  void calculateTotal() {
    totalLeave = 0;

    for (var day in leaveDays) {
      if (day["type"] == "Full Day") {
        totalLeave += 1;
      } else if (day["type"] == "First Half" || day["type"] == "Second Half") {
        totalLeave += 0.5;
      }
    }
    setState(() {});
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

  Future<void> submitLeave() async {
    if (fromDate == null || toDate == null) {
      showTopMessage("Please select dates", isError: true);
      return;
    }
    if (nameController.text.isEmpty ||
        designationController.text.isEmpty ||
        reasonController.text.isEmpty ||
        emergencyController.text.isEmpty) {
      showTopMessage("Please fill all fields", isError: true);
      return;
    }
    final missingCompensation = leaveDays.any(
      (d) => d["leavetyp"] == "Compensation" && d["compensationId"] == null,
    );
    if (missingCompensation) {
      showTopMessage(
        "Please select a compensation day for each Compensation entry",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    String leaveType = leaveDays.map((e) => e["type"]).join(",");

    String leavetyp = leaveDays.map((e) => e["leavetyp"]).join(",");

    final compensationDays = leaveDays
        .where((d) => d["leavetyp"] == "Compensation")
        .toList();

    final int? compensationExtraWorkId = compensationDays.isNotEmpty
        ? compensationDays.first["compensationId"] as int?
        : null;

    final token = await AuthService.getToken();
    final senderId = JwtHelper.getuid(token!);
    final success = await AdminService.applyLeave(
      senderId: int.parse(senderId.toString()),
      name: nameController.text,
      designation: designationController.text,
      reason: reasonController.text,
      fromDate: fromDate!,
      toDate: toDate!,
      leaveType: leaveType,
      totalDays: totalLeave,
      contactNumber: emergencyController.text,
      leavetyp: leavetyp,
      compensationExtraWorkId: compensationExtraWorkId,
    );
    setState(() => _isLoading = false);
    if (success) {
      showTopMessage("Leave Applied Successfully", isError: false);

      Navigator.pop(context, true);
    } else {
      showTopMessage("Failed to apply leave", isError: true);
    }
  }

  Future pickFromTime() async {
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
      setState(() {
        fromTime = picked;
      });
      calculateHours(); // ✅ IMPORTANT
    }
  }

  Future pickToTime() async {
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
      setState(() {
        toTime = picked;
      });
      calculateHours(); // ✅ IMPORTANT
    }
  }

  void calculateHours() {
    if (fromTime == null || toTime == null) return;

    final from = DateTime(0, 0, 0, fromTime!.hour, fromTime!.minute);
    final to = DateTime(0, 0, 0, toTime!.hour, toTime!.minute);

    final diff = to.difference(from).inMinutes;

    if (diff < 0) {
      totalMinutes = 0;
      showTopMessage("Invalid time range", isError: true);
      return;
    }

    totalMinutes = diff;

    setState(() {});
  }

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return "${hours}h ${mins}m";
    } else if (hours > 0) {
      return "${hours}h";
    } else {
      return "${mins}m";
    }
  }

  Future<void> submitPermission() async {
    if (fromTime == null || toTime == null || fromDate == null) {
      showTopMessage("Please fill all fields", isError: true);
      return;
    }

    if (nameController.text.isEmpty ||
        designationController.text.isEmpty ||
        reasonController.text.isEmpty) {
      showTopMessage("Please fill all fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AdminService.applyPermission(
      name: nameController.text,
      designation: designationController.text,
      reason: reasonController.text,
      date: fromDate!,
      fromTime: formatTimeToApi(fromTime!),
      toTime: formatTimeToApi(toTime!),
    );

    setState(() => _isLoading = false);

    if (result != null) {
      final applicationType = result["applicationType"]?.toString();

      if (applicationType == "Leave") {
        showTopMessage(
          "60 minute permission limit exceeded. Leave request created.",
          isError: false,
        );
      } else {
        final remainingMinutes = result["remainingMinutes"] ?? 0;

        showTopMessage(
          "Permission applied successfully. "
          "$remainingMinutes minutes remaining.",
          isError: false,
        );
      }

      Navigator.pop(context, true);
    } else {
      showTopMessage("Failed to apply permission", isError: true);
    }
  }

  String formatTimeToApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00"; // HH:mm:ss
  }

  @override
  Widget build(BuildContext context) {
    final web = WebPushedChrome.isWeb(context);
    if (web) return _webApplyPage();
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: web ? null : const Text("Leave Application"),
      ),
      body: WebPushedChrome.body(
        context,
        title: 'Leave & Permission',
        subtitle: applicationType == "Leave"
            ? 'Apply for leave'
            : 'Apply for a short permission',
        panel: false,
        child: WebFormFrame(
          child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(web ? 24 : 15, web ? 20 : 0, web ? 24 : 15, 24),
            children: [
              if (web)
                WebChoiceBar(
                  options: const ["Leave", "Permission"],
                  selected: applicationType,
                  onSelected: (value) => setState(() => applicationType = value),
                )
              else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Application Type",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  DropdownButton<String>(
                    value: applicationType,
                    items: [
                      DropdownMenuItem(
                        value: "Leave",
                        child: Text(
                          "Leave",
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Permission",
                        child: Text(
                          "Permission",
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        applicationType = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (applicationType == "Leave") ...[
                sectionTitle("Employee Details"),
                const SizedBox(height: 20),
                if (web)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: inputField("Name", nameController)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: inputField("Designation", designationController),
                      ),
                    ],
                  )
                else ...[
                inputField("Name", nameController),
                const SizedBox(height: 5),
                inputField("Designation", designationController),
                ],
                const SizedBox(height: 5),
                inputField("Leave Reason", reasonController),
                const SizedBox(height: 15),
                sectionTitle("Leave Period"),
                const SizedBox(height: 20),
                if (web)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: dateTile("Select From Date", fromDate, pickFromDate),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: dateTile("Select To Date", toDate, pickToDate),
                      ),
                    ],
                  )
                else ...[
                dateTile("Select From Date", fromDate, pickFromDate),
                const SizedBox(height: 5),
                dateTile("Select To Date", toDate, pickToDate),
                ],
                const SizedBox(height: 20),
                if (leaveDays.isNotEmpty) ...[
                  sectionTitle("Leave Type Per Day"),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: leaveDays.map((day) {
                        int index = leaveDays.indexOf(day);
                        bool isLast = index == leaveDays.length - 1;

                        // Build the leave-category options for this day.
                        // "Compensation" only shows once the staff has an
                        // approved compensation entry.
                        final categoryItems = leaveCategories
                            .where(
                              (c) =>
                                  c != "Compensation" ||
                                  hasApprovedCompensation,
                            )
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                            )
                            .toList();

                        // Guard against a stale "Compensation" selection if
                        // eligibility changes after the row was set.
                        final currentCategory =
                            categoryItems.any((i) => i.value == day["leavetyp"])
                            ? day["leavetyp"]
                            : "CL";

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TimeUtils.formatDate(day["date"]),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  // Row 1: Full Day / First Half / Second Half / Holiday
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: day["type"],
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: "Day Type",
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      dropdownColor: Theme.of(
                                        context,
                                      ).colorScheme.background,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                      items: const [
                                        DropdownMenuItem(
                                          value: "Full Day",
                                          child: Text("Full Day"),
                                        ),
                                        DropdownMenuItem(
                                          value: "First Half",
                                          child: Text("First Half"),
                                        ),
                                        DropdownMenuItem(
                                          value: "Second Half",
                                          child: Text("Second Half"),
                                        ),
                                        DropdownMenuItem(
                                          value: "Holiday",
                                          child: Text("Holiday"),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          leaveDays[index]["type"] = value;
                                          calculateTotal();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Row 2: CL / LOP / Compensation
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: currentCategory,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: "Leave Type",
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      dropdownColor: Theme.of(
                                        context,
                                      ).colorScheme.background,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                      items: categoryItems,
                                      onChanged: (value) {
                                        setState(() {
                                          leaveDays[index]["leavetyp"] = value;
                                          if (value != "Compensation") {
                                            leaveDays[index]["compensationId"] =
                                                null;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (day["leavetyp"] == "Compensation" &&
                                  !hasApprovedCompensation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "No approved compensation off available",
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              if (day["leavetyp"] == "Compensation" &&
                                  hasApprovedCompensation) ...[
                                const SizedBox(height: 10),
                                Builder(
                                  builder: (context) {
                                    // Ids already chosen on OTHER days in this
                                    // same application shouldn't be pickable again.
                                    final pickedElsewhere = leaveDays
                                        .asMap()
                                        .entries
                                        .where((e) => e.key != index)
                                        .map((e) => e.value["compensationId"])
                                        .where((id) => id != null)
                                        .toSet();

                                    final options = availableCompensation
                                        .where(
                                          (c) => !pickedElsewhere.contains(
                                            c["id"],
                                          ),
                                        )
                                        .toList();

                                    final currentValue =
                                        options.any(
                                          (c) =>
                                              c["id"] == day["compensationId"],
                                        )
                                        ? day["compensationId"]
                                        : null;

                                    return DropdownButtonFormField<int>(
                                      value: currentValue,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: "Select Compensation Day",
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      dropdownColor: Theme.of(
                                        context,
                                      ).colorScheme.background,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                      hint: const Text("Choose a date"),
                                      items: options
                                          .map(
                                            (c) => DropdownMenuItem<int>(
                                              value: c["id"] as int,
                                              child: Text(
                                                TimeUtils.formatDate(c["date"]),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          leaveDays[index]["compensationId"] =
                                              value;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Card(
                  color: Theme.of(context).colorScheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: const Text(
                      "Total Leave",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      "$totalLeave Days",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                sectionTitle("Emergency Contact"),
                const SizedBox(height: 20),

                TextField(
                  controller: emergencyController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
              if (applicationType == "Permission") ...[
                sectionTitle("Permission Details"),
                const SizedBox(height: 20),

                if (web)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: inputField("Name", nameController)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: inputField("Designation", designationController),
                      ),
                    ],
                  )
                else ...[
                inputField("Name", nameController),
                inputField("Designation", designationController),
                ],
                inputField("Reason", reasonController),

                const SizedBox(height: 10),

                dateTile("Select Date", fromDate, pickFromDate),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // FROM
                      Expanded(
                        child: GestureDetector(
                          onTap: pickFromTime,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "FROM",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fromTime == null
                                    ? "--:--"
                                    : fromTime!.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Divider
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),

                      // TO
                      Expanded(
                        child: GestureDetector(
                          onTap: pickToTime,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "TO",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                toTime == null
                                    ? "--:--"
                                    : toTime!.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Divider
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),

                      // TOTAL
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "TOTAL",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalMinutes > 0
                                  ? formatDuration(totalMinutes)
                                  : "--",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: AppButton(
                  text: "Submit",
                  isLoading: _isLoading,
                  onPressed: applicationType == "Leave"
                      ? submitLeave
                      : submitPermission,
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

  Widget _webApplyPage() {
    final leave = applicationType == 'Leave';
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
                      leave ? 'Apply leave' : 'Apply permission',
                      style: TextStyle(
                        color: WebTheme.brandOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _webModeSwitch(),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          decoration: BoxDecoration(
                            color: WebTheme.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WebTheme.lineOf(context)),
                          ),
                          child: leave ? _webLeaveForm() : _webPermissionForm(),
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

  Widget _webModeSwitch() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: WebTheme.brandSoftOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _webMode('Leave', applicationType == 'Leave', () {
            setState(() => applicationType = 'Leave');
          }),
          _webMode('Permission', applicationType == 'Permission', () {
            setState(() => applicationType = 'Permission');
          }),
        ],
      ),
    );
  }

  Widget _webMode(String title, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? WebTheme.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : WebTheme.inkOf(context),
          ),
        ),
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

  Widget _webBox(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WebTheme.mutedOf(context),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _webDecoration(String hint, {IconData? icon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: WebTheme.mutedOf(context)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      suffixIcon: icon == null ? null : Icon(icon, size: 18, color: WebTheme.brandOf(context)),
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: WebTheme.brandOf(context))),
    );
  }

  Widget _webText(
    TextEditingController controller,
    String hint, {
    int lines = 1,
    TextInputType? keyboard,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboard,
      maxLength: maxLength,
      style: TextStyle(fontSize: 14, color: WebTheme.inkOf(context)),
      decoration: _webDecoration(hint).copyWith(counterText: ''),
    );
  }

  Widget _webDate(String label, DateTime? date, VoidCallback onTap) {
    return _webBox(
      label,
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: _webDecoration(label, icon: Icons.calendar_today),
          child: Text(
            date == null ? label : TimeUtils.formatDate(date),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: date == null ? WebTheme.mutedOf(context) : WebTheme.brandOf(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webTime(String label, TimeOfDay? time, VoidCallback onTap) {
    return _webBox(
      label,
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: _webDecoration(label, icon: Icons.access_time),
          child: Text(
            time == null ? 'Select time' : time.format(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: time == null ? WebTheme.mutedOf(context) : WebTheme.brandOf(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webDrop({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          iconEnabledColor: WebTheme.brandOf(context),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WebTheme.brandOf(context)),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _webLeaveForm() {
    return Column(
      children: [
        _webPair(
          _webBox('Name', _webText(nameController, 'Name')),
          _webBox('Designation', _webText(designationController, 'Designation')),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _webBox('Reason', _webText(reasonController, 'Reason', lines: 2)),
        ),
        _webPair(
          _webDate('From date', fromDate, pickFromDate),
          _webDate('To date', toDate, pickToDate),
        ),
        if (leaveDays.isNotEmpty) ...[
          for (var index = 0; index < leaveDays.length; index++) _webLeaveDay(index),
          const SizedBox(height: 4),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Text(
                'Total leave',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.mutedOf(context),
                ),
              ),
              const Spacer(),
              Text(
                '$totalLeave days',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: WebTheme.brandOf(context),
                ),
              ),
            ],
          ),
        ),
        _webBox(
          'Contact',
          _webText(
            emergencyController,
            'Phone number',
            keyboard: TextInputType.phone,
            maxLength: 10,
          ),
        ),
        const SizedBox(height: 16),
        Center(child: _webSubmit()),
      ],
    );
  }

  Widget _webLeaveDay(int index) {
    final day = leaveDays[index];
    final categories = leaveCategories
        .where((item) => item != 'Compensation' || hasApprovedCompensation)
        .toList();
    final category = categories.contains(day['leavetyp']) ? day['leavetyp'] as String? : 'CL';
    final pickedElsewhere = leaveDays
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value['compensationId'])
        .where((id) => id != null)
        .toSet();
    final options = availableCompensation
        .where((item) => !pickedElsewhere.contains(item['id']))
        .toList();
    final currentValue = options.any((item) => item['id'] == day['compensationId'])
        ? day['compensationId'] as int?
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TimeUtils.formatDate(day['date']),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: WebTheme.brandOf(context)),
          ),
          const SizedBox(height: 6),
          _webPair(
            _webBox(
              'Day type',
              _webDrop(
                value: day['type'] as String?,
                items: const ['Full Day', 'First Half', 'Second Half', 'Holiday'],
                onChanged: (value) {
                  setState(() {
                    leaveDays[index]['type'] = value;
                    calculateTotal();
                  });
                },
              ),
            ),
            _webBox(
              'Leave type',
              _webDrop(
                value: category,
                items: categories,
                onChanged: (value) {
                  setState(() {
                    leaveDays[index]['leavetyp'] = value;
                    if (value != 'Compensation') {
                      leaveDays[index]['compensationId'] = null;
                    }
                  });
                },
              ),
            ),
          ),
          if (day['leavetyp'] == 'Compensation' && hasApprovedCompensation)
            _webBox(
              'Compensation day',
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: currentValue,
                    isExpanded: true,
                    hint: Text(
                      'Choose a date',
                      style: TextStyle(fontSize: 14, color: WebTheme.mutedOf(context)),
                    ),
                    dropdownColor: Colors.white,
                    iconEnabledColor: WebTheme.brandOf(context),
                    items: [
                      for (final item in options)
                        DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text(TimeUtils.formatDate(item['date'])),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => leaveDays[index]['compensationId'] = value);
                    },
                  ),
                ),
              ),
            ),
          if (day['leavetyp'] == 'Compensation' && !hasApprovedCompensation)
            Text(
              'No approved compensation off available',
              style: TextStyle(color: WebTheme.danger, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _webPermissionForm() {
    return Column(
      children: [
        _webPair(
          _webBox('Name', _webText(nameController, 'Name')),
          _webBox('Designation', _webText(designationController, 'Designation')),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _webBox('Reason', _webText(reasonController, 'Reason', lines: 2)),
        ),
        _webPair(
          _webDate('Apply date', fromDate, pickFromDate),
          _webTime('From time', fromTime, pickFromTime),
        ),
        _webPair(
          _webTime('To time', toTime, pickToTime),
          _webBox(
            'Total hours',
            Container(
              height: 46,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WebTheme.brandOf(context).withValues(alpha: 0.4)),
              ),
              child: Text(
                totalMinutes > 0 ? formatDuration(totalMinutes) : '—',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: WebTheme.brandOf(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: _webSubmit()),
      ],
    );
  }

  Widget _webSubmit() {
    final leave = applicationType == 'Leave';
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: WebTheme.brand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      onPressed: _isLoading
          ? null
          : () {
              if (leave) {
                submitLeave();
              } else {
                submitPermission();
              }
            },
      child: Text(_isLoading ? 'Saving' : 'Submit'),
    );
  }

  Widget sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.displaySmall);
  }

  Widget inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: WebPushedChrome.isWeb(context),
          fillColor: WebTheme.canvasOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: WebTheme.lineOf(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: WebTheme.lineOf(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: WebTheme.brandOf(context), width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget dateTile(String label, DateTime? date, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(
          date == null ? label : TimeUtils.formatDate(date),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget timeTile(String label, TimeOfDay? time, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(time == null ? label : time.format(context)),
        onTap: onTap,
      ),
    );
  }
}
