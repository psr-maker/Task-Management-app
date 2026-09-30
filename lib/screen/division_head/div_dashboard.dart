import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/division_head/div_compensation.dart';
import 'package:staff_work_track/screen/division_head/div_leave_management.dart';
import 'package:staff_work_track/screen/division_head/div_overtime.dart';
import 'package:staff_work_track/screen/division_head/drawer/div_auditlog.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/points.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/usersworklog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/utils/work_performance.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class DivDashboard extends StatefulWidget {
  final String department;
  final int userId;
  final String role;

  const DivDashboard({
    super.key,
    required this.department,
    required this.userId,
    required this.role,
  });

  @override
  State<DivDashboard> createState() => _DivDashboardState();
}

class _DivDashboardState extends State<DivDashboard> {
  late Future<Map<String, dynamic>> reportFuture;
  int selectedType = 0;
  bool isDivisionView = true;
  List<String> childDepartments = [];
  bool _departmentsLoading = true;
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
      department: widget.department,
      departments: childDepartments,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    List<String> names = [];
    try {
      names = await AdminService.getMySubDepartments();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      childDepartments = names;
      _departmentsLoading = false;
    });
    _fetchReport();
  }

  void _fetchReport() {
    final now = DateTime.now();
    reportFuture = ReportsService.fetchDivisionReport(
      childDepartments,
      fromDate: DateTime(now.year, 1, 1),
      toDate: DateTime(now.year, 12, 31, 23, 59, 59),
    );
    _loadTaskTiming(now.year);
  }

  Future<void> _loadTaskTiming(int year) async {
    final timing = await TaskTiming.loadDepartments(
      childDepartments,
      year: year,
    );
    if (!mounted) return;
    setState(() => taskTiming = timing);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!isDivisionView) {
      return StaffDashboard(
        userid: widget.userId,
        role: widget.role,
        backToLabel: "Division Dashboard",
        onBackToManager: () {
          setState(() => isDivisionView = true);
        },
      );
    }

    final isWeb = !AppLayout.isMobile(context);
    bindWebHeader(
      context,
      onReports: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportsTable(department: widget.department),
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
        title: const Text("Division Head"),
        actions: [
               
               
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
      body: _departmentsLoading
          ? const Center(child: RotatingFlower())
          : childDepartments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No departments are mapped under this division.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : FutureBuilder<Map<String, dynamic>>(
              future: reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: RotatingFlower());
                }
                if (snapshot.hasError) {
                  return const AppLoadError();
                }
                final data = snapshot.data ?? {};
                final departmentData = List<Map<String, dynamic>>.from(
                  data["departmentData"] ?? [],
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_fetchReport);
                    await reportFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppLayout.pagePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWeb)
                          WebPageHeader(
                            title: widget.department.isEmpty
                                ? "Division Overview"
                                : "${widget.department} Overview",
                            subtitle:
                                'Goals, tasks and department performance',
                          )
                        else
                          Text(
                            widget.department.isEmpty
                                ? "Division Overview"
                                : "${widget.department} Overview",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        const SizedBox(height: 10),
                        WebResponsiveRow(
                          minChildWidth: 180,
                          children: [
                            SmallStatCard(
                              title: "Total Users",
                              value: (data["totalUsers"] ?? 0).toString(),
                              icon: Icons.people,
                              color: Colors.brown,
                              onTap: () => _openList(
                                DashboardListKind.staff,
                                "Total Users",
                              ),
                            ),
                            SmallStatCard(
                              title: "Total Department",
                              value: (data["totalDepartments"] ??
                                      childDepartments.length)
                                  .toString(),
                              icon: Icons.apartment,
                              color: Theme.of(context).colorScheme.secondary,
                              onTap: () => _openList(
                                DashboardListKind.departments,
                                "Departments",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Goal Summary",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        WebResponsiveRow(
                          minChildWidth: 160,
                          children: [
                            SmallStatCard(
                              title: "Completed Goal",
                              value: (data["completedGoals"] ?? 0).toString(),
                              icon: Icons.check_circle_outlined,
                              color: Colors.green,
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Completed Goals",
                                filter: WorkStatusFilter.completed,
                              ),
                            ),
                            SmallStatCard(
                              title: "Pending Goal",
                              value: (data["pendingGoals"] ?? 0).toString(),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Pending Goals",
                                filter: WorkStatusFilter.pending,
                              ),
                            ),
                            SmallStatCard(
                              title: "Overdue Goal",
                              value: (data["overdueGoals"] ?? 0).toString(),
                              icon: Icons.error_outline,
                              color: Colors.red,
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Overdue Goals",
                                filter: WorkStatusFilter.overdue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Task Summary",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        WebResponsiveRow(
                          minChildWidth: 160,
                          children: [
                            SmallStatCard(
                              title: "Completed Tasks",
                              value: (data["completedTasks"] ?? 0).toString(),
                              icon: Icons.task_outlined,
                              color: Colors.teal,
                              onTap: () => _openList(
                                DashboardListKind.tasks,
                                "Completed Tasks",
                                filter: WorkStatusFilter.completed,
                              ),
                            ),
                            SmallStatCard(
                              title: "Pending Tasks",
                              value: (data["pendingTasks"] ?? 0).toString(),
                              icon: Icons.pending_outlined,
                              color: const Color.fromARGB(255, 235, 211, 0),
                              onTap: () => _openList(
                                DashboardListKind.tasks,
                                "Pending Tasks",
                                filter: WorkStatusFilter.pending,
                              ),
                            ),
                            SmallStatCard(
                              title: "Overdue Tasks",
                              value: (data["overdueTasks"] ?? 0).toString(),
                              icon: Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              onTap: () => _openList(
                                DashboardListKind.tasks,
                                "Overdue Tasks",
                                filter: WorkStatusFilter.overdue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Overall Performance Overview",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 15),
                        WebResponsiveRow(
                          minChildWidth: 180,
                          children: [
                            KpiCircleCard(
                              title: "Completion %",
                              goalPercent: ringPercent(
                                data["totalGoals"],
                                _toDouble(data["goalCompletionPercentage"]),
                              ),
                              taskPercent: ringPercent(
                                data["totalTasks"],
                                completionPercent(
                                  data["completedTasks"],
                                  data["totalTasks"],
                                ),
                              ),
                              onTap: () => _openList(
                                DashboardListKind.goals,
                                "Completed Goals",
                                filter: WorkStatusFilter.completed,
                              ),
                            ),
                            KpiCircleCard(
                              title: "On-Time %",
                              goalPercent: ringPercent(
                                data["totalGoals"],
                                _toDouble(
                                  data["onTimeGoalCompletionPercentage"],
                                ),
                              ),
                              taskPercent: ringPercent(
                                data["totalTasks"],
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
                                data["totalGoals"],
                                _toDouble(data["delayedGoalPercentage"]),
                              ),
                              taskPercent: ringPercent(
                                data["totalTasks"],
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
                        if (departmentData.isNotEmpty) ...[
                          Text(
                            "All Department Performance",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 15),
                          _buildToggle(),
                          const SizedBox(height: 15),
                          _buildDepartmentChart(departmentData),
                          const SizedBox(height: 20),
                        ],
                       // Alldeptproducticity(departments: childDepartments),
                      ],
                    ),
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
        icon: Icons.insights_rounded,
        label: 'Productivity Score',
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
        onTap: () => open(BehaviourScoreDisplay(Dept: widget.department)),
      ),
      WebMenuItem(
        icon: Icons.work_history_rounded,
        label: 'Work Logs',
        group: 'Work Management',
        onTap: () => open(
          UsersWorklog(
            allowedDepartments: [
              if (widget.department.isNotEmpty) widget.department,
              ...childDepartments,
            ],
          ),
        ),
      ),
      WebMenuItem(
        icon: Icons.event_available_rounded,
        label: 'Leave / Permission',
        group: 'Requests',
        onTap: () => open(DivLeaveManagement(department: widget.department)),
      ),
      WebMenuItem(
        icon: Icons.event_repeat_rounded,
        label: 'Compensation Work',
        group: 'Requests',
        onTap: () => open(DivCompensation(department: widget.department)),
      ),
      WebMenuItem(
        icon: Icons.schedule_rounded,
        label: 'Overtime',
        group: 'Requests',
        onTap: () => open(DivOvertime(department: widget.department)),
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
        onTap: () => open(DivAuditLog(department: widget.department)),
      ),
      WebMenuItem(
        icon: Icons.person_outline_rounded,
        label: 'My Profile',
        group: 'Profile',
        onTap: () => setState(() => isDivisionView = false),
      ),
    ];
  }

  Widget _buildDrawer(BuildContext context) {
    final department = widget.department.trim();
    return AppMenuDrawer(
      title: 'Division Head',
      subtitle: department.isEmpty ? 'Division panel' : department,
      icon: Icons.account_tree_rounded,
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
        onTap: () => setState(() => selectedType = index),
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
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: _generateBarGroups(departments),
              maxY: _getMaxChartValue(departments),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
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
                      final chartData = selectedType == 0
                          ? dept["tasks"]
                          : dept["goals"];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          (chartData["total"] ?? 0).toString(),
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
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dept = departments[groupIndex];
                    final chartData = selectedType == 0
                        ? dept["tasks"]
                        : dept["goals"];
                    final title = selectedType == 0 ? "Task" : "Goal";
                    return BarTooltipItem(
                      "${dept["department"]}\n\n"
                      "Total $title: ${chartData["total"] ?? 0}\n"
                      "Completed: ${chartData["completed"] ?? 0}\n"
                      "Pending: ${chartData["pending"] ?? 0}\n"
                      "Overdue: ${chartData["overdue"] ?? 0}",
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxChartValue(List departments) {
    if (departments.isEmpty) return 10;
    double maxValue = 0;
    for (final dept in departments) {
      final chartData = selectedType == 0 ? dept["tasks"] : dept["goals"];
      final total =
          _toDouble(chartData["completed"]) +
          _toDouble(chartData["pending"]) +
          _toDouble(chartData["overdue"]);
      if (total > maxValue) maxValue = total;
    }
    return maxValue == 0 ? 10 : maxValue * 1.2;
  }

  List<BarChartGroupData> _generateBarGroups(List departments) {
    return List.generate(departments.length, (index) {
      final dept = departments[index];
      final chartData = selectedType == 0 ? dept["tasks"] : dept["goals"];
      final completed = _toDouble(chartData["completed"]);
      final pending = _toDouble(chartData["pending"]);
      final overdue = _toDouble(chartData["overdue"]);
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
