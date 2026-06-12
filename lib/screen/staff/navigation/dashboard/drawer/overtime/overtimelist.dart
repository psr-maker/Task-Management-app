import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/overtime/overtime_entry.dart';
import 'package:staff_work_track/services/admin_service.dart';

class OvertimeList extends StatefulWidget {
  const OvertimeList({super.key});

  @override
  State<OvertimeList> createState() => _OvertimeListState();
}

class _OvertimeListState extends State<OvertimeList> {
  Map<String, List<dynamic>> groupedData = {};
  bool loading = true;

  List<dynamic> allData = [];
  List<dynamic> filteredData = [];
  DateTime? fromDate;
  DateTime? toDate;
  double regularHoursPerDay = 8.5;
  String statusFilter = "All";
  double get totalOvertimeHours {
    return filteredData.fold<double>(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item["totalHours"].toString()) ?? 0.0),
    );
  }

  int get totalDays => filteredData.length;

  double get totalRegularHours => totalDays * regularHoursPerDay;

  double get totalTime => totalRegularHours + totalOvertimeHours;
  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "";

    final parsed = DateFormat("HH:mm:ss").parse(time);

    return DateFormat("h:mm a").format(parsed);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await AdminService.getMyOverTimes();

      print("Overtime Count: ${data.length}");
      print(data);

      setState(() {
        allData = data;
        filteredData = data;
        loading = false;
      });
    } catch (e) {
      print(e);
      setState(() => loading = false);
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
    );

    if (picked == null) return;

    setState(() {
      fromDate = picked.start;
      toDate = picked.end;
    });

    applyStatusFilter(statusFilter);
  }

  void applyStatusFilter(String filter) {
    setState(() {
      statusFilter = filter;

      List<dynamic> tempList = [...allData];

      // Apply date range first
      if (fromDate != null && toDate != null) {
        tempList = tempList.where((item) {
          final itemDate = DateTime.parse(item["date"]);

          return !itemDate.isBefore(fromDate!) && !itemDate.isAfter(toDate!);
        }).toList();
      }

      // Apply status filter
      if (filter == "Approved") {
        tempList = tempList.where((item) => item["isApprov"] == true).toList();
      } else if (filter == "Pending") {
        tempList = tempList.where((item) => item["isApprov"] == false).toList();
      }

      filteredData = tempList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Overtime History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: pickDateRange,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: applyStatusFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All")),
              const PopupMenuItem(value: "Approved", child: Text("Approved")),
              const PopupMenuItem(
                value: "Pending",
                child: Text("Not Approved"),
              ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyOvertime()),
              );

              if (result == true) {
                loadData();
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: RotatingFlower())
          : Builder(
              builder: (context) {
                final Map<String, List<dynamic>> groupedData = {};

                for (var item in filteredData) {
                  final date = DateTime.parse(item["date"]);

                  final monthKey = DateFormat('MMMM yyyy').format(date);

                  groupedData.putIfAbsent(monthKey, () => []);

                  groupedData[monthKey]!.add(item);
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              "Regular Time",
                              "${totalRegularHours.toStringAsFixed(1)} hrs",
                              Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              "Overtime",
                              "${totalOvertimeHours.toStringAsFixed(1)} hrs",
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              "Total Time",
                              "${totalTime.toStringAsFixed(1)} hrs",
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: filteredData.isEmpty
                          ? const Center(child: Text("No records found"))
                          : ListView(
                              children: groupedData.entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        20,
                                        16,
                                        10,
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineLarge,
                                      ),
                                    ),

                                    ...entry.value.map(
                                      (item) => _buildTimelineCard(item),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(dynamic item) {
    final approved = item["isApprov"] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Timeline
            Column(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  color: approved ? Colors.green : Colors.orange,
                ),

                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: approved ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),

                Container(
                  width: 3,
                  height: 120,
                  color: approved ? Colors.green : Colors.orange,
                ),
              ],
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: approved ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            approved ? "Approved Time Log" : "Not Yet Approved",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: approved ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item["name"] ?? "",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        "OverTime",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(DateTime.parse(item["date"])),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 8),
                          Text(
                            "${formatTime(item["fromTime"])} - ${formatTime(item["toTime"])}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.timelapse),
                          const SizedBox(width: 8),
                          Text(
                            "${item["totalHours"]} hrs",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reason:",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item["reason"] ?? "",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
