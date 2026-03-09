import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/reports.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/notifi.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/warning.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/notification_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class StaffDashboard extends StatefulWidget {
  final int userid;
  final String role;
  const StaffDashboard({super.key, required this.userid, required this.role});

  @override
  State<StaffDashboard> createState() => _EmployeeReportPageState();
}

class _EmployeeReportPageState extends State<StaffDashboard> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  int overdueCount = 0;
  int notificationCount = 0;
  int apiWarningCount = 0;
  List<WarningModel> apiWarnings = [];
  List<Map<String, dynamic>> overdueList = [];
  @override
  void initState() {
    super.initState();
    fetchReport();
    _fetchNotifications();
    _fetchWarnings();
  }

  void _fetchNotifications() async {
    try {
      final data = await NotificationService.getMyNotifications();

      if (!mounted) return;

      setState(() {
        notificationCount = data.where((n) => n["isRead"] == false).length;
      });
    } catch (e) {
      print("Notification fetch error: $e");
    }
  }

  void _fetchWarnings() async {
    try {
      final warnings = await AnnouncementService.getWarnings();

      if (!mounted) return;

      setState(() {
        apiWarnings = warnings;
        apiWarningCount = warnings.length;
      });
    } catch (e) {
      print("Warning fetch error: $e");
    }
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

  void showTaskDetails(Map task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? delayReason = task["delayReason"];
        String? comment = task["comment"];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task["taskName"] ?? "",
                style: Theme.of(context).textTheme.labelMedium,
              ),

              const SizedBox(height: 20),

              buildInfoRow("System Points", task["systemPoints"]),
              buildInfoRow("Final Points", task["finalPoints"]),

              buildInfoRow(
                "Delay Justified",
                task["isDelayJustified"] == true ? "Yes" : "No",
              ),

              if (delayReason != null &&
                  delayReason.toString().trim().isNotEmpty)
                buildInfoRow("Delay Reason", delayReason),

              if (comment != null && comment.toString().trim().isNotEmpty)
                buildInfoRow("Comment", comment),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: RotatingFlower()));
    }

    if (data == null) {
      return const Scaffold(body: Center(child: Text("No data found")));
    }

    double completionPercentage = (data?["completionPercent"] ?? 0).toDouble();
    final List reviews = (data?["reviews"] ?? []) as List;
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),

        actions: [
          if (overdueCount > 0 || apiWarningCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Warning(overdueTasks: overdueList),
                      ),
                    );
                  },
                ),

                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (overdueCount + apiWarningCount).toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.amber),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationPage()),
                  );

                  // Refresh count when coming back
                  _fetchNotifications();
                },
              ),

              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Reportsstaff(userId: widget.userid),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Settings()),
              );
            },
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
                "Task Summary",
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

              const SizedBox(height: 20),
              Text(
                "Performance Overview",
                style: Theme.of(context).textTheme.displaySmall,
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
                      title: "Quality Score",
                      value: (data?["finalAveragePoints"] ?? 0).toDouble(),
                      icon: Icons.star_border,
                      isPercentage: false,
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),

              MonthlyTrendChart(
                monthlyData:
                    (data?["monthlyTrend"] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                    [],
              ),

              if (reviews.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  "Task Performance Points",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 15),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildPerformanceCircle(
                      avgPoints: (data?["finalAveragePoints"] ?? 0).toDouble(),
                    ),

                    const SizedBox(width: 15),

                    Expanded(child: buildTaskProgress(reviews)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskProgress(List taskReviews) {
    return Column(
      children: taskReviews.map<Widget>((task) {
        int finalPoints = task["finalPoints"] ?? 0;

        double progress = (finalPoints / 100).clamp(0.0, 1.0);

        Color barColor;
        if (finalPoints >= 75) {
          barColor = Theme.of(context).colorScheme.secondary;
        } else if (finalPoints >= 50) {
          barColor = Colors.orange;
        } else {
          barColor = Theme.of(context).colorScheme.error;
        }

        return GestureDetector(
          onTap: () {
            showTaskDetails(task);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Task Name
                Text(
                  task["taskName"] ?? "",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),

                const SizedBox(height: 5),

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

                    /// Final Points
                    Row(
                      children: [
                        Text(
                          finalPoints.toString(),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.star, color: barColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildPerformanceCircle({required double avgPoints}) {
    double percent = (avgPoints / 100).clamp(0.0, 1.0);

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
              const SizedBox(height: 15),
              Text(
                "Avg Points",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 5),
              Text(
                avgPoints.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ],
      ),
    );
  }
}
