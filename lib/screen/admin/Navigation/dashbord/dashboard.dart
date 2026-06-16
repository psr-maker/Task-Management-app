import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/deptwarnings.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/5spoints.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/deptovertime.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffleaves.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffworklog.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task_member_rmvlst.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/warrentypoints.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/notifi.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/notification_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class AdminDashboard extends StatefulWidget {
  final int mngId;
  final String role;
  final String department;
  const AdminDashboard({
    super.key,
    required this.department,
    required this.role,
    required this.mngId,
  });
  @override
  State<AdminDashboard> createState() => _AdminState();
}

class _AdminState extends State<AdminDashboard> {
  late Future<Map<String, dynamic>> reportFuture;
  Map<String, dynamic>? data;
  bool isLoading = true;
  DateTime selectedYear = DateTime.now();
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;
  int apiWarningCount = 0;
  int notificationCount = 0;
  List<WarningModel> apiWarnings = [];
  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];
  bool showSwitch = false;
  bool isManagerView = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
    loadData();
    _fetchWarnings();
    _fetchNotifications();
  }

  void _fetchWarnings() async {
    try {
      final warnings = await AnnouncementService.getDepartmentWarnings();
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
  }

  // Future<void> loadData() async {
  //   try {
  //     final res = await ReportsService.getdeptMonthlyProductivity(
  //       widget.department,
  //       selectedYear.year,
  //     );
  //     setState(() {
  //       data = res;
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //   }
  // }
  Future<void> loadData() async {
    try {
      final res = await ReportsService.getdeptMonthlyProductivity(
        widget.department,
        selectedYear.year,
      );

      if (!mounted) return;

      setState(() {
        data = res;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSwitchContainer() {
    setState(() => showSwitch = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => showSwitch = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: isManagerView
          ? AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              title: Text('Manager'),
              actions: [
                if ((overdueTaskCount + overdueGoalCount) > 0 ||
                    apiWarningCount > 0)
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
                              builder: (_) => DeptWarning(
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            (overdueTaskCount +
                                    overdueGoalCount +
                                    apiWarningCount)
                                .toString(),
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
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.amber,
                        size: 20,
                      ),
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
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            notificationCount.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
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
                        builder: (context) =>
                            ReportsTable(department: widget.department),
                      ),
                    );
                  },
                  icon: Icon(Icons.bar_chart_rounded),
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
            )
          : null,
      body: isManagerView
          ? FutureBuilder<Map<String, dynamic>>(
              future: reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: RotatingFlower());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final data = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  setState(() {
                    overdueTaskList = List<Map<String, dynamic>>.from(
                      data["overdueTasksList"] ?? [],
                    );

                    overdueGoalList = List<Map<String, dynamic>>.from(
                      data["overdueGoalsList"] ?? [],
                    );

                    overdueTaskCount = overdueTaskList.length;
                    overdueGoalCount = overdueGoalList.length;
                  });
                });
                final monthlyData = (this.data?["monthlyData"] as List? ?? []);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Goal & Task Summary",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SmallStatCard(
                                  title: "Total Staff",
                                  value: (data["totalUsers"] ?? 0).toString(),
                                  icon: Icons.task_outlined,
                                  color: Colors.brown,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SmallStatCard(
                                  title: "Total Goal",
                                  value: (data["totalGoals"] ?? 0).toString(),
                                  icon: Icons.check_circle_outlined,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SmallStatCard(
                                  title: "Total Task",
                                  value: (data["totalTasks"] ?? 0).toString(),
                                  icon: Icons.check_circle_outlined,
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
                                  title: "Completed Goal",
                                  value: (data["completedGoals"] ?? 0)
                                      .toString(),
                                  icon: Icons.task_outlined,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SmallStatCard(
                                  title: "Pending Goal",
                                  value: (data["pendingGoals"] ?? 0).toString(),
                                  icon: Icons.check_circle_outlined,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SmallStatCard(
                                  title: "Overdue Goal",
                                  value: (data["overdueGoals"] ?? 0).toString(),
                                  icon: Icons.pending_outlined,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SmallStatCard(
                                  title: "Completed Tasks",
                                  value: (data["completedTasks"] ?? 0)
                                      .toString(),
                                  icon: Icons.task_outlined,
                                  color: Colors.teal,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SmallStatCard(
                                  title: "Pending Tasks",
                                  value: (data["pendingTasks"] ?? 0).toString(),
                                  icon: Icons.check_circle_outlined,
                                  color: const Color.fromARGB(255, 235, 211, 0),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SmallStatCard(
                                  title: "Overdue Tasks",
                                  value: (data["overdueTasks"] ?? 0).toString(),
                                  icon: Icons.pending_outlined,
                                  color: Colors.redAccent,
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
                                title: "Completion %",
                                value: (data["goalCompletionPercentage"] ?? 0)
                                    .toDouble(),
                                icon: Icons.verified_outlined,
                                isPercentage: true,
                              ),
                              KpiCircleCard(
                                title: "On-Time Completion%",
                                value:
                                    (data["onTimeGoalCompletionPercentage"] ??
                                            0)
                                        .toDouble(),
                                icon: Icons.verified_outlined,
                                isPercentage: true,
                              ),
                              KpiCircleCard(
                                title: "Delayed %",
                                value: (data["delayedGoalPercentage"] ?? 0)
                                    .toDouble(),
                                icon: Icons.timer,
                                isPercentage: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ProductivityBarChart(
                            data: monthlyData
                                .map(
                                  (e) => {
                                    "month": e["month"],
                                    "productivity": e["productivity"],
                                    "taskPoints": e["taskPoints"],
                                    "goalPoints": e["goalPoints"],
                                    "fiveSPoints": e["fiveSPoints"],
                                    "warrantyPoints": e["warrantyPoints"],
                                  },
                                )
                                .toList(),
                          ),
                          _buildPerformanceSection(data),
                        ],
                      ),
                      if (showSwitch) _buildSwitchContainer(),
                    ],
                  ),
                );
              },
            )
          : StaffDashboard(
              onBackToManager: () {
                setState(() {
                  isManagerView = true;
                });
              },
              userid: widget.mngId,
              role: widget.role,
            ),
    );
  }

  Widget _buildSwitchContainer() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: showSwitch ? 0 : -80,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            isManagerView = false;
          });
        },
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            "Switch to My Dashboard",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
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

  //  Widget _buildDrawerItem(
  //   BuildContext context, {
  //   required IconData icon,
  //   required String title,
  //   required VoidCallback onTap,
  // }) {
  //   return ListTile(
  //     leading: Icon(icon),
  //     title: Text(
  //       title,
  //       style: Theme.of(context).textTheme.headlineMedium,
  //     ),
  //     trailing: const Icon(Icons.arrow_forward_ios),
  //     onTap: onTap,
  //   );
  // }

  //   Widget _buildDrawer(BuildContext context) {
  //     final theme = Theme.of(context);
  //     final isDark = theme.brightness == Brightness.dark;
  //     return Drawer(
  //       backgroundColor: isDark
  //           ? theme.colorScheme.primary
  //           : theme.colorScheme.onPrimary,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Container(
  //             width: double.infinity,
  //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
  //             decoration: BoxDecoration(color: theme.colorScheme.secondary),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Icon(
  //                   Icons.dashboard_rounded,
  //                   color: theme.colorScheme.onPrimary,
  //                   size: 32,
  //                 ),
  //                 const SizedBox(height: 12),
  //                 Text(
  //                   "Manager Panel",
  //                   style: Theme.of(context).textTheme.bodySmall,
  //                 ),
  //               ],
  //             ),
  //           ),
  //           SizedBox(height: 20),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.task_alt_rounded,
  //             title: "Task Review Points",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => Taskpoints()),
  //               );
  //             },
  //           ),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.workspace_premium_rounded,
  //             title: "5S Points",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => FiveSpoints()),
  //               );
  //             },
  //           ),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.filter_vintage_sharp,
  //             title: "Warrenty Points",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => Warrentypoints()),
  //               );
  //             },
  //           ),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.history_toggle_off_rounded,
  //             title: "Audit Log",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => AuditLogPage()),
  //               );
  //             },
  //           ),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.message,
  //             title: "Anouncements",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => Anounce()),
  //               );
  //             },
  //           ),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.access_time_sharp,
  //             title: "Worklog",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => Staffworklog()),
  //               );
  //             },
  //           ),
  //           _buildDrawerItem(
  //             context,
  //             icon: Icons.align_horizontal_right_rounded,
  //             title: "Leave Request",
  //             onTap: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => StaffLeaves()),
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark
          ? theme.colorScheme.primary
          : theme.colorScheme.onPrimary,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(color: theme.colorScheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
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

          // Scrollable menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
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
                  icon: Icons.workspace_premium_rounded,
                  title: "5S Points",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FiveSpoints()),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.filter_vintage_sharp,
                  title: "Warranty Points",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Warrentypoints()),
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
                  icon: Icons.message,
                  title: "Announcements",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Anounce()),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.access_time_sharp,
                  title: "Worklog",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Staffworklog()),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.align_horizontal_right_rounded,
                  title: "Leave Request",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StaffLeaves()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history_rounded,
                  title: "OverTime History",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeptOvertimeList()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.highlight_remove_sharp,
                  title: "Task Removal Requests",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TaskRemovalRequest()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom section
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.dashboard_customize_rounded),
            title: Text(
              "My Dashboard",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pop(context);

              _showSwitchContainer();

              setState(() {
                isManagerView = false;
              });
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
