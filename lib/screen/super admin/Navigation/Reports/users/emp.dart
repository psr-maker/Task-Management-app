import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/widgets/progressoverview.dart';

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

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    try {
      final result = await ReportsService.getEmployeeReport(widget.userid);

      setState(() {
        data = result;
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (data == null) {
      return const Scaffold(body: Center(child: Text("No data found")));
    }

    double completionPercentage = (data?["completionPercent"] ?? 0).toDouble();

    List taskReviews = data?["taskReviewDetails"] ?? [];
    List<FlSpot> spots = [];

    for (int i = 0; i < taskReviews.length; i++) {
      double point = (taskReviews[i]["points"] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), point));
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsTable(userId: widget.userid),
                ),
              );
            },
            icon: Icon(Icons.bar_chart_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Task Performance",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SmallStatCard(
                      title: "Total Tasks",
                      value: (data?["totalTasks"] ?? 0).toString(),
                      icon: Icons.task_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SmallStatCard(
                      title: "Completed",
                      value: (data?["completedCount"] ?? 0).toString(),
                      icon: Icons.check_circle_outlined,
                      color: TaskUtils.getStatusColor(TaskStatus.completed),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SmallStatCard(
                      title: "Pending",
                      value: (data?["pendingCount"] ?? 0).toString(),
                      icon: Icons.pending_outlined,
                      color: TaskUtils.getStatusColor(TaskStatus.pending),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SmallStatCard(
                      title: "IN Progress",
                      value: (data?["inProgressCount"] ?? 0).toString(),
                      icon: Icons.pending_outlined,
                      color: TaskUtils.getStatusColor(TaskStatus.inProgress),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SmallStatCard(
                      title: "Not Started",
                      value: (data?["notStartedCount"] ?? 0).toString(),
                      icon: Icons.pending_outlined,
                      color: TaskUtils.getStatusColor(TaskStatus.NotStarted),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SmallStatCard(
                      title: "Avg Completed days",
                      value: (data?["avgCompletionTime"] ?? 0).toString(),
                      icon: Icons.schedule_outlined,
                       color: Colors.teal,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SmallStatCard(
                      title: "Late Completed",
                      value: (data?["lateCompleted"] ?? 0).toString(),
                      icon: Icons.schedule_outlined,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SmallStatCard(
                      title: "Overdue",
                      value: (data?["overdueCount"] ?? 0).toString(),
                      icon: Icons.warning_outlined,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    "Performance Overview",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(width: 10),
                  buildPerformanceBadge(completionPercentage),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: KpiCircleCard(
                      title: "Completion Rate",
                      value: completionPercentage,
                      icon: Icons.verified_outlined,
                      isPercentage: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: KpiCircleCard(
                      title: "On-Time",
                      value: (data?["onTimePercent"] ?? 0).toDouble(),
                      icon: Icons.verified_outlined,
                      isPercentage: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: KpiCircleCard(
                      title: "Productivity",
                      value: (data?["productivityPercent"] ?? 0).toDouble(),
                      icon: Icons.trending_up,
                      isPercentage: true,
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),

              const SizedBox(height: 15),
              Text(
                "Task Performance points",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildPerformanceCircle(
                    totalTasks: data?["totalTasks"] ?? 0,
                    completedTasks: data?["completedCount"] ?? 0,
                    totalPoints: data?["totalPoints"] ?? 0,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: buildTaskProgress(data?["taskReviewDetails"] ?? []),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                "Monthly Trend",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),

              MonthlyTrendChart(
                monthlyData:
                    (data?["monthlyTrend"] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                    [],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPerformanceCircle({
    required int totalTasks,
    required int completedTasks,
    required int totalPoints,
  }) {
    int maxPossiblePoints = totalTasks * 100;

    double percent = maxPossiblePoints > 0
        ? (totalPoints / maxPossiblePoints)
        : 0.0;

    percent = percent.clamp(0.0, 1.0);

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 7,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${totalPoints.toString()} points",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),

              // const SizedBox(height: 4),

              // Text(
              //   "${(percent * 100).toStringAsFixed(0)}%",
              //   style: const TextStyle(fontSize: 14,  color: Colors.white),
              // ),
              const SizedBox(height: 6),

              Text(
                "$completedTasks / $totalTasks Completed",
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTaskProgress(List taskReviews) {
    return Column(
      children: taskReviews.map<Widget>((task) {
        int points = task["points"] ?? 0;

        double progress = (points / 100).clamp(0.0, 1.0);
        Color barColor;

        if (points >= 75) {
          barColor = Colors.green;
        } else if (points >= 50) {
          barColor = Colors.orange;
        } else {
          barColor = Colors.red;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task["taskName"] ?? "",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Text(
                        points.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, size: 18, color: barColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildPerformanceBadge(double completionPercent) {
    String grade;
    Color color;

    if (completionPercent >= 85) {
      grade = "Excellent";
      color = Colors.green;
    } else if (completionPercent >= 60) {
      grade = "Average";
      color = Colors.orange;
    } else {
      grade = "Needs Improvement";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
