import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/admin_approval.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/usersworklog.dart';
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

class SuperAdminDashboard extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  const SuperAdminDashboard({super.key, this.fromDate, this.toDate});

  @override
  State<SuperAdminDashboard> createState() => _OverallReportsTabState();
}

class _OverallReportsTabState extends State<SuperAdminDashboard> {
  late Future<Map<String, dynamic>> reportFuture;
  String selectedStatus = "All";
  int overdueCount = 0;
  List<Map<String, dynamic>> overdueList = [];
  int apiWarningCount = 0;
  List<WarningModel> apiWarnings = [];
  int notificationCount = 0;
  @override
  void initState() {
    super.initState();
    _fetchReport();
    _fetchWarnings();
    _fetchNotifications();
  }

  void _fetchReport() {
    reportFuture = ReportsService.fetchReport(
      fromDate: widget.fromDate,
      toDate: widget.toDate,
    );

    reportFuture.then((data) {
      if (!mounted) return;

      setState(() {
        overdueCount = data["overdueTasks"] ?? 0;

        overdueList =
            (data['overdueTasksList'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
      });
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  List<Map<String, dynamic>> _getRankedDepartments(List departments) {
    List<Map<String, dynamic>> ranked = [];

    for (var dept in departments) {
      final total = (dept["total"] ?? 0);
      final completed = (dept["completed"] ?? 0);

      double completionRate = 0;
      if (total > 0) {
        completionRate = completed / total;
      }

      ranked.add({...dept, "completionRate": completionRate});
    }

    ranked.sort(
      (a, b) => (b["completionRate"] as double).compareTo(
        a["completionRate"] as double,
      ),
    );

    return ranked;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Director Dashboard'),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (overdueCount + apiWarningCount).toString(),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.amber),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationPage()),
                  );
                  _fetchNotifications();
                },
              ),

              if (notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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

          final departments = data["departmentSummary"] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Summary",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Managers",
                        value: data["totalManagers"].toString(),
                        icon: Icons.person,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Staff",
                        value: data["totalStaff"].toString(),
                        icon: Icons.people,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Departments",
                        value: data["totalDepartments"].toString(),
                        icon: Icons.people,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

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
                        value: (data["completedTasks"] ?? 0).toString(),
                        icon: Icons.check_circle_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.completed),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending",
                        value: (data["pendingTasks"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: TaskUtils.getStatusColor(TaskStatus.pending),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "In Progress",
                        value: (data["inProgressTasks"] ?? 0).toString(),
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
                        value: (data["notStartedTasks"] ?? 0).toString(),
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
                        value: (data["lateCompletedTasks"] ?? 0).toString(),
                        icon: Icons.pending_outlined,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue Task",
                        value: (data["overdueTasks"] ?? 0).toString(),
                        icon: Icons.warning_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
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
                        value: _toDouble(data["completionPercentage"]),
                        icon: Icons.verified_outlined,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiCircleCard(
                        title: "On-Time",
                        value: _toDouble(data["slaPercentage"]),
                        icon: Icons.verified_outlined,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiCircleCard(
                        title: "Task Growth",
                        value: _toDouble(data["growthPercentage"]),

                        icon: Icons.trending_up,
                        isPercentage: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  "Department Ranking",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 15),
                _buildDepartmentChart(departments),
                const SizedBox(height: 15),
                _buildDepartmentRanking(departments),
              
                MonthlyTrendChart(
                  monthlyData:
                      (data["monthlyTrend"] as List<dynamic>?)
                          ?.map((e) => e as Map<String, dynamic>)
                          .toList() ??
                      [],
                ),

                const SizedBox(height: 15),
                PendingApprovals(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 150,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 30),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "Super Admin",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Admin Panel",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          ListTile(
            leading: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              "Audit Log",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AuditLogPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.speaker_notes_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              "Anouncements",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Anounce()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.access_time_sharp,
              color: Theme.of(context).colorScheme.secondary,
            ), 
            title: Text(
              "Worklog",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UsersWorklog()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentRanking(List departments) {
    final ranked = _getRankedDepartments(departments);

    final hasPerformance = ranked.any(
      (dept) => (dept["completionRate"] as double) > 0,
    );

    if (!hasPerformance) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No performance data available",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final topDepartments = ranked
        .where((dept) => (dept["completionRate"] as double) > 0)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(topDepartments.length, (index) {
        final dept = topDepartments[index];
        final rank = index + 1;
        final completionRate = dept["completionRate"] as double;
        final percent = (completionRate * 100).toStringAsFixed(0);

        Color rankColor;
        IconData rankIcon;

        switch (rank) {
          case 1:
            rankColor = Colors.amber;
            rankIcon = Icons.emoji_events;
            break;
          case 2:
            rankColor = Colors.grey;
            rankIcon = Icons.emoji_events;
            break;
          case 3:
            rankColor = Colors.brown;
            rankIcon = Icons.emoji_events;
            break;
          default:
            rankColor = Colors.blueGrey;
            rankIcon = Icons.trending_up;
        }

        final completedTasks = dept["completed"] ?? 0;
        final totalTasks = dept["total"] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: rankColor.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: rankColor.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(rankIcon, color: rankColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${dept["department"]}",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    "$percent%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: rankColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Completed: $completedTasks / $totalTasks tasks",
                 style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionRate,
                  minHeight: 6,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation(rankColor),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDepartmentChart(List departments) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: _generateBarGroups(departments),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= departments.length) {
                    return const SizedBox();
                  }

                  final dept = departments[value.toInt()];
                  final total = (dept["total"] ?? 0).toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      total,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  );
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= departments.length) {
                    return const SizedBox();
                  }

                  final deptName = departments[value.toInt()]["department"]
                      .toString()
                      .replaceAll("Department", "")
                      .trim();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      deptName,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  );
                },
              ),
            ),
          ),

          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.grey, width: 1),
              bottom: BorderSide(color: Colors.grey, width: 1),
            ),
          ),

          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dept = departments[groupIndex];

                final completed = dept["completed"] ?? 0;
                final pending = dept["pending"] ?? 0;
                final overdue = dept["overdue"] ?? 0;
                final total = dept["total"] ?? 0;

                return BarTooltipItem(
                  "${dept["department"]}\n\n"
                  "Total Task: $total\n"
                  "Completed: $completed\n"
                  "Pending: $pending\n"
                  "Overdue: $overdue",

                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),

          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List departments) {
    return List.generate(departments.length, (index) {
      final dept = departments[index];

      final completed = (dept["completed"] ?? 0).toDouble();
      final pending = (dept["pending"] ?? 0).toDouble();
      final overdue = (dept["overdue"] ?? 0).toDouble();
      final total = completed + pending + overdue;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            width: 8,
            borderRadius: BorderRadius.circular(6),
            rodStackItems: [
              BarChartRodStackItem(
                0,
                completed,
                TaskUtils.getStatusColor(TaskStatus.completed),
              ),
              BarChartRodStackItem(
                completed,
                completed + pending,
                TaskUtils.getStatusColor(TaskStatus.pending),
              ),
              BarChartRodStackItem(completed + pending, total, Colors.red),
            ],
          ),
        ],
      );
    });
  }
}
