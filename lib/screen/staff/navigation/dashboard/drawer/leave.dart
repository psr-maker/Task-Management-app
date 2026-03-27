import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';

class StaffLeave extends StatefulWidget {
  const StaffLeave({super.key});

  @override
  State<StaffLeave> createState() => _StaffLeaveState();
}

class _StaffLeaveState extends State<StaffLeave> {
  final nameController = TextEditingController();
  final designationController = TextEditingController();
  final reasonController = TextEditingController();
  final emergencyController = TextEditingController();

  final bool _isLoading = false;

  DateTime? fromDate;
  DateTime? toDate;

  List<Map<String, dynamic>> leaveDays = [];
  double totalLeave = 0;

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
      } else {
        totalLeave += 0.5;
      }
    }

    setState(() {});
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
      body: ListView(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
        children: [
          /// Employee Info
          sectionTitle("Employee Details"),
          const SizedBox(height: 20),
          inputField("Name", nameController),
          const SizedBox(height: 5),
          inputField("Designation", designationController),
          const SizedBox(height: 5),
          inputField("Leave Reason", reasonController),
          const SizedBox(height: 20),

          /// Dates
          sectionTitle("Leave Period"),
          const SizedBox(height: 20),
          dateTile("Select From Date", fromDate, pickFromDate),
          const SizedBox(height: 10),
          dateTile("Select To Date", toDate, pickToDate),
          const SizedBox(height: 20),

          /// Leave Day Type
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
                    title: Text(DateFormat("dd MMM yyyy").format(day["date"])),
                    trailing: DropdownButton<String>(
                      value: day["type"],
                      dropdownColor: Colors.white,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

          /// Total
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

          /// Emergency
          sectionTitle("Emergency Contact"),
          const SizedBox(height: 20),
          inputField("Phone Number", emergencyController),

          const SizedBox(height: 20),
          Center(
            child: AppButton(
              text: "Submit",
              isLoading: _isLoading,
              onPressed: () {},
              color: Theme.of(context).colorScheme.secondary,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
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
