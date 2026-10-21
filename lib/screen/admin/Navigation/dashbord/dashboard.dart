import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/staff_warnings.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/manager_report.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/attinbhvscore/scoredisplay.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/company/hr_warnings.dart';
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
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/reports_service.dart';

class _LiveProfile {
  static final List<VoidCallback> _handlers = [];

  static void register(VoidCallback handler) {
    if (!_handlers.contains(handler)) _handlers.add(handler);
  }

  static void unregister(VoidCallback handler) {
    _handlers.remove(handler);
  }

  static void open() {
    if (_handlers.isEmpty) return;
    _handlers.last();
  }
}

class AdminDashboard extends StatefulWidget {
  final int mngId;
  final String role;
  final String department;
  final VoidCallback? onBack;
  final String backLabel;
  const AdminDashboard({
    super.key,
    required this.department,
    required this.role,
    required this.mngId,
    this.onBack,
    this.backLabel = 'Back to reports',
  });
  @override
  State<AdminDashboard> createState() => _AdminState();
}

class _AdminState extends State<AdminDashboard> {
  late Future<Map<String, dynamic>> reportFuture;
  Map<String, dynamic>? data;
  bool isLoading = true;
  DateTime selectedYear = DateTime.now();
  int selectedMonth = DateTime.now().month <= 1 ? 1 : DateTime.now().month - 1;
  int overdueTaskCount = 0;
  int overdueGoalCount = 0;
  int apiWarningCount = 0;
  int dueSoonGoalCount = 0;
  int dueSoonTaskCount = 0;
  int notificationCount = 0;
  List<WarningModel> apiWarnings = [];
  List<Map<String, dynamic>> overdueTaskList = [];
  List<Map<String, dynamic>> overdueGoalList = [];
  bool isManagerView = true;
  String _roleTitle = '';

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
    _roleTitle = AppRoles.displayName(widget.role);
    _loadRoleTitle();
    _LiveProfile.register(_showMyProfile);
    _fetchReport();
    loadData();
    _fetchWarnings();
    _loadDueSoon();
  }

  @override
  void dispose() {
    _LiveProfile.unregister(_showMyProfile);
    super.dispose();
  }

  Future<void> _loadRoleTitle() async {
    try {
      final roles = await SuperAdminService.getRoles();
      if (!mounted) return;
      final name = AppRoles.displayName(widget.role, roles: roles);
      if (name.isEmpty) return;
      setState(() => _roleTitle = name);
    } catch (_) {}
  }

  void _showMyProfile() {
    if (!mounted) return;
    setState(() => isManagerView = false);
  }

  void _openDepartmentWarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffWarningsPage(
          userId: widget.mngId,
          departmentScope: true,
          department: widget.onBack == null ? '' : widget.department,
        ),
      ),
    );
  }

  Future<void> _loadDueSoon() async {
    try {
      final results = await Future.wait([
        loadWorkItems(
          kind: DashboardListKind.goals,
          filter: WorkStatusFilter.dueSoon,
          department: widget.department,
        ),
        loadWorkItems(
          kind: DashboardListKind.tasks,
          filter: WorkStatusFilter.dueSoon,
          department: widget.department,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        dueSoonGoalCount = results[0].length;
        dueSoonTaskCount = results[1].length;
      });
    } catch (e) {
      debugPrint('Due soon load error: $e');
    }
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
      isLoading = true;
    });
    _fetchReport();
    await loadData();
  }

  List<WarningModel> _warningsForThisDepartment(List<WarningModel> warnings) {
    final department = widget.department.trim();
    if (widget.onBack == null || department.isEmpty) return warnings;
    return warnings.where((item) => item.belongsToDepartment(department)).toList();
  }

  void _fetchWarnings() async {
    try {
      final warnings = _warningsForThisDepartment(
        await AnnouncementService.getWarnings(),
      );
      if (!mounted) return;
      setState(() {
        apiWarnings = warnings;
        apiWarningCount = warnings.length;
      });
    } catch (e) {
      print("Warning fetch error: $e");
    }
  }

  List<dynamic> _scoreList(dynamic raw) {
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
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
        data = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _LiveProfile.register(_showMyProfile);
    final isWeb = !AppLayout.isMobile(context);
    if (isManagerView) {
      bindWebHeader(
        context,
        overdueCount: apiWarningCount,
        onOverdue: _openDepartmentWarnings,
        onReports: _openReports,
        onSettings: _openSettings,
        menuItems: _sidebarMenu(),
        menuOwner: this,
      );
    }

    return Scaffold(
      drawer: isWeb || widget.onBack != null ? null : _buildDrawer(context),
      appBar: isWeb || !isManagerView ? null : _mobileAppBar(),
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
                final nextTasks = _reportList(data, const [
                  "overdueTasksList",
                  "overdueTaskslist",
                  "overdueTaskList",
                ]);
                final nextGoals = _reportList(data, const [
                  "overdueGoalsList",
                  "overdueGoalslist",
                  "overdueGoalList",
                ]);
                final nextTaskCount = nextTasks.isNotEmpty
                    ? nextTasks.length
                    : _count(data["overdueTasks"]);
                final nextGoalCount = nextGoals.isNotEmpty
                    ? nextGoals.length
                    : _count(data["overdueGoals"]);
                if (nextTaskCount != overdueTaskCount ||
                    nextGoalCount != overdueGoalCount ||
                    nextTasks.length != overdueTaskList.length ||
                    nextGoals.length != overdueGoalList.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      overdueTaskList = nextTasks;
                      overdueGoalList = nextGoals;
                      overdueTaskCount = nextTaskCount;
                      overdueGoalCount = nextGoalCount;
                    });
                  });
                }
                final reportMonths = _scoreList(
                  data["departmentMonthlyScores"] ??
                      data["DepartmentMonthlyScores"],
                );
                final breakdownMonths = this.data?["monthlyData"] is List
                    ? this.data!["monthlyData"] as List
                    : const [];
                final report = ManagerReport(
                  department: widget.department,
                  year: selectedYear.year,
                  month: selectedMonth,
                  summary: data,
                  monthly: reportMonths,
                  breakdown: breakdownMonths,
                  onPickYear: _pickYear,
                  onSelectMonth: (value) => setState(() => selectedMonth = value),
                  onOpenReports: _openReports,
                  onOpenSettings: _openSettings,
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
                  dueSoonGoals: dueSoonGoalCount,
                  dueSoonTasks: dueSoonTaskCount,
                  onWarnings: widget.onBack != null && apiWarningCount == 0
                      ? null
                      : _openDepartmentWarnings,
                );
                if (widget.onBack == null || !isWeb) return report;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: TextButton.icon(
                        onPressed: widget.onBack,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: WebTheme.brandOf(context),
                        ),
                        label: Text(widget.backLabel),
                      ),
                    ),
                    Expanded(child: report),
                  ],
                );
              },
            )
          : StaffDashboard(
              onBackToManager: () {
                if (!mounted) return;
                setState(() {
                  isManagerView = true;
                });
              },
              replaceShellMenu: true,
              userid: widget.mngId,
              role: widget.role,
            ),
    );
  }

  PreferredSizeWidget _mobileAppBar() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final name = widget.department.trim().isEmpty
        ? 'Department'
        : widget.department.trim();
    return AppBar(
      backgroundColor: WebTheme.brand,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 64,
      titleSpacing: widget.onBack == null ? 0 : null,
      leading: widget.onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: widget.onBack,
            ),
      automaticallyImplyLeading: widget.onBack == null,
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
          Text(
            _roleTitle,
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
        if (widget.onBack == null || apiWarningCount > 0)
          IconButton(
            tooltip: 'Warnings',
            visualDensity: VisualDensity.compact,
            onPressed: _openDepartmentWarnings,
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

    final bool isAccountsManager =
        widget.department.trim() == "Accounts Department" &&
        AppRoles.isManager(widget.role);
    final bool isHRManager =
        widget.department.trim() == "HR Department" &&
        AppRoles.isManager(widget.role);

    return [
      if (widget.onBack != null)
        WebMenuItem(
          icon: Icons.arrow_back_rounded,
          label: widget.backLabel,
          group: 'Profile',
          selected: true,
          onTap: widget.onBack!,
        ),
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
      if (isHRManager) ...[
        WebMenuItem(
          icon: Icons.event_note_rounded,
          label: 'Leave Reports',
          group: 'Administration',
          onTap: () => open(const HrLeaves()),
        ),
        WebMenuItem(
          icon: Icons.warning_amber_rounded,
          label: 'Warnings',
          group: 'Administration',
          onTap: () => open(const HrWarningsPage()),
        ),
      ],
      if (widget.onBack == null)
        WebMenuItem(
          icon: Icons.person_outline_rounded,
          label: 'My Profile',
          group: 'Profile',
          stamp: 1,
          onTap: _LiveProfile.open,
        ),
    ];
  }

  Widget _buildDrawer(BuildContext context) {
    final subtitle = widget.department.trim().isEmpty
        ? 'Department overview'
        : widget.department.trim();
    return AppMenuDrawer(
      title: _roleTitle,
      subtitle: subtitle,
      icon: Icons.dashboard_rounded,
      items: _sidebarMenu(),
    );
  }
}
