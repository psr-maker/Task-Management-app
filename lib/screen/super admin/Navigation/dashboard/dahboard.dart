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
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/services/notification_service.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchWarnings();
    _fetchNotifications();
    dashboard = loadDashboard();
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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  Future<Map<String, dynamic>> loadDashboard() async {
    try {
      var data = await _service.getDashboardSummary();
      return data;
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.amber),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationPage()),
                  );
                  //  _fetchNotifications();
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
        future: dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RotatingFlower());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final data = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              overdueTaskList = List<Map<String, dynamic>>.from(
                data["overdueTaskslist"] ?? [],
              );
              overdueGoalList = List<Map<String, dynamic>>.from(
                data["overdueGoalsList"] ?? [],
              );
              overdueTaskCount = overdueTaskList.length;
              overdueGoalCount = overdueGoalList.length;
            });
          });
          final tasks = data["tasks"] ?? {};
          final goals = data["goals"] ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Managers",
                        value: data["totalManagers"].toString(),
                        icon: Icons.person,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Staff's",
                        value: data["totalStaff"].toString(),
                        icon: Icons.people,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Departments",
                        value: data["totalDepartments"].toString(),
                        icon: Icons.apartment,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Goal & Task Summary",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SmallStatCard(
                        title: "Total Goals",
                        value: goals["total"].toString(),
                        icon: Icons.flag,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Completed",
                        value: goals["completed"].toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending",
                        value: goals["pending"].toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue",
                        value: goals["overdue"].toString(),
                        icon: Icons.error,
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
                        title: "Total Tasks",
                        value: tasks["total"].toString(),
                        icon: Icons.list_alt,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Completed",
                        value: tasks["completed"].toString(),
                        icon: Icons.check_circle,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Pending",
                        value: tasks["pending"].toString(),
                        icon: Icons.pending,
                        color: const Color.fromARGB(255, 235, 211, 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SmallStatCard(
                        title: "Overdue",
                        value: tasks["overdue"].toString(),
                        icon: Icons.warning,
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
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: KpiCircleCard(
                        title: "Completion %",
                        value: _toDouble(goals["completionPercentage"]),
                        icon: Icons.verified_outlined,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiCircleCard(
                        title: "On-Time Completed %",
                        value: _toDouble(goals["onTimeCompletionPercentage"]),
                        icon: Icons.timelapse_rounded,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiCircleCard(
                        title: "Delayed %",
                        value: _toDouble(goals["delayedPercentage"]),
                        icon: Icons.access_time_rounded,
                        isPercentage: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Department Performance",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 15),
                _buildToggle(),
                const SizedBox(height: 15),
                _buildDepartmentChart(data["departmentData"]),
                const SizedBox(height: 20),
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
                  final data = selectedType == 0
                      ? dept["tasks"]
                      : dept["goals"];
                  final total = (data["total"] ?? 0).toString();
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
                      style: Theme.of(context).textTheme.headlineSmall,
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
                final data = selectedType == 0 ? dept["tasks"] : dept["goals"];
                final completed = data["completed"] ?? 0;
                final pending = data["pending"] ?? 0;
                final overdue = data["overdue"] ?? 0;
                final total = data["total"] ?? 0;
                final title = selectedType == 0 ? "Task" : "Goal";
                return BarTooltipItem(
                  "${dept["department"]}\n\n"
                  "Total $title: $total\n"
                  "Completed: $completed\n"
                  "Pending: $pending\n"
                  "Overdue: $overdue",
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
      final data = selectedType == 0 ? dept["tasks"] : dept["goals"];
      final completed = (data["completed"] ?? 0).toDouble();
      final pending = (data["pending"] ?? 0).toDouble();
      final overdue = (data["overdue"] ?? 0).toDouble();
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
