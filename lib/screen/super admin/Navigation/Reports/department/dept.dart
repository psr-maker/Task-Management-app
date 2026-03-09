import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/employee/emp_list.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() {
    setState(() {
      reportFuture = ReportsService.fetchDepartmentReport(
        widget.department,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );
    });
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task summary",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Total Tasks",
                        value: (data["totalTasks"] ?? 0).toString(),
                        icon: Icons.task_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Completed",
                        value: (data["completed"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.completed),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending",
                        value: (data["pending"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.pending),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "In Progress",
                        value: (data["inProgress"] ?? 0).toString(),
                        icon: Icons.warning_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.inProgress),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Not Started",
                        value: (data["notStarted"] ?? 0).toString(),
                        icon: Icons.task_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.NotStarted),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Avg completed days",
                        value: (data["averageCompletionDays"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Late completed",
                        value: (data["lateCompleted"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue Task",
                        value: (data["overdue"] ?? 0).toString(),
                        icon: Icons.warning_outlined,
                        color: Colors.red,
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
                      title: "Completion Rate",
                      value: (data["completionPercentage"] ?? 0).toDouble(),
                      icon: Icons.verified_outlined,
                      isPercentage: true,
                    ),

                    KpiCircleCard(
                      title: "On-Time",
                      value: (data["slaPercentage"] ?? 0).toDouble(),
                      icon: Icons.verified_outlined,
                      isPercentage: true,
                    ),
                    KpiCircleCard(
                      title: "Growth",
                      value: (data["growthPercentage"] ?? 0).toDouble(),
                      icon: Icons.trending_up,
                      isPercentage: true,
                    ),
                  ],
                ),

                MonthlyTrendChart(
                  monthlyData: (data["monthlyTrend"] as List)
                      .map((e) => e as Map<String, dynamic>)
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

    final showTop = top != null && (top["completed"] ?? 0) > 0;
    final showLow = low != null && (low["completed"] ?? 0) > 0;

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
            completedCount: top["completed"] ?? 0,
            totalTasks: top["totalTasks"] ?? 0,
            startColor: Theme.of(context).colorScheme.primary,
            endColor: Theme.of(context).colorScheme.secondary,
            icon: Icons.emoji_events,
          ),
        if (showTop) const SizedBox(height: 5),

        if (showLow)
          _advancedPerformerCard(
            title: "Low Performer",
            name: low!["user"] ?? "-",
            completedCount: low["completed"] ?? 0,
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
      height: 100,
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
