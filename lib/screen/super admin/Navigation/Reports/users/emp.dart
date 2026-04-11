import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/downpdf.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/kpicard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';

class EmployeeReportPage extends StatefulWidget {
  final int userid;
  final String username;
  final String role;
  const EmployeeReportPage({
    super.key,
    required this.userid,
    required this.username,
    required this.role,
  });

  @override
  State<EmployeeReportPage> createState() => _EmployeeReportPageState();
}

class _EmployeeReportPageState extends State<EmployeeReportPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  List<dynamic> monthlyData = [];
  DateTime selectedYear = DateTime.now();
  int apiWarningCount = 0;
  List<WarningModel> apiWarnings = [];
  double completionPercentage = 0;
  double onTimePercentage = 0;
  double delayedGoalPercent = 0;
  @override
  void initState() {
    super.initState();
    _fetchWarnings();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      final report = await ReportsService.getEmployeeReport(
        widget.userid,
        selectedYear.year,
      );
      final monthly = await ReportsService.getMonthlyProductivity(
        widget.userid,
        selectedYear.year,
      );

      setState(() {
        data = report;
        monthlyData = monthly;
        completionPercentage = (data?["goalCompletionPercent"] ?? 0).toDouble();
        onTimePercentage = (data?["goalOnTimePercent"] ?? 0).toDouble();
        delayedGoalPercent = (data?["delayedGoalPercent"] ?? 0).toDouble();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  void _fetchWarnings() async {
    try {
      final warnings = await AnnouncementService.getWarningsByUser(
        widget.userid,
      );

      if (!mounted) return;

      setState(() {
        apiWarnings = warnings;
        apiWarningCount = warnings.length;
      });
    } catch (e) {
      print("Warning fetch error: $e");
    }
  }

  Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> generateAndDownloadPDF() async {
    // Fetch detailed report data for tables
    Map<String, dynamic> reportData = {};
    try {
      reportData = await ReportsService.getFullReport(
        userId: widget.userid,
      );
    } catch (e) {
      print("Error fetching full report: $e");
    }

    // Create PDF generator and generate PDF
    final pdfGenerator = EmployeeReportPdfGenerator(
      userId: widget.userid,
      username: widget.username,
      reportYear: selectedYear.year,
      summaryData: data!,
      monthlyData: monthlyData,
      warnings: apiWarnings,
      completionPercentage: completionPercentage,
      onTimePercentage: onTimePercentage,
      delayedGoalPercent: delayedGoalPercent,
      reportData: reportData,
    );

    await pdfGenerator.generateAndDownloadPDF();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: RotatingFlower()));
    }

    if (data == null) {
      return const Scaffold(body: Center(child: Text("No data found")));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
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
                  builder: (context) => ReportsTable(userId: widget.userid),
                ),
              );
            }, 
            icon: const Icon(Icons.bar_chart_rounded),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedYear,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year, // 🔥 IMPORTANT
              );

              if (picked != null) {
                setState(() {
                  selectedYear = picked;
                  isLoading = true;
                });

                fetchAllData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Goal & Task Summary",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SmallStatCard(
                    title: "Total Goals",
                    value: (data?["totalGoals"] ?? 0).toString(),
                    icon: Icons.emoji_events_outlined,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SmallStatCard(
                    title: "Total Tasks",
                    value: (data?["totalTasks"] ?? 0).toString(),
                    icon: Icons.task_outlined,
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
                    title: "Goals Completed",
                    value: (data?["completedGoals"] ?? 0).toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SmallStatCard(
                    title: "Goals Pending",
                    value: (data?["pendingGoals"] ?? 0).toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SmallStatCard(
                    title: "Goals Overdue",
                    value: (data?["overdueGoals"] ?? 0).toString(),
                    icon: Icons.warning_amber_outlined,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Task Status
            Row(
              children: [
                Expanded(
                  child: SmallStatCard(
                    title: "Tasks Completed",
                    value: (data?["completedTasks"] ?? 0).toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SmallStatCard(
                    title: "Tasks Pending",
                    value: (data?["pendingTasks"] ?? 0).toString(),
                    icon: Icons.pending_actions,
                    color: const Color.fromARGB(255, 235, 211, 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SmallStatCard(
                    title: "Tasks Overdue",
                    value: (data?["overdueTasks"] ?? 0).toString(),
                    icon: Icons.warning_amber_outlined,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),

            // Goal Status
            const SizedBox(height: 20),
            Text(
              "Performance Overview",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: KpiCircleCard(
                    title: "Goal Completion %",
                    value: completionPercentage,
                    icon: Icons.verified_outlined,
                    isPercentage: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCircleCard(
                    title: "On-Time Completion %",
                    value: onTimePercentage,
                    icon: Icons.verified_outlined,
                    isPercentage: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCircleCard(
                    title: "Delayed %",
                    value: delayedGoalPercent,
                    icon: Icons.verified_outlined,
                    isPercentage: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CapsuleBarChart(data: monthlyData),
            const SizedBox(height: 10),
            (data?["year"] ?? 0) == DateTime.now().year
                ? const SizedBox() // hide
                : YearlyProductivityPage(
                    year: data?["year"],
                    yearlyProductivity: (data?["yearlyProductivity"] ?? 0)
                        .toDouble(),
                  ),
            const SizedBox(height: 20),
            MonthlyTrendChart(
              monthlyData: (data?["monthlyTrend"] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
            ),
            const SizedBox(height: 20),

            if (apiWarnings.isNotEmpty) ...[
              /// Title + Count
              Row(
                children: [
                  Text(
                    "Warnings",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                        // ignore: deprecated_member_use
                      ).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$apiWarningCount",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              /// Warning List
              ...apiWarnings.map((warning) {
                final severityColor = getSeverityColor(warning.severity);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius:
                        Theme.of(context).cardTheme.shape
                            is RoundedRectangleBorder
                        ? (Theme.of(context).cardTheme.shape
                                  as RoundedRectangleBorder)
                              .borderRadius
                        : BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Left Color Indicator
                      Container(
                        width: 5,
                        height: 80,
                        decoration: BoxDecoration(
                          color: severityColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Title + Date
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      warning.title,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${warning.createdDate.day}/${warning.createdDate.month}/${warning.createdDate.year}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              /// Message
                              Text(
                                warning.message,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),

                              const SizedBox(height: 8),

                              /// Footer
                              Row(
                                children: [
                                  Text(
                                    "${warning.receiverName} • ${warning.receiverRole}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      // ignore: deprecated_member_use
                                      color: severityColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Warning ${warning.escalationLevel}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: severityColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
