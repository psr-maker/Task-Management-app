import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/downpdf.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/utils/work_performance.dart';
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
  bool _isDownloadingPdf = false;
  TaskTiming taskTiming = TaskTiming.empty;

  double _percent(Map source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchWarnings();
    fetchAllData();
    _loadTaskTiming();
  }

  Future<void> _loadTaskTiming() async {
    final timing = await TaskTiming.load(
      userId: widget.userid,
      year: selectedYear.year,
    );
    if (!mounted) return;
    setState(() => taskTiming = timing);
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

      if (!mounted) return;
      setState(() {
        data = report;
        monthlyData = monthly;
        completionPercentage = _percent(report, [
          "goalCompletionPercent",
          "goalCompletionPercentage",
        ]);
        onTimePercentage = _percent(report, [
          "goalOnTimePercent",
          "onTimeGoalCompletionPercentage",
        ]);
        delayedGoalPercent = _percent(report, [
          "delayedGoalPercent",
          "delayedGoalPercentage",
        ]);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

  void _openList(
    DashboardListKind kind,
    String title, {
    WorkStatusFilter filter = WorkStatusFilter.all,
  }) {
    openDashboardList(
      context,
      kind: kind,
      filter: filter,
      title: title,
      userId: widget.userid,
    );
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
    if (!mounted) return;
    setState(() {
      _isDownloadingPdf = true;
    });
    Map<String, dynamic> reportData = {};
    try {
      reportData = await ReportsService.getFullReport(userId: widget.userid);

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
    } catch (e) {
      print(e);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List list = data?["leavePermissionMonthly"] ?? [];
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    final Map<String, dynamic> attendanceMap = {
      for (var item in list)
        months[(item["month"] ?? 1) - 1]: {
          "leave": item["leave"] ?? 0,
          "permission": item["permission"] ?? 0,
        },
    };
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
            onPressed: _isDownloadingPdf ? null : generateAndDownloadPDF,
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
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
                if (!mounted) return;
                setState(() {
                  selectedYear = picked;
                  isLoading = true;
                });

                fetchAllData();
                _loadTaskTiming();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebSectionTitle(title: "Goal & Task Summary"),
            WebResponsiveRow(
              minChildWidth: 180,
              children: [
                SmallStatCard(
                  title: "Total Goals",
                  value: (data?["totalGoals"] ?? 0).toString(),
                  icon: Icons.emoji_events_outlined,
                  color: Colors.deepPurple,
                  onTap: () => _openList(DashboardListKind.goals, "Total Goals"),
                ),
                SmallStatCard(
                  title: "Total Tasks",
                  value: (data?["totalTasks"] ?? 0).toString(),
                  icon: Icons.task_outlined,
                  color: Colors.blue,
                  onTap: () => _openList(DashboardListKind.tasks, "Total Tasks"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            WebResponsiveRow(
              minChildWidth: 160,
              children: [
                SmallStatCard(
                  title: "Goals Completed",
                  value: (data?["completedGoals"] ?? 0).toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onTap: () => _openList(
                    DashboardListKind.goals,
                    "Completed Goals",
                    filter: WorkStatusFilter.completed,
                  ),
                ),
                SmallStatCard(
                  title: "Goals Pending",
                  value: (data?["pendingGoals"] ?? 0).toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  onTap: () => _openList(
                    DashboardListKind.goals,
                    "Pending Goals",
                    filter: WorkStatusFilter.pending,
                  ),
                ),
                SmallStatCard(
                  title: "Goals Overdue",
                  value: (data?["overdueGoals"] ?? 0).toString(),
                  icon: Icons.warning_amber_outlined,
                  color: Colors.red,
                  onTap: () => _openList(
                    DashboardListKind.goals,
                    "Overdue Goals",
                    filter: WorkStatusFilter.overdue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            WebResponsiveRow(
              minChildWidth: 160,
              children: [
                SmallStatCard(
                  title: "Tasks Completed",
                  value: (data?["completedTasks"] ?? 0).toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.teal,
                  onTap: () => _openList(
                    DashboardListKind.tasks,
                    "Completed Tasks",
                    filter: WorkStatusFilter.completed,
                  ),
                ),
                SmallStatCard(
                  title: "Tasks Pending",
                  value: (data?["pendingTasks"] ?? 0).toString(),
                  icon: Icons.pending_actions,
                  color: const Color.fromARGB(255, 235, 211, 0),
                  onTap: () => _openList(
                    DashboardListKind.tasks,
                    "Pending Tasks",
                    filter: WorkStatusFilter.pending,
                  ),
                ),
                SmallStatCard(
                  title: "Tasks Overdue",
                  value: (data?["overdueTasks"] ?? 0).toString(),
                  icon: Icons.warning_amber_outlined,
                  color: Colors.redAccent,
                  onTap: () => _openList(
                    DashboardListKind.tasks,
                    "Overdue Tasks",
                    filter: WorkStatusFilter.overdue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const WebSectionTitle(title: "Performance Overview"),
            WebResponsiveRow(
              minChildWidth: 180,
              children: [
                KpiCircleCard(
                  title: "Completion %",
                  goalPercent: ringPercent(
                    data?["totalGoals"],
                    completionPercentage,
                  ),
                  taskPercent: ringPercent(
                    data?["totalTasks"],
                    completionPercent(
                      data?["completedTasks"],
                      data?["totalTasks"],
                    ),
                  ),
                ),
                KpiCircleCard(
                  title: "On-Time Completion %",
                  goalPercent: ringPercent(
                    data?["totalGoals"],
                    onTimePercentage,
                  ),
                  taskPercent: ringPercent(
                    data?["totalTasks"],
                    taskTiming.onTime,
                  ),
                ),
                KpiCircleCard(
                  title: "Delayed %",
                  goalPercent: ringPercent(
                    data?["totalGoals"],
                    delayedGoalPercent,
                  ),
                  taskPercent: ringPercent(
                    data?["totalTasks"],
                    taskTiming.delayed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            WebPanel.wrap(context, CapsuleBarChart(data: monthlyData)),
            const SizedBox(height: 10),
            (data?["year"] ?? 0) == DateTime.now().year
                ? const SizedBox() // hide
                : YearlyProductivityPage(
                    year: data?["year"],
                    yearlyProductivity: (data?["yearlyProductivity"] ?? 0)
                        .toDouble(),
                  ),
            const SizedBox(height: 20),
            WebPanel.wrap(
              context,
              LeavePermissionChart(attendance: attendanceMap),
            ),
            const SizedBox(height: 20),
            WebPanel.wrap(
              context,
              MonthlyTrendChart(
                monthlyData: (data?["monthlyTrend"] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            // LeavePermissionChart(attendance: attendance),
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
