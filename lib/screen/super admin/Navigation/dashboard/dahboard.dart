import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/department/department_dashboard.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/director_report.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/staffleaves.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/director_compensation.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/anouncement.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/auditlog.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/task%20points/emptaskreview.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/points.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/drawer/usersworklog.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/settings/settings.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/staff_warnings.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/dashboard_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/work_performance.dart';

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
  DateTime selectedYear = DateTime.now();
  int selectedMonth = DateTime.now().month <= 1 ? 12 : DateTime.now().month - 1;
  int apiWarningCount = 0;
  int dueSoonGoalCount = 0;
  int dueSoonTaskCount = 0;
  List<({String department, int count})> departmentWarnings = [];
  List<String> companyDepartments = [];
  void _openList(
    DashboardListKind kind,
    String title, {
    WorkStatusFilter filter = WorkStatusFilter.all,
    bool companyDepartments = false,
    bool openReports = false,
  }) {
    openDashboardList(
      context,
      kind: kind,
      filter: filter,
      title: title,
      companyDepartments: companyDepartments,
      openReports: openReports,
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
    _fetchWarnings();
    _loadDueSoon();
    dashboard = loadDashboard();
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
      dashboard = loadDashboard();
    });
  }

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportsTable()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Settings()),
    );
  }

  void _openWarnings([String department = '']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffWarningsPage(
          userId: 0,
          companyScope: true,
          initialDepartment: department,
          filterDepartments: companyDepartments,
        ),
      ),
    );
  }

  void _fetchWarnings() async {
    try {
      final warnings = await AnnouncementService.getWarnings();
      if (!mounted) return;
      setState(() {
        apiWarningCount = warnings.length;
        departmentWarnings = _warningsByDepartment(warnings);
      });
    } catch (e) {
      print("Warning fetch error: $e");
    }
  }

  List<({String department, int count})> _warningsByDepartment(List<WarningModel> warnings) {
    final groups = <String, int>{};
    for (final item in warnings) {
      final dept = item.receiverDept.trim();
      final key = dept.isEmpty
          ? 'Company'
          : groups.keys.cast<String?>().firstWhere(
                (name) => name != null && DivisionConfig.isAllowedDepartment(dept, [name]),
                orElse: () => null,
              ) ??
              dept;
      groups[key] = (groups[key] ?? 0) + 1;
    }
    final rows = [
      for (final entry in groups.entries) (department: entry.key, count: entry.value),
    ];
    rows.sort((a, b) => a.department.toLowerCase().compareTo(b.department.toLowerCase()));
    return rows;
  }

  Future<void> _loadDueSoon() async {
    try {
      final results = await Future.wait([
        loadWorkItems(kind: DashboardListKind.goals, filter: WorkStatusFilter.dueSoon),
        loadWorkItems(kind: DashboardListKind.tasks, filter: WorkStatusFilter.dueSoon),
      ]);
      if (!mounted) return;
      setState(() {
        dueSoonGoalCount = results[0].length;
        dueSoonTaskCount = results[1].length;
      });
    } catch (e) {
      print('Due soon load error: $e');
    }
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

  Future<Map<String, dynamic>> loadDashboard() async {
    final year = selectedYear.year;
    final raw = _unwrapSummary(await _service.getDashboardSummary(year: year));
    Map<String, dynamic> previous = {};
    if (year > 2000) {
      try {
        previous = _unwrapSummary(await _service.getDashboardSummary(year: year - 1));
      } catch (_) {}
    }
    final currentCompany = _companyBlock(_map(raw));
    final previousCompany = _companyBlock(_map(previous));
    var userCount = _int(currentCompany["totalUsers"]);
    if (userCount <= 0) {
      try {
        final users = await SuperAdminService.getAllUsers();
        userCount = users.length;
      } catch (_) {}
    }
    final data = {
      ...currentCompany,
      "totalUsers": userCount,
      "departmentRows": _departmentRows(raw),
      "previousDepartmentRows": _departmentRows(previous),
      "previousMonthlyCompanyPerformance": _companyMonths(previous),
      "previousYearlyOverallCompanyScore":
          previousCompany["yearlyOverallCompanyScore"],
      "previousYearlyCompanyProductivity":
          previousCompany["yearlyCompanyProductivity"],
    };
    final fromSummary = [
      for (final row in _departmentRows(raw))
        (row['department'] ?? '').toString().trim(),
    ];
    List<String> fromApi = [];
    try {
      fromApi = await ReportsService.getAllDepartments();
    } catch (_) {}
    companyDepartments = _mergeDepartments([...fromApi, ...fromSummary]);
    return data;
  }

  List<String> _mergeDepartments(List<String> names) {
    final merged = <String>[];
    for (final value in names) {
      final name = value.trim();
      if (name.isEmpty || name == 'null') continue;
      if (merged.any((item) => DivisionConfig.isAllowedDepartment(name, [item]))) {
        continue;
      }
      merged.add(name);
    }
    merged.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return merged;
  }

  Map<String, dynamic> _companyBlock(Map<String, dynamic> root) {
    final company = _map(root['company']);
    final tasks = _map(company.isEmpty ? root['tasks'] : company['tasks']);
    final goals = _map(company.isEmpty ? root['goals'] : company['goals']);
    tasks.putIfAbsent('onTimeTaskCompletionPercentage', () => tasks['onTimePercentage']);
    tasks.putIfAbsent('delayedTaskPercentage', () => tasks['delayedPercentage']);
    goals.putIfAbsent('onTimeGoalCompletionPercentage', () => goals['onTimePercentage']);
    goals.putIfAbsent('delayedGoalPercentage', () => goals['delayedPercentage']);
    return {
      'totalUsers': company['totalUsers'] ?? root['totalUsers'],
      'totalDepartments': company['totalDepartments'] ?? root['totalDepartments'],
      'availableMonths': root['availableMonths'],
      'yearlyOverallCompanyScore': company['yearlyOverallCompanyScore'],
      'yearlyCompanyProductivity': company['yearlyCompanyProductivity'],
      'tasks': tasks,
      'goals': goals,
      'monthlyCompanyPerformance': _companyMonths(root),
    };
  }

  List<Map<String, dynamic>> _companyMonths(Map<String, dynamic> root) {
    return [
      for (final row in _mapList(root['monthlyCompanyPerformance']))
        {
          'month': row['month'],
          'totalScore': row['performance'] ?? row['totalScore'],
          'productivity': row['productivity'],
        },
    ];
  }

  List<Map<String, dynamic>> _departmentRows(Map<String, dynamic> root) {
    final mapped = _map(root);
    final source = mapped['departments'] ?? mapped['departmentData'];
    return [
      for (final dept in _mapList(source))
        {
          'department': dept['department'] ?? dept['departmentName'],
          'monthlyData': [
            for (final month in _mapList(dept['monthlyPerformance'] ?? dept['monthlyData']))
              {
                'month': month['month'],
                'totalScore': month['performance'] ?? month['totalScore'],
                'productivity': month['productivity'],
              },
          ],
        },
    ];
  }

  List<Map<String, dynamic>> _rowList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => _map(item)).toList();
  }

  TaskTiming _timing(Map<String, dynamic> work, String onTimeKey, String delayedKey) {
    if (!work.containsKey(onTimeKey) && !work.containsKey(delayedKey)) {
      return TaskTiming.empty;
    }
    return TaskTiming(
      onTime: work.containsKey(onTimeKey) ? _num(work[onTimeKey]) : null,
      delayed: work.containsKey(delayedKey) ? _num(work[delayedKey]) : null,
    );
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
          map.containsKey("TotalDepartments") ||
          map.containsKey("company") ||
          map.containsKey("Company") ||
          map.containsKey("monthlyCompanyPerformance")) {
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
    final warnings = apiWarningCount;
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
          final departments = _rowList(data['departmentRows']);
          final previousDepartments = _rowList(data['previousDepartmentRows']);
          final taskMap = _map(data['tasks']);
          final goalMap = _map(data['goals']);
          return DirectorReport(
            year: selectedYear.year,
            month: selectedMonth,
            onSelectMonth: (value) => setState(() => selectedMonth = value),
            summary: data,
            departments: departments,
            productivity: departments,
            previousProductivity: previousDepartments,
            taskTiming: _timing(taskMap, 'onTimePercentage', 'delayedPercentage'),
            goalTiming: _timing(goalMap, 'onTimePercentage', 'delayedPercentage'),
            warningCount: warnings,
            departmentWarnings: departmentWarnings,
            dueSoonGoals: dueSoonGoalCount,
            dueSoonTasks: dueSoonTaskCount,
            onOpenDepartmentWarnings: _openWarnings,
            onPickYear: _pickYear,
            onOpenReports: _openReports,
            onOpenSettings: _openSettings,
            onWarnings: _openWarnings,
            onOpenUsers: () => _openList(
              DashboardListKind.staff,
              'Total Users',
              openReports: true,
            ),
            onOpenDepartments: () => _openList(
              DashboardListKind.departments,
              'Departments',
              companyDepartments: true,
              openReports: true,
            ),
            onOpenDepartment: (department) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DepartmentDashboardPage(department: department),
                ),
              );
            },
            onOpenTasks: (title, filter) =>
                _openList(DashboardListKind.tasks, title, filter: filter),
            onOpenGoals: (title, filter) =>
                _openList(DashboardListKind.goals, title, filter: filter),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _mobileAppBar() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return AppBar(
      backgroundColor: WebTheme.brand,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 64,
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Director',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Company overview',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70, fontSize: 11),
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
          tooltip: 'Reports',
          visualDensity: VisualDensity.compact,
          onPressed: _openReports,
          icon: const Icon(
            Icons.bar_chart_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (apiWarningCount > 0)
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
          tooltip: 'Settings',
          visualDensity: VisualDensity.compact,
          onPressed: _openSettings,
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  List<WebMenuItem> _sidebarMenu() => directorShellMenu(context);

  Widget _buildDrawer(BuildContext context) {
    return AppMenuDrawer(
      title: 'Super Admin',
      subtitle: 'Admin Panel',
      icon: Icons.admin_panel_settings_rounded,
      items: _sidebarMenu(),
    );
  }
}

List<WebMenuItem> directorShellMenu(BuildContext context) {
  void open(Widget page) {
    if (WebShellScope.contentNavigator.currentState != null) {
      WebShellScope.open(page);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
      icon: Icons.warning_amber_rounded,
      label: 'Warnings',
      group: 'Requests',
      onTap: () => open(
        const StaffWarningsPage(userId: 0, companyScope: true),
      ),
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
