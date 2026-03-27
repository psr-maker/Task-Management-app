import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/addworklog.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/edit_worklog.dart';
import 'package:staff_work_track/services/announ_service.dart';

class Worklog extends StatefulWidget {
  const Worklog({super.key});

  @override
  State<Worklog> createState() => _WorklogState();
}

class _WorklogState extends State<Worklog> {
  bool _isLoading = false;
  bool get hasDrafts {
    return logs.any((log) => log["status"] == "Draft");
  }

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> logs = [];
  @override
  void initState() {
    super.initState();
    _loadLogs();
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

  Duration calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  String formatHoursToHM(double hours) {
    int totalMinutes = (hours * 60).round();

    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;

    return "${h}h ${m}m";
  }

  double totalDuration() {
    double total = 0;
    for (var log in logs) {
      total += log["totalHours"] ?? 0;
    }
    return total;
  }

  void _pickYearMonthDate() {
    int tempYear = selectedDate.year;
    int tempMonth = selectedDate.month;
    int tempDay = selectedDate.day;

    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromARGB(255, 10, 54, 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int maxDays = daysInMonth(tempYear, tempMonth);
            if (tempDay > maxDays) tempDay = maxDays;

            return Padding(
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Date",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Year",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      DropdownButton<int>(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        value: tempYear,

                        items: List.generate(27, (i) {
                          int year = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (v) => setModalState(() => tempYear = v!),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Month",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      DropdownButton<int>(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        value: tempMonth,
                        items: List.generate(12, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(0, i + 1)),
                            ),
                          );
                        }),
                        onChanged: (v) => setModalState(() => tempMonth = v!),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      itemCount: maxDays,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemBuilder: (context, index) {
                        int day = index + 1;
                        bool isSelected = day == tempDay;

                        return GestureDetector(
                          onTap: () => setModalState(() => tempDay = day),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(width: 2, color: Colors.white),
                              color: isSelected
                                  ? Colors.white
                                  : Color.fromARGB(255, 10, 54, 12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: AppButton(
                      text: "Apply",
                      isLoading: _isLoading,
                      onPressed: () async {
                        setState(() {
                          selectedDate = DateTime(tempYear, tempMonth, tempDay);
                        });

                        Navigator.pop(context);

                        await _loadLogs();
                      },

                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addWorklog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWorklogPage()),
    );

    if (result == true) {
      await _loadLogs();
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final data = await AnnouncementService.getMyWorkLogs(selectedDate);

      setState(() {
        logs = data.map((item) {
          final startDateTime = DateTime.parse(item["startTime"]);
          final endDateTime = DateTime.parse(item["endTime"]);

          return {
            "start": TimeOfDay(
              hour: startDateTime.hour,
              minute: startDateTime.minute,
            ),
            "end": TimeOfDay(
              hour: endDateTime.hour,
              minute: endDateTime.minute,
            ),
            "description": item["description"],
            "title": item["title"],
            "status": item["status"],
            "id": item["id"],
            "totalHours": (item["totalHours"] as num).toDouble(),
          };
        }).toList();
      });
    } catch (e) {
      print(e);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitDrafts() async {
    if (!canSubmit) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Submit Drafts",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        content: const Text(
          "Are you sure you want to submit all draft worklogs for this day?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),

          AppButton(
            text: "Submit",
            isLoading: _isLoading,
            onPressed: () => Navigator.pop(context, true),
            color: Theme.of(context).colorScheme.secondary,
            txtcolor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await AnnouncementService.updateWorkLogStatus(
        workDate: selectedDate,
        status: "Submitted",
      );

      if (response["updatedCount"] != null && response["updatedCount"] > 0) {
        showTopMessage("Drafts submitted successfully.", isError: false);
        await _loadLogs();
      }
    } catch (e) {
      print(e);

      showTopMessage("Failed to submit drafts.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String get appBarButtonText {
    if (logs.isEmpty) return "No Worklogs";
    if (logs.any((log) => log["status"] == "Draft")) return "Draft";
    return "Submitted";
  }

  bool get canSubmit => logs.any((log) => log["status"] == "Draft");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Worklog"),
        actions: [
          if (logs.isNotEmpty)
            TextButton(
              onPressed: canSubmit ? _submitDrafts : null,
              child: Text(
                appBarButtonText,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _weekHeader(),
                SizedBox(height: 10),
                _totalHours(),
                SizedBox(height: 10),
                Expanded(child: _timelineLogs()),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: _addWorklog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _weekHeader() {
    DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );

    return Container(
    //  color: Theme.of(context).colorScheme.onPrimary,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(selectedDate),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(height: 5),
                  Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),

              IconButton(
                onPressed: _pickYearMonthDate,
                icon: Icon(Icons.edit_calendar_outlined),
              ),
            ],
          ),

          const SizedBox(height: 5),

          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                DateTime day = startOfWeek.add(Duration(days: index));
                bool isSelected =
                    day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;

                return GestureDetector(
                  onTap: () async {
                    setState(() => selectedDate = day);
                    await _loadLogs();
                  },
                  child: Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineLogs() {
    if (logs.isEmpty) {
      return const Center(child: Text("No worklogs yet."));
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final double hours = log["totalHours"] ?? 0;

        return GestureDetector(
          onLongPress: () async {
            if (log["status"] != "Draft") {
              showTopMessage("Cannot edit a submitted worklog.", isError: true);

              return;
            }

            final int? worklogId = log["id"] as int?;
            if (worklogId == null) return;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditWorklogPage(
                  worklogId: worklogId,
                  title: log["title"] ?? "",
                  description: log["description"] ?? "",
                  startTime: log["start"],
                  endTime: log["end"],
                  workDate: selectedDate,
                ),
              ),
            );

            if (result == true) {
              await _loadLogs();
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                height: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log["start"].format(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      log["end"].format(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: Theme.of(context).colorScheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log["title"] ?? "",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          log["description"] ?? " ",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Duration: ${formatHoursToHM(hours)}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _totalHours() {
    final total = totalDuration();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total Work Time",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            formatHoursToHM(total),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
