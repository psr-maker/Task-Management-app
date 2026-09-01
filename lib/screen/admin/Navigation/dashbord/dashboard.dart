import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/deptwarnings.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/5spoints.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/company/leavlist_hr.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/company/punchclist_account.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/deptovertime.dart';
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
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/notifi.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/services/announ_service.dart';
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

  // void _fetchNotifications() async {
  //   try {
  //     final data = await NotificationService.getMyNotifications();
  //     if (!mounted) return;
  //     setState(() {
  //       notificationCount = data.where((n) => n["isRead"] == false).length;
  //     });
  //   } catch (e) {
  //     print("Notification fetch error: $e");
  //   }
  // }

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
                    //    _fetchNotifications();
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
                                isPercentage: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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

    final bool isAccountsManager =
        widget.department.trim() == "Accounts Department" &&
        widget.role.toString() == "2";
    final bool isHRManager =
        widget.department.trim() == "HR Department" &&
        widget.role.toString() == "2";

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

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                  _buildDrawerItem(
                  context,
                  icon: Icons.task_alt_rounded,
                  title: "Score Calculation",
                  onTap: () {
                    Navigator.pop(context);

                   Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductivityCalculationPage()),
              );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.task_alt_rounded,
                  title: "Task Performance",
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
                  icon: Icons.psychology_rounded,
                  title: "Behaviour & Attitude",
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BehaviourScoreDisplay(Dept: widget.department),
                      ),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.event_available_rounded,
                  title: "Leave Management",
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
                  icon: Icons.edit_calendar_rounded,
                  title: "Attendance Corrections",
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PunchCorrdeptlist()),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.more_time_rounded,
                  title: "Overtime",
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
                  icon: Icons.work_history_rounded,
                  title: "Work Logs",
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
                  icon: Icons.campaign_rounded,
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
                  icon: Icons.checklist_rounded,
                  title: "5S Performance",
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
                  icon: Icons.assignment_late_rounded,
                  title: "Task Removal Penalties",
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TaskRemovalRequest()),
                    );
                  },
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.manage_search_rounded,
                  title: "Audit Log",
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AuditLogPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          if (isAccountsManager) ...[
            const Divider(height: 1),

            _buildDrawerItem(
              context,
              icon: Icons.fact_check_rounded,
              title: "Attendance Reports",
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PunchCompany(managerId: widget.mngId),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              context,
              icon: Icons.event_note_rounded,
              title: "Leave Reports",
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HrLeaves(),
                  ),
                );
              },
            ),
          ],
          if (isHRManager) ...[
            const Divider(height: 1),

            _buildDrawerItem(
              context,
              icon: Icons.event_note_rounded,
              title: "Leave Reports",
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HrLeaves(),
                  ),
                );
              },
            ),
          ],

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.dashboard_customize_rounded),
            title: Text(
              "My Dashboard",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
