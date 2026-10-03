import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/core/widgets/worklog_session_tile.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/addworklog.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/checkout_worklog.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/offline_worklogs.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

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
      final inRaw = log["time"];
      final outRaw = log["outTime"];
      if (inRaw == null || outRaw == null || outRaw.toString().isEmpty) {
        continue;
      }
      try {
        final start = TimeUtils.fromUtcIso8601(inRaw.toString());
        final end = TimeUtils.fromUtcIso8601(outRaw.toString());
        final minutes = end.difference(start).inMinutes;
        if (minutes > 0) total += minutes / 60.0;
      } catch (_) {}
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
      backgroundColor: Theme.of(context).colorScheme.primary,
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
                  Text(
                    "Select Date",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Year",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      DropdownButton<int>(
                        style: Theme.of(context).textTheme.labelLarge,
                        value: tempYear,

                        items: List.generate(27, (i) {
                          int year = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          );
                        }),
                        onChanged: (v) => setModalState(() => tempYear = v!),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Month",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      DropdownButton<int>(
                        style: Theme.of(context).textTheme.labelLarge,
                        value: tempMonth,
                        items: List.generate(12, (i) {
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(0, i + 1)),
                              style: Theme.of(context).textTheme.labelMedium,
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
                              border: Border.all(
                                width: 1.5,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.background
                                  : Theme.of(context).colorScheme.onPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.secondary,
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
                      color: Theme.of(context).colorScheme.secondary,
                      txtcolor: Theme.of(context).colorScheme.onPrimary,
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

  Future<void> _checkOut(Map<String, dynamic> log) async {
    final rawId = log["id"];
    if (rawId == null) return;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutWorklogPage(
          workLogId: id,
          title: (log["title"] ?? "").toString(),
        ),
      ),
    );

    if (result == 'local') {
      showTopMessage('Your check out saved locally.', isError: false);
      return;
    }

    if (result == true) {
      await _loadLogs();
    }
  }

  Future<void> _addWorklog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWorklogPage()),
    );

    if (!mounted || result == null) return;

    if (result == "local") {
      showTopMessage("Your worklog saved locally.", isError: false);
      return;
    }

    if (result == "cloud") {
      showTopMessage(
        "Check in saved. Check out later from this worklog.",
        isError: false,
      );
      await _loadLogs();
    }
  }

  Future<void> _openLocalWorklogs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OfflineWorkLogs()),
    );
    if (mounted) await _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final data = await AnnouncementService.getMyWorkLogs(selectedDate);

      setState(() {
        logs = pairWorkLogs(data, singleUser: true).map((item) {
          return {
            "description": item["description"],
            "title": item["title"],
            "status": item["status"],
            "id": item["id"],
            "imageUrl": item["imageUrl"],
            "outImageUrl": item["outImageUrl"],
            "workType": item["workType"],
            "time": item["time"],
            "outTime": item["outTime"],
            "locationName": item["locationName"],
            "outLocationName": item["outLocationName"],
            "workDate": item["workDate"],
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
        content: Text(
          "Are you sure you want to submit all draft worklogs for this day?",
           style: Theme.of(context).textTheme.labelMedium,
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
    final isWeb = !AppLayout.isMobile(context);
    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              title: const Text("Daily Worklog"),
              actions: [
                IconButton(
                  tooltip: "Local worklogs",
                  onPressed: _openLocalWorklogs,
                  icon: const Icon(Icons.cloud_off_outlined),
                ),
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
        padding: isWeb
            ? AppLayout.pagePadding(context)
            : const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWeb) ...[
                  Row(
                    children: [
                      const WebPageHeader(
                        title: 'Worklog',
                        subtitle: 'Daily hours and timeline',
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Local worklogs',
                        onPressed: _openLocalWorklogs,
                        icon: const Icon(Icons.cloud_off_outlined),
                      ),
                      if (logs.isNotEmpty)
                        TextButton(
                          onPressed: canSubmit ? _submitDrafts : null,
                          child: Text(appBarButtonText),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _weekHeader(),
                SizedBox(height: 10),
                _totalHours(),
                SizedBox(height: 15),
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
                    TimeUtils.formatDate(selectedDate),
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
      return const Center(child: Text('No worklogs yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final hasOut = (log['outImageUrl'] ?? '').toString().isNotEmpty ||
            (log['outTime'] ?? '').toString().isNotEmpty;
        return WorklogSessionTile(
          log: log,
          onCheckOut: hasOut ? null : () => _checkOut(log),
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
