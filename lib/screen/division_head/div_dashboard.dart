import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/theme/theme_provider.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/staff_warnings.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/manager_report.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/division_head/div_compensation.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/screen/division_head/div_leave_management.dart';
import 'package:staff_work_track/screen/division_head/div_users.dart';
import 'package:staff_work_track/screen/division_head/drawer/div_auditlog.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/dashboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/department_dashboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/points.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/usersworklog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/work_performance.dart';

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
  Future<Map<String, dynamic>>? dashboard;
  DateTime selectedYear = DateTime.now();
  int selectedMonth = DateTime.now().month <= 1 ? 12 : DateTime.now().month - 1;
  bool isDivisionView = true;
  List<String> childDepartments = [];
  bool _departmentsLoading = true;
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;
  int apiWarningCount = 0;
  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];

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
    final now = DateTime.now();
    if (now.month == 1) {
      selectedYear = DateTime(now.year - 1);
      selectedMonth = 12;
    }
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    List<String> names = [];
    final own = widget.department.trim();
    try {
      names = await AdminService.getMySubDepartments(
        headDepartment: own.isEmpty ? null : own,
      );
    } catch (_) {}
    if (names.isEmpty && own.isNotEmpty) names = [own];
    if (!mounted) return;
    setState(() {
      childDepartments = names;
      _departmentsLoading = false;
      if (names.isNotEmpty) dashboard = _loadDashboard();
    });
  }

  Future<void> _pickYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedYear,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      selectedYear = picked;
      final now = DateTime.now();
      selectedMonth = picked.year == now.year
          ? (now.month <= 1 ? 1 : now.month - 1)
          : 12;
      dashboard = _loadDashboard();
    });
  }

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsTable(department: widget.department),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Settings()),
    );
  }

  List<String> _warningDepartments() {
    return [
      if (widget.department.trim().isNotEmpty) widget.department,
      ...childDepartments,
    ];
  }

  StaffWarningsPage _warningsPage() {
    return StaffWarningsPage(
      userId: widget.userId,
      departmentScope: true,
      department: widget.department,
      filterDepartments: _warningDepartments(),
    );
  }

  void _openWarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _warningsPage()),
    );
  }

  Future<void> _fetchWarnings() async {
    try {
      final warnings = await AnnouncementService.getWarnings();
      final allowed = _warningDepartments();
      final count = warnings.where((WarningModel item) {
        return allowed.any(
          (name) => DivisionConfig.isAllowedDepartment(item.receiverDept, [name]),
        );
      }).length;
      if (!mounted) return;
      setState(() => apiWarningCount = count);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    final year = selectedYear.year;
    _fetchWarnings();
    final division = await ReportsService.fetchDivisionReport(
      childDepartments,
      fromDate: DateTime(year, 1, 1),
      toDate: DateTime(year, 12, 31, 23, 59, 59),
    );
    final results = await Future.wait([
      _loadScores(year),
      TaskTiming.loadDepartments(childDepartments, year: year),
      _scopedUserCount(),
      _loadDueSoon(),
    ]);
    final scores = results[0] as Map<String, dynamic>;
    final monthly = scores['monthly'] as List? ?? const [];
    final departments = scores['departments'] as List? ?? const [];
    final timing = results[1] as TaskTiming;
    final userCount = results[2] as int?;
    final dueSoon = results[3] as ({int goals, int tasks});
    final tasks = _mapList(
      division['overdueTasksList'] ??
          division['overdueTaskslist'] ??
          division['OverdueTasksList'] ??
          division['overdueTaskList'],
    );
    final goals = _mapList(
      division['overdueGoalsList'] ??
          division['overdueGoalslist'] ??
          division['OverdueGoalsList'] ??
          division['overdueGoalList'],
    );
    final overdueTasks = tasks.isNotEmpty
        ? tasks.length
        : _int(division['overdueTasks'] ?? division['OverdueTasks']);
    final overdueGoals = goals.isNotEmpty
        ? goals.length
        : _int(division['overdueGoals'] ?? division['OverdueGoals']);
    final totalTasks = _int(division['totalTasks']);
    final completedTasks = _int(division['completedTasks']);
    final summary = {
      ...division,
      'overdueTasks': overdueTasks,
      'overdueGoals': overdueGoals,
      if (userCount != null) 'totalUsers': userCount,
      if (totalTasks > 0)
        'taskCompletionPercentage': completedTasks / totalTasks * 100,
      'onTimeTaskCompletionPercentage': ?timing.onTime,
      'delayedTaskPercentage': ?timing.delayed,
    };
    if (!mounted) {
      return {
        'summary': summary,
        'monthly': monthly,
        'departments': departments,
      };
    }
    setState(() {
      overdueTaskList = tasks;
      overdueGoalList = goals;
      overdueTaskCount = overdueTasks;
      overdueGoalCount = overdueGoals;
    });
    return {
      'summary': summary,
      'monthly': monthly,
      'departments': departments,
      'dueSoonGoals': dueSoon.goals,
      'dueSoonTasks': dueSoon.tasks,
    };
  }

  Future<({int goals, int tasks})> _loadDueSoon() async {
    try {
      final results = await Future.wait([
        loadWorkItems(
          kind: DashboardListKind.goals,
          filter: WorkStatusFilter.dueSoon,
          departments: childDepartments,
        ),
        loadWorkItems(
          kind: DashboardListKind.tasks,
          filter: WorkStatusFilter.dueSoon,
          departments: childDepartments,
        ),
      ]);
      return (goals: results[0].length, tasks: results[1].length);
    } catch (error) {
      debugPrint('Division due soon: $error');
      return (goals: 0, tasks: 0);
    }
  }

  Future<int?> _scopedUserCount() async {
    try {
      final users = await AdminService.getEmployeesByDepartments(
        childDepartments,
      );
      return users.length;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadScores(int year) async {
    const keys = [
      'totalScore',
      'productivity',
      'goalPoints',
      'taskPoints',
      'attitudeScore',
      'fiveS',
    ];
    final results = await Future.wait(
      childDepartments.map((department) async {
        try {
          final report = await ReportsService.getdeptMonthlyProductivity(
            department,
            year,
          );
          final raw = report['monthlyData'] ?? report['MonthlyData'];
          if (raw is! List) return <Map<String, dynamic>>[];
          return [
            for (final item in raw)
              if (item is Map) Map<String, dynamic>.from(item),
          ];
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      }),
    );
    final buckets = <int, Map<String, List<double>>>{};
    for (final rows in results) {
      for (final row in rows) {
        final month = _int(row['month'] ?? row['Month']);
        if (month < 1 || month > 12) continue;
        final bag = buckets.putIfAbsent(month, () => {});
        for (final key in keys) {
          final value = row[key] ?? row['${key[0].toUpperCase()}${key.substring(1)}'];
          if (value == null) continue;
          (bag[key] ??= []).add(_num(value));
        }
      }
    }
    final months = buckets.keys.toList()..sort();
    return {
      'monthly': [
        for (final month in months)
          {
            'month': month,
            for (final key in keys)
              if ((buckets[month]?[key] ?? []).isNotEmpty)
                key: buckets[month]![key]!.reduce((a, b) => a + b) /
                    buckets[month]![key]!.length,
          },
      ],
      'departments': [
        for (var i = 0; i < childDepartments.length; i++)
          {
            'department': childDepartments[i],
            'monthlyData': results[i],
          },
      ],
    };
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  void _keepRoleTheme() {
    context.read<ThemeProvider>().applyRole(widget.role);
  }

  void _openProfile() {
    _keepRoleTheme();
    if (!isDivisionView) return;
    setState(() => isDivisionView = false);
  }

  void _backToDivision() {
    _keepRoleTheme();
    WebShellScope.maybeOf(context)?.update(clearSelection: true);
    setState(() => isDivisionView = true);
  }

  String get _divisionName {
    final name = widget.department.trim();
    return name.isEmpty ? 'Division' : name;
  }

  void _openUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DivUsers(
          department: widget.department,
          showAppBar: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnings = apiWarningCount;
    if (!isDivisionView) {
      return StaffDashboard(
        userid: widget.userId,
        role: widget.role,
        backToLabel: 'Back to dashboard',
        replaceShellMenu: true,
        onBackToManager: _backToDivision,
      );
    }

    final isWeb = !AppLayout.isMobile(context);
    bindWebHeader(
      context,
      overdueCount: warnings,
      onOverdue: _openWarnings,
      onReports: _openReports,
      onSettings: _openSettings,
      menuItems: _sidebarMenu(),
    );

    return Scaffold(
      drawer: isWeb ? null : _buildDrawer(context),
      appBar: isWeb ? null : _mobileAppBar(),
      body: _departmentsLoading
          ? const Center(child: RotatingFlower())
          : childDepartments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No departments are mapped under this division.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : FutureBuilder<Map<String, dynamic>>(
              future: dashboard,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: RotatingFlower());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const AppLoadError();
                }
                final payload = snapshot.data!;
                final summary = payload['summary'] is Map
                    ? Map<String, dynamic>.from(payload['summary'] as Map)
                    : <String, dynamic>{};
                final monthly = payload['monthly'] is List
                    ? payload['monthly'] as List
                    : const [];
                final departmentSeries = payload['departments'] is List
                    ? [
                        for (final item in payload['departments'] as List)
                          if (item is Map) Map<String, dynamic>.from(item),
                      ]
                    : const <Map<String, dynamic>>[];
                return RefreshIndicator(
                  onRefresh: () async {
                    final next = _loadDashboard();
                    setState(() => dashboard = next);
                    await next;
                  },
                  child: ManagerReport(
                    department: _divisionName,
                    year: selectedYear.year,
                    month: selectedMonth,
                    summary: summary,
                    monthly: monthly,
                    roleLabel: 'Division Head',
                    scopedDepartments: childDepartments,
                    departmentSeries: departmentSeries,
                    onPickYear: _pickYear,
                    onSelectMonth: (value) =>
                        setState(() => selectedMonth = value),
                    onOpenReports: _openReports,
                    onOpenSettings: _openSettings,
                    onOpenUsers: _openUsers,
                    onOpenDepartment: (name) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DepartmentDashboardPage(department: name),
                        ),
                      );
                    },
                    onOpenStaff: (userId, role, name, department) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffDashboard(
                            userid: userId,
                            role: role,
                            personName: name,
                            personDepartment: department,
                            backToLabel: 'Back to dashboard',
                            onBackToManager: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    onOpenTasks: (title, filter) => _openList(
                      DashboardListKind.tasks,
                      title,
                      filter: filter,
                    ),
                    onOpenGoals: (title, filter) => _openList(
                      DashboardListKind.goals,
                      title,
                      filter: filter,
                    ),
                    warningCount: apiWarningCount,
                    dueSoonGoals: payload['dueSoonGoals'] is int
                        ? payload['dueSoonGoals'] as int
                        : 0,
                    dueSoonTasks: payload['dueSoonTasks'] is int
                        ? payload['dueSoonTasks'] as int
                        : 0,
                    onWarnings: _openWarnings,
                  ),
                );
              },
            ),
    );
  }

  PreferredSizeWidget _mobileAppBar() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final name = widget.department.trim().isEmpty
        ? 'Division overview'
        : widget.department.trim();
    return AppBar(
      backgroundColor: WebTheme.isDark(context) ? WebTheme.darkHeader : WebTheme.brand,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 64,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Division Head',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<int>(
          onSelected: (value) => setState(() => selectedMonth = value),
          itemBuilder: (context) => [
            for (var month = 1; month <= 12; month++)
              PopupMenuItem(value: month, child: Text(months[month - 1])),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              months[selectedMonth.clamp(1, 12) - 1],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        InkWell(
          onTap: _pickYear,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${selectedYear.year}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Warnings',
          visualDensity: VisualDensity.compact,
          onPressed: _openWarnings,
          icon: Badge(
            isLabelVisible: apiWarningCount > 0,
            label: Text('$apiWarningCount'),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFC107),
              size: 22,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Reports',
          visualDensity: VisualDensity.compact,
          onPressed: _openReports,
          icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
        ),
        IconButton(
          tooltip: 'Settings',
          visualDensity: VisualDensity.compact,
          onPressed: _openSettings,
          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  List<WebMenuItem> _sidebarMenu() {
    void open(Widget page) {
      if (WebShellScope.contentNavigator.currentState != null) {
        WebShellScope.open(page);
        return;
      }
      if (!mounted) return;
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
        icon: Icons.warning_amber_rounded,
        label: 'Warnings',
        group: 'Requests',
        onTap: () => open(_warningsPage()),
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
        icon: isDivisionView
            ? Icons.person_outline_rounded
            : Icons.person_rounded,
        label: 'My Profile',
        group: 'Profile',
        selected: !isDivisionView,
        onTap: _openProfile,
      ),
      if (!isDivisionView)
        WebMenuItem(
          icon: Icons.arrow_back_rounded,
          label: 'Back to dashboard',
          group: 'Profile',
          selected: true,
          onTap: _backToDivision,
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
}
