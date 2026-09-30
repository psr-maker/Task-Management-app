import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/downpdf.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/utils/work_performance.dart';
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
  bool _isDownloadingPdf = false;
  DateTime selectedYear = DateTime.now();
  TaskTiming taskTiming = TaskTiming.empty;

  void _openWork(
    DashboardListKind kind,
    String title, {
    WorkStatusFilter filter = WorkStatusFilter.all,
  }) {
    openDashboardList(
      context,
      kind: kind,
      filter: filter,
      title: title,
      department: widget.department,
    );
  }

  void _openStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(widget.department),
          ),
          body: EmployeeList(
            department: widget.department,
            searchQuery: '',
            openReports: true,
          ),
        ),
      ),
    );
  }

  double _percent(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }

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
    _loadTaskTiming();
  }

  Future<void> _loadTaskTiming() async {
    final timing = await TaskTiming.load(
      department: widget.department,
      year: selectedYear.year,
    );
    if (!mounted) return;
    setState(() => taskTiming = timing);
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
    setState(() {
      _isDownloadingPdf = true;
    });
    Map<String, dynamic> summaryReportData = {};
    Map<String, dynamic> tableReportData = {};

    try {
      summaryReportData = await ReportsService.fetchDepartmentReport(
        widget.department,
      );
      tableReportData = await ReportsService.getFullReport(
        department: widget.department,
      );
      final pdfGenerator = EmployeeReportPdfGenerator(
        department: widget.department,
        reportYear: selectedYear.year,
        summaryData: summaryReportData,
        monthlyData: data?["monthlyData"] ?? [],
        warnings: [],
        completionPercentage: _percent(
          summaryReportData,
          "goalCompletionPercentage",
        ),
        onTimePercentage: _percent(
          summaryReportData,
          "onTimeGoalCompletionPercentage",
        ),
        delayedGoalPercent: _percent(
          summaryReportData,
          "delayedGoalPercentage",
        ),
        reportData: tableReportData,
        // topPerformer:
        //     (summaryReportData["topPerformer"] as List?)?.isNotEmpty == true
        //     ? Map<String, dynamic>.from(summaryReportData["topPerformer"][0])
        //     : null,

        // lowPerformer:
        //     (summaryReportData["lowPerformer"] as List?)?.isNotEmpty == true
        //     ? Map<String, dynamic>.from(summaryReportData["lowPerformer"][0])
        //     : null,
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.department),
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
            return const AppLoadError();
          }

          final data = snapshot.data!;
          final completion = _percent(data, "goalCompletionPercentage");
          final onTime = _percent(data, "onTimeGoalCompletionPercentage");
          final delayed = _percent(data, "delayedGoalPercentage");
          final monthlyData = (this.data?["monthlyData"] as List? ?? []);
          return SingleChildScrollView(
            padding: AppLayout.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WebSectionTitle(title: "Goal & Task Summary"),
                WebResponsiveRow(
                  minChildWidth: 160,
                  children: [
                    SmallStatCard(
                      title: "Total Employees",
                      value: (data["totalUsers"] ?? 0).toString(),
                      icon: Icons.task_outlined,
                      color: Colors.brown,
                      onTap: _openStaff,
                    ),
                    SmallStatCard(
                      title: "Total Goal",
                      value: (data["totalGoals"] ?? 0).toString(),
                      icon: Icons.check_circle_outlined,
                      color: Colors.deepPurple,
                      onTap: () => _openWork(
                        DashboardListKind.goals,
                        "Total Goals",
                      ),
                    ),
                    SmallStatCard(
                      title: "Total Task",
                      value: (data["totalTasks"] ?? 0).toString(),
                      icon: Icons.check_circle_outlined,
                      color: Colors.blue,
                      onTap: () => _openWork(
                        DashboardListKind.tasks,
                        "Total Tasks",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                WebResponsiveRow(
                  minChildWidth: 160,
                  children: [
                    SmallStatCard(
                      title: "Completed Goal",
                      value: (data["completedGoals"] ?? 0).toString(),
                      icon: Icons.task_outlined,
                      color: Colors.green,
                      onTap: () => _openWork(
                        DashboardListKind.goals,
                        "Completed Goals",
                        filter: WorkStatusFilter.completed,
                      ),
                    ),
                    SmallStatCard(
                      title: "Pending Goal",
                      value: (data["pendingGoals"] ?? 0).toString(),
                      icon: Icons.check_circle_outlined,
                      color: Colors.orange,
                      onTap: () => _openWork(
                        DashboardListKind.goals,
                        "Pending Goals",
                        filter: WorkStatusFilter.pending,
                      ),
                    ),
                    SmallStatCard(
                      title: "Overdue Goal",
                      value: (data["overdueGoals"] ?? 0).toString(),
                      icon: Icons.pending_outlined,
                      color: Colors.red,
                      onTap: () => _openWork(
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
                      title: "Completed Tasks",
                      value: (data["completedTasks"] ?? 0).toString(),
                      icon: Icons.task_outlined,
                      color: Colors.teal,
                      onTap: () => _openWork(
                        DashboardListKind.tasks,
                        "Completed Tasks",
                        filter: WorkStatusFilter.completed,
                      ),
                    ),
                    SmallStatCard(
                      title: "Pending Tasks",
                      value: (data["pendingTasks"] ?? 0).toString(),
                      icon: Icons.check_circle_outlined,
                      color: const Color.fromARGB(255, 235, 211, 0),
                      onTap: () => _openWork(
                        DashboardListKind.tasks,
                        "Pending Tasks",
                        filter: WorkStatusFilter.pending,
                      ),
                    ),
                    SmallStatCard(
                      title: "Overdue Tasks",
                      value: (data["overdueTasks"] ?? 0).toString(),
                      icon: Icons.pending_outlined,
                      color: Colors.redAccent,
                      onTap: () => _openWork(
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
                      goalPercent: ringPercent(data["totalGoals"], completion),
                      taskPercent: ringPercent(
                        data["totalTasks"],
                        completionPercent(
                          data["completedTasks"],
                          data["totalTasks"],
                        ),
                      ),
                    ),
                    KpiCircleCard(
                      title: "On-Time Completion%",
                      goalPercent: ringPercent(data["totalGoals"], onTime),
                      taskPercent: ringPercent(
                        data["totalTasks"],
                        taskTiming.onTime,
                      ),
                    ),
                    KpiCircleCard(
                      title: "Delayed %",
                      goalPercent: ringPercent(data["totalGoals"], delayed),
                      taskPercent: ringPercent(
                        data["totalTasks"],
                        taskTiming.delayed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                WebPanel.wrap(
                  context,
                  ProductivityBarChart(
                    data: monthlyData
                        .map(
                          (e) => {
                            "month": e["month"] ?? 0,
                            "taskPoints": e["taskPoints"] ?? 0,
                            "goalPoints": e["goalPoints"] ?? 0,
                            "attitudeScore": e["attitudeScore"] ?? 0,
                            "fiveS": e["fiveS"] ?? 0,
                            "productivity": e["productivity"] ?? 0,
                            "totalscore": e["totalScore"] ?? 0,
                          },
                        )
                        .toList(),
                  ),
                ),
                _buildPerformanceSection(data),
                const SizedBox(height: 25),
                Text(
                  "Staffs List",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                EmployeeList(
                  department: widget.department,
                  searchQuery: '',
                  shrinkWrap: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceSection(Map<String, dynamic> data) {
    final List<dynamic> topList = data["topPerformer"] ?? [];
    final List<dynamic> lowList = data["lowPerformer"] ?? [];

    final Map<String, dynamic>? top = topList.isNotEmpty
        ? Map<String, dynamic>.from(topList.first)
        : null;

    final Map<String, dynamic>? low = lowList.isNotEmpty
        ? Map<String, dynamic>.from(lowList.first)
        : null;

    final bool showTop = top != null;
    final bool showLow = low != null;

    if (!showTop && !showLow) {
      return const SizedBox.shrink();
    }

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
            name: top["user"] ?? "-",
            completedCount: top["completedTasks"] ?? 0,
            totalTasks: top["assignedTasks"] ?? 0,
            score: (top["score"] as num?)?.toDouble() ?? 0,
            startColor: Theme.of(context).colorScheme.primary,
            endColor: Theme.of(context).colorScheme.secondary,
            icon: Icons.emoji_events,
          ),

        if (showTop) const SizedBox(height: 8),

        if (showLow)
          _advancedPerformerCard(
            title: "Low Performer",
            name: low["user"] ?? "-",
            completedCount: low["completedTasks"] ?? 0,
            totalTasks: low["assignedTasks"] ?? 0,
            score: (low["score"] as num?)?.toDouble() ?? 0,
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
    required double score,
    required Color startColor,
    required Color endColor,
    required IconData icon,
  }) {
    final double progress = (score / 100).clamp(0.0, 1.0);

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
                    "${score.toStringAsFixed(1)}%",
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
