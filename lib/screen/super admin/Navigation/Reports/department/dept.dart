import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/downpdf.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class DepartmentReportsTab extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String department;

  const DepartmentReportsTab({
    super.key,
    required this.department,
    this.fromDate,
    this.toDate,
  });

  @override
  State<DepartmentReportsTab> createState() => _DepartmentReportsTabState();
}

class _DepartmentReportsTabState extends State<DepartmentReportsTab> {
  late Future<Map<String, dynamic>> reportFuture;
  Map<String, dynamic>? data;
  bool isLoading = true;
  DateTime selectedYear = DateTime.now();
  @override
  void initState() {
    super.initState();
    _fetchReport();
    loadData();
  }

  void _fetchReport() {
    final fromDate = DateTime(selectedYear.year, 1, 1);
    final toDate = DateTime(selectedYear.year, 12, 31, 23, 59, 59);

    setState(() {
      reportFuture = ReportsService.fetchDepartmentReport(
        widget.department,
        fromDate: fromDate,
        toDate: toDate,
      );
    });
  }

  Future<void> loadData() async {
    try {
      final res = await ReportsService.getdeptMonthlyProductivity(
        widget.department,
        selectedYear.year,
      );

      setState(() {
        data = res;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> generateAndDownloadPDF() async {
    Map<String, dynamic> summaryReportData = {};
    Map<String, dynamic> tableReportData = {};

    try {
      summaryReportData = await ReportsService.fetchDepartmentReport(
        widget.department,
      );
      tableReportData = await ReportsService.getFullReport(
        department: widget.department,
      );
    } catch (e) {
      print("Error fetching department reports: $e");
    }

    final pdfGenerator = EmployeeReportPdfGenerator(
      department: widget.department,
      reportYear: selectedYear.year,
      summaryData: summaryReportData,
      monthlyData: data?["monthlyData"] ?? [],
      warnings: [],
      completionPercentage: (summaryReportData["goalCompletionPercentage"] ?? 0)
          .toDouble(),
      onTimePercentage: (summaryReportData["onTimeGoalCompletionPercentage"] ?? 0)
          .toDouble(),
      delayedGoalPercent: (summaryReportData["delayedGoalPercentage"] ?? 0).toDouble(),
      reportData: tableReportData,
      topPerformer: summaryReportData["topPerformer"],
      lowPerformer: summaryReportData["lowPerformer"],
    );

    await pdfGenerator.generateAndDownloadPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.department),
        actions: [
          IconButton(
            onPressed: generateAndDownloadPDF,
            icon: Icon(Icons.download),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportsTable(department: widget.department),
                ),
              );
            },
            icon: Icon(Icons.bar_chart_rounded),
          ),
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedYear,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );

              if (picked != null) {
                setState(() {
                  selectedYear = picked;
                  isLoading = true;
                });

                _fetchReport();
                await loadData();
              }
            },
            icon: Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final monthlyData = (this.data?["monthlyData"] as List? ?? []);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Goal & Task Summary",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Total Employees",
                        value: (data["totalUsers"] ?? 0).toString(),
                        icon: Icons.task_outlined,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Total Goal",
                        value: (data["totalGoals"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Total Task",
                        value: (data["totalTasks"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Completed Goal",
                        value: (data["completedGoals"] ?? 0).toString(),
                        icon: Icons.task_outlined,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending Goal",
                        value: (data["pendingGoals"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue Goal",
                        value: (data["overdueGoals"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Completed Tasks",
                        value: (data["completedTasks"] ?? 0).toString(),
                        icon: Icons.task_outlined,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending Tasks",
                        value: (data["pendingTasks"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: const Color.fromARGB(255, 235, 211, 0),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue Tasks",
                        value: (data["overdueTasks"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Performance Overview",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    KpiCircleCard(
                      title: "Completion %",
                      value: (data["goalCompletionPercentage"] ?? 0).toDouble(),
                      icon: Icons.verified_outlined,
                      isPercentage: true,
                    ),

                    KpiCircleCard(
                      title: "On-Time Completion%",
                      value: (data["onTimeGoalCompletionPercentage"] ?? 0)
                          .toDouble(),
                      icon: Icons.verified_outlined,
                      isPercentage: true,
                    ),
                    KpiCircleCard(
                      title: "Delayed %",
                      value: (data["delayedGoalPercentage"] ?? 0).toDouble(),
                      icon: Icons.timer,
                      isPercentage: true,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ProductivityBarChart(
                  data: monthlyData
                      .map(
                        (e) => {
                          "month": e["month"],
                          "productivity": e["productivity"],
                          "taskPoints": e["taskPoints"],
                          "goalPoints": e["goalPoints"],
                          "fiveSPoints": e["fiveSPoints"],
                          "warrantyPoints": e["warrantyPoints"],
                        },
                      )
                      .toList(),
                ),
                _buildPerformanceSection(data),
                const SizedBox(height: 25),
                Text(
                  "Staffs List",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                EmployeeList(department: widget.department, searchQuery: ''),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceSection(Map<String, dynamic> data) {
    final top = data["topPerformer"];
    final low = data["lowPerformer"];

    final showTop = top != null && (top["completedTasks"] ?? 0) > 0;
    // final showLow = low != null && (low["completedTasks"] ?? 0) > 0;
    final showLow = low != null;

    if (!showTop && !showLow) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          "Performance Metrics",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),

        if (showTop)
          _advancedPerformerCard(
            title: "Top Performer",
            name: top!["user"] ?? "-",
            completedCount: top["completedTasks"] ?? 0,
            totalTasks: top["totalTasks"] ?? 0, // we will fix below
            startColor: Theme.of(context).colorScheme.primary,
            endColor: Theme.of(context).colorScheme.secondary,
            icon: Icons.emoji_events,
          ),

        if (showTop) const SizedBox(height: 5),

        if (showLow)
          _advancedPerformerCard(
            title: "Low Performer",
            name: low!["user"] ?? "-",
            completedCount: low["completedTasks"] ?? 0,
            totalTasks: low["totalTasks"] ?? 0,
            startColor: Colors.redAccent,
            endColor: Colors.red,
            icon: Icons.thumb_down,
          ),
      ],
    );
  }

  Widget _advancedPerformerCard({
    required String title,
    required String name,
    required int completedCount,
    required int totalTasks,
    required Color startColor,
    required Color endColor,
    required IconData icon,
  }) {
    final double progress = totalTasks > 0 ? (completedCount / totalTasks) : 0;
    final int percentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [startColor.withOpacity(0.2), endColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [startColor, endColor]),
                  ),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: endColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            Text(name, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 5),

            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade300,
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 8,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [startColor, endColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: endColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$completedCount / $totalTasks tasks completed",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: endColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$percentage%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: endColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
