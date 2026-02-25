import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/auditlog.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/empreports.dart';

import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warning.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/widgets/progressoverview.dart';

class AdminDashboard extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String department;
  const AdminDashboard({
    super.key,
    required this.department,
    this.fromDate,
    this.toDate,
  });

  @override
  State<AdminDashboard> createState() => _AdminState();
}

class _AdminState extends State<AdminDashboard> {
  late Future<Map<String, dynamic>> deptFuture;
  int overdueCount = 0;
  List<Map<String, dynamic>> overdueList = [];
  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() {
    setState(() {
      deptFuture = DashboardService.fetchmanagerDepartment(
        widget.department,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      deptFuture.then((data) {
        if (!mounted) return;

        setState(() {
          overdueCount = data["overdue"] ?? 0;

          overdueList =
              (data['overdueTaskList'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text('Manager Dashboard'),
        actions: [
          if (overdueCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.warning, color: Colors.red),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      overdueCount.toString(),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Settings()),
              );
            },
          ),
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             ReportsTable(department: widget.department),
          //       ),
          //     );
          //   },
          //   icon: const Icon(Icons.bar_chart_rounded),
          // ),
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

      body: FutureBuilder<Map<String, dynamic>>(
        future: deptFuture,
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
                  "Overview Summary",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Total Staff",
                        value: (data["userCount"] ?? 0).toString(),
                        icon: Icons.task_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportsTable(department: widget.department),
                            ),
                          );
                        },
                        child: SmallStatCard(
                          title: "Staff Reports",
                          value: "",
                          icon: Icons.bar_chart,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
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
                    const SizedBox(width: 10),

                    Expanded(
                      child: SmallStatCard(
                        title: "Completed",
                        value: (data["completed"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.completed),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: SmallStatCard(
                        title: "Pending",
                        value: (data["pending"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.pending),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: SmallStatCard(
                        title: "In Progress",
                        value: (data["inProgress"] ?? 0).toString(),
                        icon: Icons.warning_outlined,
                        color: Colors.blueAccent,
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
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: SmallStatCard(
                        title: "Avg completed days",
                        value: (data["averageCompletionDays"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: SmallStatCard(
                        title: "Late completed",
                        value: (data["lateCompleted"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 10),

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
                const SizedBox(height: 15),
                Text(
                  "Performance Oveview",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: KpiCircleCard(
                        title: "Completion Rate",
                        value: (data["completionPercentage"] ?? 0).toDouble(),
                        icon: Icons.verified_outlined,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiCircleCard(
                        title: "On-Time",
                        value: (data["slaPercentage"] ?? 0).toDouble(),
                        icon: Icons.verified_outlined,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiCircleCard(
                        title: "Growth",
                        value: (data["growthPercentage"] ?? 0).toDouble(),
                        icon: Icons.trending_up,
                        isPercentage: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _buildPerformanceSection(data),

                const SizedBox(height: 15),

                Text(
                  "Monthly Trend",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),

                MonthlyTrendChart(
                  monthlyData: (data["monthlyTrend"] as List)
                      .map((e) => e as Map<String, dynamic>)
                      .toList(),
                ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Performance Metrics",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),

        // Top Performer Card
        _advancedPerformerCard(
          title: "Top Performer",
          name: top?["user"] ?? "-",
          completedCount: top?["completed"] ?? 0,
          totalTasks: top?["totalTasks"] ?? 0,
          startColor: Theme.of(context).colorScheme.primary,
          endColor: Theme.of(context).colorScheme.secondary,
          icon: Icons.emoji_events,
        ),
        const SizedBox(height: 5),

        // Low Performer Card
        _advancedPerformerCard(
          title: "Low Performer",
          name: low?["user"] ?? "-",
          completedCount: low?["completed"] ?? 0,
          totalTasks: low?["totalTasks"] ?? 0,
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
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 8,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Icon Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [startColor, endColor]),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: endColor,
                    //     blurRadius: 6,
                    //     offset: const Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 5),

            // Name
            Text(name, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 5),

            // Progress bar with gradient
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

            // Task count + percentage badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$completedCount / $totalTasks tasks completed",
                  style: Theme.of(context).textTheme.labelSmall,
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
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
                  "Manager Panel",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🔹 SECTION TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Reports",
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 MENU ITEMS
          _buildDrawerItem(
            context,
            icon: Icons.task_alt_rounded,
            title: "Task Review Points",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Taskpoints()),
              );
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.history_toggle_off_rounded,
            title: "Audit Log",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AuditLogPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history_toggle_off_rounded,
            title: "Anouncements",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Anounce()),
              );
            },
          ),
        ],
      ),
    );
  }
}
