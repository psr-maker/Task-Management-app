import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/deptwarnings.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/company/leavlist_hr.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/company/punchclist_account.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/dept_compensation.dart/compen_list.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/overtime/manage_overtime.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/punchdeptlist.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffleaves.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffworklog.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task_member_rmvlst.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/points.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/widgets/StatCard.dart';
import 'package:staff_work_track/widgets/monthlytrend.dart';
import 'package:staff_work_track/utils/work_performance.dart';
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
  TaskTiming taskTiming = TaskTiming.empty;
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;
  int apiWarningCount = 0;
  int notificationCount = 0;
  List<WarningModel> apiWarnings = [];
  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];
  bool showSwitch = false;
  bool isManagerView = true;

  List<Map<String, dynamic>> _reportList(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is! List || value.isEmpty) continue;
      return [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    }
    return [];
  }

  int _count(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

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
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchReport();
    loadData();
    _fetchWarnings();
    // _fetchNotifications();
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
    _loadTaskTiming();
  }

  Future<void> _loadTaskTiming() async {
    final timing = await TaskTiming.load(
      department: widget.department,
      year: selectedYear.year,
    );
    if (!mounted) return;
    setState(() => taskTiming = timing);
  }

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
    final isWeb = !AppLayout.isMobile(context);
    bindWebHeader(
      context,
      overdueCount: overdueTaskCount + overdueGoalCount + apiWarningCount,
      onOverdue: () {
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
      appBar: isWeb || !isManagerView
          ? null
          : AppBar(
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
            ),
      body: isManagerView
          ? FutureBuilder<Map<String, dynamic>>(
              future: reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: RotatingFlower());
                }
                if (snapshot.hasError) {
                  return const AppLoadError();
                }
                final data = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  setState(() {
                    overdueTaskList = _reportList(data, const [
                      "overdueTasksList",
                      "overdueTaskslist",
                      "overdueTaskList",
                    ]);
                    overdueGoalList = _reportList(data, const [
                      "overdueGoalsList",
                      "overdueGoalslist",
                      "overdueGoalList",
                    ]);
                    overdueTaskCount = overdueTaskList.isNotEmpty
                        ? overdueTaskList.length
                        : _count(data["overdueTasks"]);
                    overdueGoalCount = overdueGoalList.isNotEmpty
                        ? overdueGoalList.length
                        : _count(data["overdueGoals"]);
                  });
                });
                final monthlyData = (this.data?["monthlyData"] as List? ?? []);
                return SingleChildScrollView(
                  padding: AppLayout.pagePadding(context),
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
                          WebResponsiveRow(
                            minChildWidth: 160,
                            children: [
                              SmallStatCard(
                                title: "Total Staff",
                                value: (data["totalUsers"] ?? 0).toString(),
                                icon: Icons.task_outlined,
                                color: Colors.brown,
                                onTap: () => _openList(
                                  DashboardListKind.staff,
                                  "Total Staff",
                                ),
                              ),
                              SmallStatCard(
                                title: "Total Goal",
                                value: (data["totalGoals"] ?? 0).toString(),
                                icon: Icons.check_circle_outlined,
                                color: Colors.deepPurple,
                                onTap: () => _openList(
                                  DashboardListKind.goals,
                                  "Total Goals",
                                ),
                              ),
                              SmallStatCard(
                                title: "Total Task",
                                value: (data["totalTasks"] ?? 0).toString(),
                                icon: Icons.check_circle_outlined,
                                color: Colors.blue,
                                onTap: () => _openList(
                                  DashboardListKind.tasks,
                                  "Total Tasks",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          WebResponsiveRow(
                            minChildWidth: 160,
                            children: [
                              SmallStatCard(
                                title: "Completed Goal",
                                value: (data["completedGoals"] ?? 0).toString(),
                                icon: Icons.task_outlined,
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
                                icon: Icons.check_circle_outlined,
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
                                icon: Icons.pending_outlined,
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
                                icon: Icons.check_circle_outlined,
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
                                icon: Icons.pending_outlined,
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
                            "Performance Overview",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 10),
                          WebResponsiveRow(
                            minChildWidth: 180,
                            children: [
                              KpiCircleCard(
                                title: "Completion %",
                                goalPercent: ringPercent(
                                  data["totalGoals"],
                                  (data["goalCompletionPercentage"] ?? 0)
                                      .toDouble(),
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
                                title: "On-Time Completion%",
                                goalPercent: ringPercent(
                                  data["totalGoals"],
                                  (data["onTimeGoalCompletionPercentage"] ?? 0)
                                      .toDouble(),
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
                                  (data["delayedGoalPercentage"] ?? 0)
                                      .toDouble(),
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
                          WebPanel.wrap(
                            context,
                            ProductivityBarChart(
                              data: monthlyData.map((e) {
                                return {
                                  "month": e["month"] ?? 0,
                                  "taskPoints": e["taskPoints"] ?? 0,
                                  "goalPoints": e["goalPoints"] ?? 0,
                                  "attitudeScore": e["attitudeScore"] ?? 0,
                                  "fiveS": e["fiveS"] ?? 0,
                                  "productivity": e["productivity"] ?? 0,
                                  "totalscore": e["totalScore"] ?? 0,
                                };
                              }).toList(),
                            ),
                          ),
                          // _buildPerformanceSection(data),
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

  List<WebMenuItem> _sidebarMenu() {
    void open(Widget page) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    final bool isAccountsManager =
        widget.department.trim() == "Accounts Department" &&
        widget.role.toString() == "3";
    final bool isHRManager =
        widget.department.trim() == "HR Department" &&
        widget.role.toString() == "3";

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
        onTap: () => open(const Staffworklog()),
      ),
      WebMenuItem(
        icon: Icons.event_available_rounded,
        label: 'Leave / Permission',
        group: 'Requests',
        onTap: () => open(const StaffLeaves()),
      ),
      WebMenuItem(
        icon: Icons.edit_calendar_rounded,
        label: 'Attendance Correction',
        group: 'Requests',
        onTap: () => open(const PunchCorrdeptlist()),
      ),
      WebMenuItem(
        icon: Icons.more_time_rounded,
        label: 'Compensation Work',
        group: 'Requests',
        onTap: () => open(ExtraWorkPage(deptt: widget.department)),
      ),
      WebMenuItem(
        icon: Icons.schedule_rounded,
        label: 'Overtime',
        group: 'Requests',
        onTap: () => open(ManagerOvertime(dept: widget.department)),
      ),
      WebMenuItem(
        icon: Icons.campaign_rounded,
        label: 'Announcements',
        group: 'Communication',
        onTap: () => open(const Anounce()),
      ),
      WebMenuItem(
        icon: Icons.assignment_late_rounded,
        label: 'Task Penalty',
        group: 'Administration',
        onTap: () => open(const TaskRemovalRequest()),
      ),
      WebMenuItem(
        icon: Icons.manage_search_rounded,
        label: 'Audit Logs',
        group: 'Administration',
        onTap: () => open(const AuditLogPage()),
      ),
      if (isAccountsManager) ...[
        WebMenuItem(
          icon: Icons.fact_check_rounded,
          label: 'Attendance Reports',
          group: 'Administration',
          onTap: () => open(PunchCompany(managerId: widget.mngId)),
        ),
        WebMenuItem(
          icon: Icons.event_note_rounded,
          label: 'Leave Reports',
          group: 'Administration',
          onTap: () => open(const HrLeaves()),
        ),
      ],
      if (isHRManager)
        WebMenuItem(
          icon: Icons.event_note_rounded,
          label: 'Leave Reports',
          group: 'Administration',
          onTap: () => open(const HrLeaves()),
        ),
      WebMenuItem(
        icon: Icons.person_outline_rounded,
        label: 'My Profile',
        group: 'Profile',
        onTap: () {
          _showSwitchContainer();
          setState(() => isManagerView = false);
        },
      ),
    ];
  }

  Widget _buildDrawer(BuildContext context) {
    final subtitle = widget.department.trim().isEmpty
        ? 'Manager Panel'
        : widget.department.trim();
    return AppMenuDrawer(
      title: 'Manager',
      subtitle: subtitle,
      icon: Icons.dashboard_rounded,
      items: _sidebarMenu(),
    );
  }
}
