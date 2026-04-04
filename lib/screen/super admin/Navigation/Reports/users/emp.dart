import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/reports_service.dart';
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

  @override
  void initState() {
    super.initState();
    // fetchReport();
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: RotatingFlower()));
    }

    if (data == null) {
      return const Scaffold(body: Center(child: Text("No data found")));
    }

    double completionPercentage = (data?["goalCompletionPercent"] ?? 0)
        .toDouble();
    double onTimePercentage = (data?["goalOnTimePercent"] ?? 0).toDouble();
    double delayedGoalPercent = (data?["delayedGoalPercent"] ?? 0).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
          ],
        ),
      ),
    );
  }
}
