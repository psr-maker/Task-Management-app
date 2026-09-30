import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/utils/role_hierarchy.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/extrawork/Compensation.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/leave/leavelist.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/ovtme/overtime.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/punch/punchlist.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/settings/usersettings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/warning.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/utils/work_performance.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class StaffDashboard extends StatefulWidget {
  final int userid;
  final String role;
  final VoidCallback? onBackToManager;
  final String backToLabel;
  const StaffDashboard({
    super.key,
    required this.userid,
    required this.role,
    this.onBackToManager,
    this.backToLabel = "Back to Dashboard",
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool loadFailed = false;
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;

  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];
  int apiWarningCount = 0;
  List<WarningModel> apiWarnings = [];
  int notificationCount = 0;
  DateTime selectedYear = DateTime.now();
  List<dynamic> monthlyData = [];
  late bool _hideOvertime;
  TaskTiming taskTiming = TaskTiming.empty;

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

  @override
  void initState() {
    super.initState();
    _hideOvertime = false;
    _resolveOvertimeVisibility();
    fetchAllData();
    _loadTaskTiming();
    //_fetchNotifications();
    _fetchWarnings();
  }

  Future<void> _resolveOvertimeVisibility() async {
    try {
      final roles = await SuperAdminService.getRoles();
      final hide = skipsOvertime(roles, widget.role);
      if (mounted) setState(() => _hideOvertime = hide);
    } catch (_) {}
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
      List<dynamic> monthly = [];
      try {
        monthly = await ReportsService.getMonthlyProductivity(
          widget.userid,
          selectedYear.year,
        );
      } catch (e) {
        debugPrint("Monthly productivity: $e");
      }

      if (!mounted) return;
      setState(() {
        data = report;
        monthlyData = monthly;
        isLoading = false;
        loadFailed = false;
        overdueTaskCount = _asInt(report["overdueTasks"]);
        overdueGoalCount = _asInt(report["overdueGoals"]);
        overdueTaskList = _mapList(report["overdueTaskList"]);
        overdueGoalList = _mapList(report["overdueGoalList"]);
      });
    } catch (e) {
      debugPrint("Staff dashboard: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadFailed = true;
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? 0;
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return [];
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
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

    final Map<String, dynamic> attendanceMap = {};
    for (final item in list) {
      if (item is! Map) continue;
      final rawMonth = item["month"];
      final month = rawMonth is num
          ? rawMonth.toInt()
          : int.tryParse(rawMonth?.toString() ?? "") ?? 0;
      if (month < 1 || month > 12) continue;
      attendanceMap[months[month - 1]] = {
        "leave": _asDouble(item["leave"]),
        "permission": _asDouble(item["permission"]),
      };
    }
    if (isLoading) {
      return const Scaffold(body: Center(child: RotatingFlower()));
    }

    double completionPercentage = _asDouble(data?["goalCompletionPercent"]);
    double onTimePercentage = _asDouble(data?["goalOnTimePercent"]);
    double delayedGoalPercent = _asDouble(data?["delayedGoalPercent"]);
    final isWeb = !AppLayout.isMobile(context);
    bindWebHeader(
      context,
      overdueCount: overdueTaskCount + overdueGoalCount + apiWarningCount,
      onOverdue: () {
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
      onReports: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportsTable(userId: widget.userid),
          ),
        );
      },
      onSettings: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UsersSettings()),
        );
      },
      menuItems: _sidebarMenu(),
    );

    return Scaffold(
      drawer: isWeb ? null : _buildDrawer(context),
      appBar: isWeb
          ? null
          : AppBar(
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
          // Stack(
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.notifications, color: Colors.amber),
          //       onPressed: () async {
          //         await Navigator.push(
          //           context,
          //           MaterialPageRoute(builder: (_) => NotificationPage()),
          //         );

          //         // Refresh count when coming back
          //        // _fetchNotifications();
          //       },
          //     ),

          //     if (notificationCount > 0)
          //       Positioned(
          //         right: 8,
          //         top: 8,
          //         child: Container(
          //           padding: const EdgeInsets.all(4),
          //           decoration: const BoxDecoration(
          //             color: Colors.red,
          //             shape: BoxShape.circle,
          //           ),
          //           constraints: const BoxConstraints(
          //             minWidth: 15,
          //             minHeight: 15,
          //           ),
          //           child: Text(
          //             notificationCount.toString(),
          //             style: const TextStyle(
          //               color: Colors.white,
          //               fontSize: 8,
          //               fontWeight: FontWeight.bold,
          //             ),
          //             textAlign: TextAlign.center,
          //           ),
          //         ),
          //       ),
          //   ],
          // ),
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
                MaterialPageRoute(builder: (_) => UsersSettings()),
              );
            },
          ),
        ],
      ),

      body: loadFailed
          ? const AppLoadError()
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Stack(
          children: [
            Padding(
              padding: AppLayout.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Goal & Task Summary",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(height: 10),
                  WebResponsiveRow(
                    minChildWidth: 180,
                    children: AppLayout.isMobile(context)
                        ? [
                            SmallStatCard(
                              title: "Total Goals",
                              value: (data?["totalGoals"] ?? 0).toString(),
                              icon: Icons.emoji_events_outlined,
                              color: Colors.deepPurple,
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Total Goals",
                              ),
                            ),
                            SmallStatCard(
                              title: "Total Tasks",
                              value: (data?["totalTasks"] ?? 0).toString(),
                              icon: Icons.task_outlined,
                              color: Colors.blue,
                              onTap: () => _openList(
                                DashboardListKind.tasks,
                                "Total Tasks",
                              ),
                            ),
                          ]
                        : [
                            SmallStatCard(
                              title: "Productivity Score",
                              value:
                                  "${completionPercentage.toStringAsFixed(0)}%",
                              icon: Icons.insights_outlined,
                              color: WebTheme.brand,
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Completed Goals",
                                filter: WorkStatusFilter.completed,
                              ),
                            ),
                            SmallStatCard(
                              title: "Tasks Completed",
                              value: (data?["completedTasks"] ?? 0).toString(),
                              icon: Icons.task_alt_rounded,
                              color: WebTheme.success,
                              onTap: () => _openList(
                                DashboardListKind.tasks,
                                "Completed Tasks",
                                filter: WorkStatusFilter.completed,
                              ),
                            ),
                            SmallStatCard(
                              title: "Pending Tasks",
                              value: (data?["pendingTasks"] ?? 0).toString(),
                              icon: Icons.pending_actions_outlined,
                              color: WebTheme.warning,
                              onTap: () => _openList(
                                DashboardListKind.tasks,
                                "Pending Tasks",
                                filter: WorkStatusFilter.pending,
                              ),
                            ),
                            SmallStatCard(
                              title: "Goals Progress",
                              value:
                                  "${(data?["completedGoals"] ?? 0)}/${(data?["totalGoals"] ?? 0)}",
                              icon: Icons.flag_outlined,
                              color: WebTheme.dark,
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Completed Goals",
                                filter: WorkStatusFilter.completed,
                              ),
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

                  // Task Status
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

                  // Goal Status
                  const SizedBox(height: 20),
                  Text(
                    "Performance Overview",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 15),
                  WebResponsiveRow(
                    minChildWidth: 180,
                    children: [
                      KpiCircleCard(
                        title: "Goal Completion %",
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
                        onTap: () => _openList(
                          DashboardListKind.goals,
                          "Completed Goals",
                          filter: WorkStatusFilter.completed,
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
                        onTap: () => _openList(
                          DashboardListKind.goals,
                          "On-Time Completed Goals",
                          filter: WorkStatusFilter.onTime,
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
                        onTap: () => _openList(
                          DashboardListKind.goals,
                          "Delayed Completed Goals",
                          filter: WorkStatusFilter.delayed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  WebPanel.wrap(context, CapsuleBarChart(data: monthlyData)),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WebMenuItem> _sidebarMenu() {
    void open(Widget page) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    return [
      if (widget.onBackToManager != null)
        WebMenuItem(
          icon: Icons.dashboard_customize_rounded,
          label: widget.backToLabel,
          group: 'Profile',
          onTap: widget.onBackToManager!,
        ),
      WebMenuItem(
        icon: Icons.event_available_rounded,
        label: 'Leave / Permission',
        group: 'Requests',
        onTap: () => open(const Leavelist()),
      ),
      if (!AppRoles.isDivisionHead(widget.role)) ...[
        WebMenuItem(
          icon: Icons.event_repeat_rounded,
          label: 'Compensation work',
          group: 'Requests',
          onTap: () => open(const MyExtraWorkPage()),
        ),
        if (!_hideOvertime)
          WebMenuItem(
            icon: Icons.more_time_rounded,
            label: 'Overtime',
            group: 'Requests',
            onTap: () => open(const OvertimeListttt()),
          ),
        WebMenuItem(
          icon: Icons.edit_calendar_rounded,
          label: 'Attendance Correction',
          group: 'Requests',
          onTap: () => open(const PunchCorrectionList()),
        ),
      ],
    ];
  }

  Widget _buildDrawer(BuildContext context) {
    return AppMenuDrawer(
      title: 'Staff',
      subtitle: 'My menu',
      icon: Icons.person_rounded,
      items: _sidebarMenu(),
    );
  }
}
