import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/leave.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/notifi.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/warning.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/notification_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class StaffDashboard extends StatefulWidget {
  final int userid;
  final String role;
  final VoidCallback? onBackToManager;
  const StaffDashboard({
    super.key,
    required this.userid,
    required this.role,
    this.onBackToManager,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;

  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];
  int apiWarningCount = 0;
  List<WarningModel> apiWarnings = [];
  int notificationCount = 0;
  DateTime selectedYear = DateTime.now();
  List<dynamic> monthlyData = [];

  @override
  void initState() {
    super.initState();
    fetchAllData();
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
        overdueTaskCount = report["overdueTasks"] ?? 0;
        overdueGoalCount = report["overdueGoals"] ?? 0;

        overdueTaskList = List<Map<String, dynamic>>.from(
          report["overdueTaskList"] ?? [],
        );

        overdueGoalList = List<Map<String, dynamic>>.from(
          report["overdueGoalList"] ?? [],
        );
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
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          if ((overdueTaskCount + overdueGoalCount) > 0 || apiWarningCount > 0)
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
                        builder: (_) => Warning(
                          overdueTasks: overdueTaskList,
                          overdueGoals: overdueGoalList,
                        ),
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
                      (overdueTaskCount + overdueGoalCount + apiWarningCount)
                          .toString(),
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
                  builder: (context) => ReportsTable(userId: widget.userid),
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
        scrollDirection: Axis.vertical,
        child: Stack(
          children: [
            Padding(
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

                  (data?["year"] ?? 0) == DateTime.now().year
                      ? const SizedBox() // hide
                      : YearlyProductivityPage(
                          year: data?["year"],
                          yearlyProductivity: (data?["yearlyProductivity"] ?? 0)
                              .toDouble(),
                        ),
                  const SizedBox(height: 10),
                  CapsuleBarChart(data: monthlyData),
                  const SizedBox(height: 20),
                  MonthlyTrendChart(
                    monthlyData: (data?["monthlyTrend"] as List? ?? [])
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.onPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(color: theme.colorScheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.dashboard_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  "Staff Panel",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _buildDrawerItem(
            context,
            icon: Icons.task_alt_rounded,
            title: "Leave Request",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StaffLeave()),
              );
            },
          ),
        ],
      ),
    );
  }
}
