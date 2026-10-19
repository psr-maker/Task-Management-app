import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
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
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WebTheme.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int maxDays = daysInMonth(tempYear, tempMonth);
            if (tempDay > maxDays) tempDay = maxDays;
            final ink = WebTheme.inkOf(context);
            final muted = WebTheme.mutedOf(context);
            final field = BoxDecoration(
              color: WebTheme.canvasOf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WebTheme.lineOf(context)),
            );
            Widget picker(String label, Widget control) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: field,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      control,
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WebTheme.lineOf(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select date',
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      picker(
                        'Year',
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            dropdownColor: WebTheme.surfaceOf(context),
                            value: tempYear,
                            style: TextStyle(
                              color: ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            items: List.generate(27, (i) {
                              final year = DateTime.now().year - i;
                              return DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              );
                            }),
                            onChanged: (v) => setModalState(() => tempYear = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      picker(
                        'Month',
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            dropdownColor: WebTheme.surfaceOf(context),
                            value: tempMonth,
                            style: TextStyle(
                              color: ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            items: List.generate(12, (i) {
                              return DropdownMenuItem(
                                value: i + 1,
                                child: Text(monthNames[i]),
                              );
                            }),
                            onChanged: (v) => setModalState(() => tempMonth = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    child: GridView.builder(
                      itemCount: maxDays,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final isSelected = day == tempDay;
                        return GestureDetector(
                          onTap: () => setModalState(() => tempDay = day),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? WebTheme.brand
                                  : WebTheme.canvasOf(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? WebTheme.brand
                                    : WebTheme.lineOf(context),
                              ),
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: isSelected ? Colors.white : ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Apply',
                      isLoading: _isLoading,
                      onPressed: () async {
                        setState(() {
                          selectedDate = DateTime(tempYear, tempMonth, tempDay);
                        });
                        Navigator.pop(context);
                        await _loadLogs();
                      },
                      color: WebTheme.brand,
                      txtcolor: Colors.white,
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
    if (!AppLayout.isMobile(context)) return _webPage();
    return Scaffold(
      appBar: AppBar(
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
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

  Widget _webPage() {
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: Padding(
        padding: AppLayout.pagePadding(context),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _webToolbar(),
                const SizedBox(height: 8),
                _webWeek(),
                const SizedBox(height: 8),
                _webSummary(),
                const SizedBox(height: 8),
                Expanded(child: _webTimeline()),
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
    );
  }

  Widget _webToolbar() {
    return Row(
      children: [
        Text(
          'Worklog',
          style: TextStyle(
            color: WebTheme.brandOf(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${DateFormat('EEE').format(selectedDate)}, ${TimeUtils.formatDate(selectedDate)}',
          style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Local worklogs',
          visualDensity: VisualDensity.compact,
          onPressed: _openLocalWorklogs,
          icon: Icon(Icons.cloud_off_outlined, size: 18, color: WebTheme.brandOf(context)),
        ),
        if (logs.isNotEmpty)
          TextButton(
            onPressed: canSubmit ? _submitDrafts : null,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: WebTheme.brandOf(context),
            ),
            child: Text(appBarButtonText),
          ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: _addWorklog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: WebTheme.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _webWeek() {
    final start = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    return Row(
      children: [
        for (var index = 0; index < 7; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(child: _webDay(start.add(Duration(days: index)))),
        ],
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Choose date',
          onPressed: _pickYearMonthDate,
          icon: Icon(Icons.edit_calendar_outlined, color: WebTheme.brandOf(context)),
        ),
      ],
    );
  }

  Widget _webDay(DateTime day) {
    final selected = day.year == selectedDate.year &&
        day.month == selectedDate.month &&
        day.day == selectedDate.day;
    return Material(
      color: selected ? WebTheme.brand : WebTheme.surfaceOf(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          setState(() => selectedDate = day);
          await _loadLogs();
        },
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? WebTheme.brand : WebTheme.lineOf(context),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E').format(day),
                style: TextStyle(
                  color: selected ? Colors.white70 : WebTheme.mutedOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: selected ? Colors.white : WebTheme.inkOf(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webSummary() {
    final drafts = logs.where((log) => log['status'] == 'Draft').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WebTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WebTheme.lineOf(context)),
      ),
      child: Row(
        children: [
          _webStat(formatHoursToHM(totalDuration()), 'Work time'),
          _webDivider(),
          _webStat('${logs.length}', 'Sessions'),
          _webDivider(),
          _webStat('$drafts', 'Drafts'),
        ],
      ),
    );
  }

  Widget _webDivider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: WebTheme.lineOf(context),
    );
  }

  Widget _webStat(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: WebTheme.brandOf(context),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _webTimeline() {
    if (_isLoading) return const Center(child: RotatingFlower());
    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No worklogs for this day.',
          style: TextStyle(color: WebTheme.mutedOf(context), fontSize: 14),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 2 : 1;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: (logs.length / columns).ceil(),
          itemBuilder: (context, row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 12),
                    Expanded(child: _webSession(row * columns + column)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _webSession(int index) {
    if (index >= logs.length) return const SizedBox.shrink();
    final log = logs[index];
    final hasOut = (log['outImageUrl'] ?? '').toString().isNotEmpty ||
        (log['outTime'] ?? '').toString().isNotEmpty;
    return WorklogSessionTile(
      log: log,
      compact: true,
      onCheckOut: hasOut ? null : () => _checkOut(log),
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
