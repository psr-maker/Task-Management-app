import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/dept_compensation.dart/compen_list.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffleaves.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/points.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/usersworklog.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/TaskUtils.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/kpicard.dart';

class DivDashboard extends StatefulWidget {
  final String department;

  const DivDashboard({
    super.key,
    required this.department,
  });

  @override
  State<DivDashboard> createState() => _DivDashboardState();
}

class _DivDashboardState extends State<DivDashboard> {
  late Future<Map<String, dynamic>> reportFuture;
  int selectedType = 0;

  List<String> get childDepartments =>
      DivisionConfig.childDepartments(widget.department);

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() {
    final now = DateTime.now();
    reportFuture = ReportsService.fetchDivisionReport(
      childDepartments,
      fromDate: DateTime(now.year, 1, 1),
      toDate: DateTime(now.year, 12, 31, 23, 59, 59),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("Division Head"),
      ),
      body: childDepartments.isEmpty
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
                  return Center(child: Text("Error: ${snapshot.error}"));
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
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.department.isEmpty
                              ? "Division Overview"
                              : "${widget.department} Overview",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SmallStatCard(
                                title: "Total Users",
                                value: (data["totalUsers"] ?? 0).toString(),
                                icon: Icons.people,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SmallStatCard(
                                title: "Total Department",
                                value: (data["totalDepartments"] ??
                                        childDepartments.length)
                                    .toString(),
                                icon: Icons.apartment,
                                color: Theme.of(context).colorScheme.secondary,
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
                        Row(
                          children: [
                            Expanded(
                              child: SmallStatCard(
                                title: "Completed Goal",
                                value: (data["completedGoals"] ?? 0).toString(),
                                icon: Icons.check_circle_outlined,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SmallStatCard(
                                title: "Pending Goal",
                                value: (data["pendingGoals"] ?? 0).toString(),
                                icon: Icons.pending_actions,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SmallStatCard(
                                title: "Overdue Goal",
                                value: (data["overdueGoals"] ?? 0).toString(),
                                icon: Icons.error_outline,
                                color: Colors.red,
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
                        Row(
                          children: [
                            Expanded(
                              child: SmallStatCard(
                                title: "Completed Tasks",
                                value: (data["completedTasks"] ?? 0).toString(),
                                icon: Icons.task_outlined,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SmallStatCard(
                                title: "Pending Tasks",
                                value: (data["pendingTasks"] ?? 0).toString(),
                                icon: Icons.pending_outlined,
                                color: const Color.fromARGB(255, 235, 211, 0),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SmallStatCard(
                                title: "Overdue Tasks",
                                value: (data["overdueTasks"] ?? 0).toString(),
                                icon: Icons.warning_amber_rounded,
                                color: Colors.redAccent,
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
                        Row(
                          children: [
                            Expanded(
                              child: KpiCircleCard(
                                title: "Completion %",
                                value: _toDouble(
                                  data["goalCompletionPercentage"],
                                ),
                                icon: Icons.verified_outlined,
                                isPercentage: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: KpiCircleCard(
                                title: "On-Time %",
                                value: _toDouble(
                                  data["onTimeGoalCompletionPercentage"],
                                ),
                                icon: Icons.timelapse_rounded,
                                isPercentage: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: KpiCircleCard(
                                title: "Delayed %",
                                value: _toDouble(data["delayedGoalPercentage"]),
                                icon: Icons.access_time_rounded,
                                isPercentage: true,
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(color: theme.colorScheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Icon(
                  Icons.account_tree_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  "Division Head Panel",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (widget.department.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.department,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                _buildDrawerItem(
                  icon: Icons.task_alt_rounded,
                  title: "Score Calculation",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductivityCalculationPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.event_available_rounded,
                  title: "Leave Management",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StaffLeaves()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.more_time_rounded,
                  title: "Compensation Leave",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExtraWorkPage(deptt: widget.department),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.work_history_rounded,
                  title: "Worklogs",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UsersWorklog(
                          allowedDepartments: childDepartments,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.campaign_rounded,
                  title: "Announcements",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Anounce()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.manage_search_rounded,
                  title: "Auditlog",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditLogPage(
                          allowedDepartments: [
                            if (widget.department.isNotEmpty)
                              widget.department,
                            ...childDepartments,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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
