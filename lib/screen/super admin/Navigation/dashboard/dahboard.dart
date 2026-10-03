import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffleaves.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/director_compensation.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/admin_approval.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/points.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/users_overtime.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/usersworklog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/warning.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/utils/work_performance.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class SuperAdminDashboard extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  const SuperAdminDashboard({super.key, this.fromDate, this.toDate});

  @override
  State<SuperAdminDashboard> createState() => _OverallReportsTabState();
}

class _OverallReportsTabState extends State<SuperAdminDashboard> {
  late Future<Map<String, dynamic>> dashboard;
  final DashboardService _service = DashboardService();
  int selectedType = 0;
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;

  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];
  int apiWarningCount = 0;
  List<WarningModel> apiWarnings = [];
  int notificationCount = 0;
  TaskTiming taskTiming = TaskTiming.empty;
  bool _showChart = false;

  void _openList(
    DashboardListKind kind,
    String title, {
    WorkStatusFilter filter = WorkStatusFilter.all,
    bool companyDepartments = false,
  }) {
    openDashboardList(
      context,
      kind: kind,
      filter: filter,
      title: title,
      companyDepartments: companyDepartments,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchWarnings();
    dashboard = loadDashboard();
    _loadTaskTiming();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showChart = true);
    });
  }

  Future<void> _loadTaskTiming() async {
    final timing = await TaskTiming.load();
    if (!mounted) return;
    setState(() => taskTiming = timing);
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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _count(dynamic value) {
    if (value == null) return "0";
    if (value is num) {
      if (value == value.roundToDouble()) return value.toInt().toString();
      return value.toString();
    }
    return value.toString();
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) => _map(item)).toList();
  }

  Map<String, dynamic> _map(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      final name = key.toString();
      result[name] = value is Map ? _map(value) : value;
      if (name.isEmpty) return;
      final camel = name[0].toLowerCase() + name.substring(1);
      result.putIfAbsent(camel, () => result[name]);
    });
    return result;
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse("${value ?? ""}") ?? 0;
  }

  Map<String, dynamic> _chartSection(Map dept) {
    final raw = selectedType == 0 ? dept["tasks"] : dept["goals"];
    return _map(raw);
  }

  Widget _departmentCountCard(Map<String, dynamic> dept) {
    final name = (dept["department"] ?? "Department").toString();
    final goals = _map(dept["goals"]);
    final tasks = _map(dept["tasks"]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: WebTheme.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _countLine("Goals", goals, Colors.deepPurple),
          const SizedBox(height: 8),
          _countLine("Tasks", tasks, Colors.blue),
        ],
      ),
    );
  }

  Widget _countLine(String label, Map<String, dynamic> data, Color color) {
    Widget figure(String title, String key) {
      return Padding(
        padding: const EdgeInsets.only(right: 14, bottom: 4),
        child: Text(
          "$title ${_count(data[key])}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WebTheme.inkOf(context),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          children: [
            figure("Total", "total"),
            figure("Completed", "completed"),
            figure("Pending", "pending"),
            figure("Overdue", "overdue"),
          ],
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> loadDashboard() async {
    final raw = _unwrapSummary(await _service.getDashboardSummary());
    var userCount = _int(raw["totalUsers"] ?? raw["TotalUsers"]);
    if (userCount <= 0) {
      try {
        final users = await SuperAdminService.getAllUsers();
        userCount = users.length;
      } catch (_) {}
    }
    final data = {...raw, "totalUsers": userCount};
    if (!mounted) return data;
    final tasks = _mapList(
      data["overdueTasksList"] ?? data["overdueTaskslist"] ?? data["OverdueTasksList"],
    );
    final goals = _mapList(
      data["overdueGoalsList"] ?? data["overdueGoalslist"] ?? data["OverdueGoalsList"],
    );
    setState(() {
      overdueTaskList = tasks;
      overdueGoalList = goals;
      overdueTaskCount = _num(data["tasks"] is Map ? data["tasks"]["overdue"] : null)
          .round();
      if (overdueTaskCount == 0) overdueTaskCount = tasks.length;
      overdueGoalCount = _num(data["goals"] is Map ? data["goals"]["overdue"] : null)
          .round();
      if (overdueGoalCount == 0) overdueGoalCount = goals.length;
    });
    return data;
  }

  Map<String, dynamic> _unwrapSummary(Map<String, dynamic> data) {
    for (final key in ["data", "Data", "result", "Result"]) {
      final inner = data[key];
      if (inner is! Map) continue;
      final map = Map<String, dynamic>.from(inner);
      if (map.containsKey("totalUsers") ||
          map.containsKey("TotalUsers") ||
          map.containsKey("tasks") ||
          map.containsKey("Tasks") ||
          map.containsKey("totalDepartments") ||
          map.containsKey("TotalDepartments")) {
        return map;
      }
    }
    return data;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse("${value ?? ""}") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
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
      onSettings: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Settings()),
        );
      },
      menuItems: _sidebarMenu(),
    );

    return Scaffold(
      drawer: isWeb ? null : _buildDrawer(context),
      appBar: isWeb
          ? null
          : AppBar(
        title: const Text('Dashboard'),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (overdueTaskCount + overdueGoalCount + apiWarningCount)
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
          // Stack(
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.notifications, color: Colors.amber),
          //       onPressed: () async {
          //         await Navigator.push(
          //           context,
          //           MaterialPageRoute(builder: (_) => const NotificationPage()),
          //         );

          //        // _fetchNotifications();
          //       },
          //     ),

          //     if (notificationCount > 0)
          //       Positioned(
          //         right: 6,
          //         top: 6,
          //         child: Container(
          //           padding: const EdgeInsets.all(4),
          //           decoration: const BoxDecoration(
          //             color: Colors.red,
          //             shape: BoxShape.circle,
          //           ),
          //           constraints: const BoxConstraints(
          //             minWidth: 18,
          //             minHeight: 18,
          //           ),
          //           child: Text(
          //             notificationCount.toString(),
          //             style: const TextStyle(
          //               color: Colors.white,
          //               fontSize: 10,
          //               fontWeight: FontWeight.bold,
          //             ),
          //             textAlign: TextAlign.center,
          //           ),
          //         ),
          //       ),
          //   ],
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
        future: dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) {
            return const AppLoadError();
          }
          final data = _map(snapshot.data!);
          final tasks = _map(data["tasks"]);
          final goals = _map(data["goals"]);
          final departments = _mapList(data["departmentData"]);
          return SingleChildScrollView(
            padding: AppLayout.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WebResponsiveRow(
                  minChildWidth: 180,
                  children: [
                    SmallStatCard(
                      title: "Total Users",
                      value: _count(data["totalUsers"]),
                      icon: Icons.people_outline_rounded,
                      color: WebTheme.brand,
                      onTap: () => _openList(
                        DashboardListKind.staff,
                        "Total Users",
                      ),
                    ),
                    SmallStatCard(
                      title: "Departments",
                      value: _count(data["totalDepartments"]),
                      icon: Icons.apartment_outlined,
                      color: WebTheme.dark,
                      onTap: () => _openList(
                        DashboardListKind.departments,
                        "Departments",
                        companyDepartments: true,
                      ),
                    ),
                    if (!AppLayout.isMobile(context)) ...[
                      SmallStatCard(
                        title: "Tasks Completed",
                        value: _count(tasks["completed"]),
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
                        value: _count(tasks["pending"]),
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
                        value: "${_toDouble(goals["completionPercentage"]).toStringAsFixed(0)}%",
                        icon: Icons.flag_outlined,
                        color: WebTheme.brand,
                        onTap: () => _openList(
                          DashboardListKind.goals,
                          "Completed Goals",
                          filter: WorkStatusFilter.completed,
                        ),
                      ),
                      SmallStatCard(
                        title: "Overall Performance",
                        value: "${_toDouble(goals["onTimeCompletionPercentage"]).toStringAsFixed(0)}%",
                        icon: Icons.trending_up_rounded,
                        color: WebTheme.success,
                        onTap: () => _openList(
                          DashboardListKind.goals,
                          "On-Time Completed Goals",
                          filter: WorkStatusFilter.onTime,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Goal & Task Summary",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                WebResponsiveRow(
                  minChildWidth: 160,
                  children: [
                    SmallStatCard(
                      title: "Total Goals",
                      value: _count(goals["total"]),
                      icon: Icons.flag,
                      color: Colors.deepPurple,
                      onTap: () => _openList(
                        DashboardListKind.goals,
                        "Total Goals",
                      ),
                    ),
                    SmallStatCard(
                      title: "Completed",
                      value: _count(goals["completed"]),
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onTap: () => _openList(
                        DashboardListKind.goals,
                        "Completed Goals",
                        filter: WorkStatusFilter.completed,
                      ),
                    ),
                    SmallStatCard(
                      title: "Pending",
                      value: _count(goals["pending"]),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                      onTap: () => _openList(
                        DashboardListKind.goals,
                        "Pending Goals",
                        filter: WorkStatusFilter.pending,
                      ),
                    ),
                    SmallStatCard(
                      title: "Overdue",
                      value: _count(goals["overdue"]),
                      icon: Icons.error,
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
                WebResponsiveRow(
                  minChildWidth: 160,
                  children: [
                    SmallStatCard(
                      title: "Total Tasks",
                      value: _count(tasks["total"]),
                      icon: Icons.list_alt,
                      color: Colors.blue,
                      onTap: () => _openList(
                        DashboardListKind.tasks,
                        "Total Tasks",
                      ),
                    ),
                    SmallStatCard(
                      title: "Completed",
                      value: _count(tasks["completed"]),
                      icon: Icons.check_circle,
                      color: Colors.teal,
                      onTap: () => _openList(
                        DashboardListKind.tasks,
                        "Completed Tasks",
                        filter: WorkStatusFilter.completed,
                      ),
                    ),
                    SmallStatCard(
                      title: "Pending",
                      value: _count(tasks["pending"]),
                      icon: Icons.pending,
                      color: const Color.fromARGB(255, 235, 211, 0),
                      onTap: () => _openList(
                        DashboardListKind.tasks,
                        "Pending Tasks",
                        filter: WorkStatusFilter.pending,
                      ),
                    ),
                    SmallStatCard(
                      title: "Overdue",
                      value: _count(tasks["overdue"]),
                      icon: Icons.warning,
                      color: Colors.redAccent,
                      onTap: () => _openList(
                        DashboardListKind.tasks,
                        "Overdue Tasks",
                        filter: WorkStatusFilter.overdue,
                      ),
                    ),
                  ],
                ),
                if (departments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Department Goal & Task",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  for (final dept in departments) ...[
                    _departmentCountCard(dept),
                    const SizedBox(height: 10),
                  ],
                ],
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
                      title: "Completion %",
                      goalPercent: ringPercent(
                        goals["total"],
                        _toDouble(goals["completionPercentage"]),
                      ),
                      taskPercent: ringPercent(
                        tasks["total"],
                        completionPercent(
                          tasks["completed"],
                          tasks["total"],
                        ),
                      ),
                      onTap: () => _openList(
                        DashboardListKind.goals,
                        "Completed Goals",
                        filter: WorkStatusFilter.completed,
                      ),
                    ),
                    KpiCircleCard(
                      title: "On-Time Completion%",
                      goalPercent: ringPercent(
                        goals["total"],
                        _toDouble(goals["onTimeCompletionPercentage"]),
                      ),
                      taskPercent: ringPercent(
                        tasks["total"],
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
                        goals["total"],
                        _toDouble(goals["delayedPercentage"]),
                      ),
                      taskPercent: ringPercent(
                        tasks["total"],
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
                if (departments.isNotEmpty) ...[
                  Text(
                    "Department Performance",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 15),
                  _buildToggle(),
                  const SizedBox(height: 15),
                  if (_showChart)
                    _buildDepartmentChart(departments)
                  else
                    const SizedBox(
                      height: 300,
                      child: Center(child: RotatingFlower()),
                    ),
                  const SizedBox(height: 20),
                ],
                Alldeptproducticity(),
                const SizedBox(height: 20),
                PendingApprovals(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<WebMenuItem> _sidebarMenu() {
    void open(Widget page) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    return [
      WebMenuItem(
        icon: Icons.work_history_rounded,
        label: 'Work Logs',
        group: 'Work Management',
        onTap: () => open(const UsersWorklog()),
      ),
      WebMenuItem(
        icon: Icons.insights_rounded,
        label: 'Productivity',
        group: 'Performance',
        onTap: () => open(const ProductivityCalculationPage()),
      ),
      WebMenuItem(
        icon: Icons.task_alt_rounded,
        label: 'Task Performance',
        group: 'Performance',
        onTap: () => open(const Taskpoints()),
      ),
      WebMenuItem(
        icon: Icons.psychology_rounded,
        label: 'Attitude & Behaviour',
        group: 'Performance',
        onTap: () => open(const BehaviourScoreDisplay(scoreLeaders: true)),
      ),
      WebMenuItem(
        icon: Icons.event_available_rounded,
        label: 'Leave / Permission',
        group: 'Requests',
        onTap: () => open(const StaffLeaves(isDirectorView: true)),
      ),
      WebMenuItem(
        icon: Icons.more_time_rounded,
        label: 'Compensation Work',
        group: 'Requests',
        onTap: () => open(const DirectorCompensation()),
      ),
      WebMenuItem(
        icon: Icons.schedule_rounded,
        label: 'Overtime',
        group: 'Requests',
        onTap: () => open(const UsersOverTime()),
      ),
      WebMenuItem(
        icon: Icons.campaign_rounded,
        label: 'Announcements',
        group: 'Communication',
        onTap: () => open(const Anounce()),
      ),
      WebMenuItem(
        icon: Icons.manage_search_rounded,
        label: 'Audit Logs',
        group: 'Administration',
        onTap: () => open(const AuditLogPage()),
      ),
    ];
  }

  Widget _buildDrawer(BuildContext context) {
    return AppMenuDrawer(
      title: 'Super Admin',
      subtitle: 'Admin Panel',
      icon: Icons.admin_panel_settings_rounded,
      items: _sidebarMenu(),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(children: [_toggleItem("Task", 0), _toggleItem("Goal", 1)]),
    );
  }

  Widget _toggleItem(String text, int index) {
    final isSelected = selectedType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedType = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentChart(List departments) {
    const double departmentWidth = 100;

    final double chartWidth = math.max(
      MediaQuery.of(context).size.width,
      departments.length * departmentWidth,
    );

    return SizedBox(
      height: 300,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: _generateBarGroups(departments),

              maxY: _getMaxChartValue(departments),

              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= departments.length) {
                        return const SizedBox();
                      }

                      final dept = departments[index];

                      final data = _chartSection(Map<String, dynamic>.from(dept));

                      final total = _count(data["total"]);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          total,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= departments.length) {
                        return const SizedBox();
                      }

                      final deptName = departments[index]["department"]
                          .toString()
                          .replaceAll("Department", "")
                          .trim();

                      return SizedBox(
                        width: departmentWidth - 10,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            deptName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
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
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  tooltipMargin: 6,
                  maxContentWidth: 200,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  direction: TooltipDirection.top,
                  getTooltipColor: (_) => const Color(0xFF1B3A2A),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dept = departments[groupIndex] is Map
                        ? Map<String, dynamic>.from(departments[groupIndex])
                        : <String, dynamic>{};
                    final data = _chartSection(dept);

                    final completed = _count(data["completed"]);
                    final pending = _count(data["pending"]);
                    final overdue = _count(data["overdue"]);
                    final total = _count(data["total"]);

                    final title = selectedType == 0 ? "Task" : "Goal";

                    return BarTooltipItem(
                      "${dept["department"]}\n\n"
                      "Total $title: $total\n"
                      "Completed: $completed\n"
                      "Pending: $pending\n"
                      "Overdue: $overdue",
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),

              gridData: FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxChartValue(List departments) {
    if (departments.isEmpty) {
      return 10;
    }

    double maxValue = 0;

    for (final dept in departments) {
      if (dept is! Map) continue;
      final data = _chartSection(Map<String, dynamic>.from(dept));

      final total = _num(data["total"]);

      if (total > maxValue) {
        maxValue = total;
      }
    }

    // Add some space above tallest bar
    if (maxValue == 0) {
      return 10;
    }

    return maxValue * 1.55;
  }

  ({double height, List<BarChartRodStackItem> stacks}) _barParts(
    Map<String, dynamic> data,
  ) {
    final completed = _num(data["completed"]);
    final pending = _num(data["pending"]);
    final overdue = math.min(_num(data["overdue"]), math.max(pending, 0)).toDouble();
    final waiting = math.max(0, pending - overdue).toDouble();
    final stacks = <BarChartRodStackItem>[];
    var cursor = 0.0;

    void add(double amount, Color color) {
      if (amount <= 0) return;
      stacks.add(BarChartRodStackItem(cursor, cursor + amount, color));
      cursor += amount;
    }

    add(completed, TaskUtils.getStatusColor(TaskStatus.completed));
    add(waiting, TaskUtils.getStatusColor(TaskStatus.pending));
    add(overdue.toDouble(), Colors.red);
    return (height: cursor, stacks: stacks);
  }

  List<BarChartGroupData> _generateBarGroups(List departments) {
    return List.generate(departments.length, (index) {
      final dept = departments[index] is Map
          ? Map<String, dynamic>.from(departments[index])
          : <String, dynamic>{};
      final parts = _barParts(_chartSection(dept));
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: parts.height,
            width: 8,
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade300,
            rodStackItems: parts.stacks,
          ),
        ],
      );
    });
  }
}
