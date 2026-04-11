import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

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
      leaveDays.add({"date": current, "type": "Full Day"});
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
    setState(() => _isLoading = true);
    String leaveType = leaveDays.map((e) => e["type"]).join(",");
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
    );
    setState(() => _isLoading = false);
    if (success) {
      showTopMessage("Leave Applied Successfully", isError: false);
    } else {
      showTopMessage("Failed to apply leave", isError: true);
    }
  }

  Future pickFromTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    );

    if (picked != null) {
      setState(() {
        toTime = picked;
      });
      calculateHours(); // ✅ IMPORTANT
    }
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

    final success = await AdminService.applyPermission(
      name: nameController.text,
      designation: designationController.text,
      reason: reasonController.text,
      date: fromDate!, // single date
      fromTime: formatTimeToApi(fromTime!),
      toTime: formatTimeToApi(toTime!),
    );

    setState(() => _isLoading = false);

    if (success) {
      showTopMessage("Permission Applied Successfully", isError: false);

      // ✅ optional reset
      setState(() {
        fromTime = null;
        toTime = null;
        totalMinutes = 0;
      });
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Leave Application"),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(left: 15, right: 15),
            children: [
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
              const SizedBox(height: 20),
              if (applicationType == "Leave") ...[
                sectionTitle("Employee Details"),
                const SizedBox(height: 20),
                inputField("Name", nameController),
                const SizedBox(height: 5),
                inputField("Designation", designationController),
                const SizedBox(height: 5),
                inputField("Leave Reason", reasonController),
                const SizedBox(height: 20),
                sectionTitle("Leave Period"),
                const SizedBox(height: 20),
                dateTile("Select From Date", fromDate, pickFromDate),
                const SizedBox(height: 10),
                dateTile("Select To Date", toDate, pickToDate),
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
                        return ListTile(
                          title: Text(
                            DateFormat("dd MMM yyyy").format(day["date"]),
                          ),
                          trailing: DropdownButton<String>(
                            value: day["type"],
                            dropdownColor: Colors.white,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                            iconEnabledColor: Colors.black,
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
                inputField("Phone Number", emergencyController),
              ],
              if (applicationType == "Permission") ...[
                sectionTitle("Permission Details"),
                const SizedBox(height: 20),

                inputField("Name", nameController),
                inputField("Designation", designationController),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
          date == null ? label : DateFormat("dd MMM yyyy").format(date),
        ),
        onTap: onTap,
      ),
    );
  }
}
