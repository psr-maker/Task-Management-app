import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/utils/role_hierarchy.dart';
import 'package:staff_work_track/core/responsive/web_shell_controller.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/app_menu_drawer.dart';
import 'package:staff_work_track/core/widgets/load_error.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/dashboard/dashboard_lists.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/extrawork/Compensation.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/leave/leavelist.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/ovtme/overtime.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/punch/punchlist.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/settings/usersettings.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/staff_report.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/staff_warnings.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/Reports/reports_table.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/announ_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/work_performance.dart';

class StaffDashboard extends StatefulWidget {
  final int userid;
  final String role;
  final VoidCallback? onBackToManager;
  final String backToLabel;
  final bool replaceShellMenu;
  final String personName;
  final String personDepartment;
  const StaffDashboard({
    super.key,
    required this.userid,
    required this.role,
    this.onBackToManager,
    this.backToLabel = "Back to Dashboard",
    this.replaceShellMenu = false,
    this.personName = '',
    this.personDepartment = '',
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool loadFailed = false;
  DateTime selectedYear = DateTime.now();
  int selectedMonth = DateTime.now().month <= 1 ? 12 : DateTime.now().month - 1;
  List<dynamic> monthlyData = [];
  List<dynamic> breakdownData = [];
  List<dynamic> previousMonthly = [];
  Map<String, dynamic> previousSummary = {};
  List<dynamic> leaveItems = [];
  List<dynamic> permissionItems = [];
  List<dynamic> compensationItems = [];
  List<dynamic> overtimeItems = [];
  String staffName = '';
  String departmentName = '';
  late bool _hideOvertime;
  TaskTiming taskTiming = TaskTiming.empty;
  List<WarningModel> userWarnings = [];
  int dueSoonGoals = 0;
  int dueSoonTasks = 0;

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
    final now = DateTime.now();
    if (now.month == 1) {
      selectedYear = DateTime(now.year - 1);
      selectedMonth = 12;
    }
    _hideOvertime = false;
    _resolveOvertimeVisibility();
    fetchAllData();
    _loadTaskTiming();
    _loadWarnings();
    _loadDueSoon();
  }

  Future<void> _loadDueSoon() async {
    try {
      final results = await Future.wait([
        loadWorkItems(
          kind: DashboardListKind.goals,
          filter: WorkStatusFilter.dueSoon,
          userId: widget.userid,
        ),
        loadWorkItems(
          kind: DashboardListKind.tasks,
          filter: WorkStatusFilter.dueSoon,
          userId: widget.userid,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        dueSoonGoals = results[0].length;
        dueSoonTasks = results[1].length;
      });
    } catch (e) {
      debugPrint('Due soon: $e');
    }
  }

  List<WarningModel> _warningsForUser(
    List<WarningModel> items, {
    required bool fromUserEndpoint,
  }) {
    final matched = items
        .where(
          (item) => item.belongsToUser(
            widget.userid,
            name: widget.personName,
          ),
        )
        .toList();
    if (matched.isNotEmpty) return matched;
    if (fromUserEndpoint &&
        items.isNotEmpty &&
        items.every((item) => item.receiverId == 0)) {
      return items;
    }
    return matched;
  }

  Future<void> _loadWarnings() async {
    List<WarningModel> warnings = [];
    try {
      warnings = _warningsForUser(
        await AnnouncementService.getWarningsByUser(widget.userid),
        fromUserEndpoint: true,
      );
    } catch (e) {
      debugPrint('Staff warnings: $e');
    }
    if (warnings.isEmpty) {
      try {
        warnings = _warningsForUser(
          await AnnouncementService.getWarnings(),
          fromUserEndpoint: false,
        );
      } catch (err) {
        debugPrint('Staff warnings fallback: $err');
      }
    }
    if (!mounted) return;
    setState(() => userWarnings = warnings);
  }

  void _openWarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffWarningsPage(
          userId: widget.userid,
          personName: widget.personName,
        ),
      ),
    );
  }

  Future<void> _resolveOvertimeVisibility() async {
    try {
      final roles = await SuperAdminService.getRoles();
      final hide = skipsOvertime(roles, widget.role);
      if (mounted) setState(() => _hideOvertime = hide);
    } catch (_) {}
  }

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsTable(userId: widget.userid),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsersSettings()),
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
    await fetchAllData();
    await _loadTaskTiming();
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
      final monthly = _reportMonths(report["monthlyProductivityReport"]);
      List<dynamic> breakdown = [];
      try {
        breakdown = await ReportsService.getMonthlyProductivity(
          widget.userid,
          selectedYear.year,
        );
      } catch (e) {
        debugPrint("Monthly productivity: $e");
      }
      var name = _profileText(report, const [
        "employeeName",
        "name",
        "userName",
      ]);
      var department = _profileText(report, const [
        "department",
        "departmentName",
      ]);
      if (name.isEmpty) name = widget.personName.trim();
      if (department.isEmpty) department = widget.personDepartment.trim();
      List<dynamic> priorMonthly = [];
      Map<String, dynamic> priorSummary = {};
      List<dynamic> leaves = [];
      List<dynamic> permissions = [];
      List<dynamic> compensations = [];
      List<dynamic> overtimes = [];
      var reportAttendance = report;
      try {
        priorSummary = await ReportsService.getEmployeeReport(
          widget.userid,
          selectedYear.year - 1,
        );
      } catch (e) {
        debugPrint("Previous year report: $e");
      }
      priorMonthly = _reportMonths(priorSummary["monthlyProductivityReport"]);
      try {
        final token = await AuthService.getToken();
        final signedInId = token == null || token.isEmpty
            ? null
            : int.tryParse(JwtHelper.getuid(token) ?? '');
        final viewingOther =
            signedInId != null && signedInId != widget.userid;
        if (viewingOther) {
          final owned = await _recordsForSelectedUser(widget.userid, name);
          leaves = owned.leaves;
          permissions = owned.permissions;
          compensations = owned.compensations;
          overtimes = owned.overtimes;
          if (department.isEmpty) department = owned.department;
          if (name.isEmpty) name = widget.personName.trim();
          reportAttendance = report;
        } else {
          leaves = _itemList(await AdminService.getLeaves());
          permissions = _itemList(await AdminService.getPermissions());
          compensations = await OvertimeService.getMyExtraWork();
          overtimes = _itemList(await OvertimeService.getMyOvertime());
          if (name.isEmpty || department.isEmpty) {
            final profile = await AuthService.getMyProfile();
            if (name.isEmpty) {
              name = _profileText(profile, const ['name', 'userName', 'fullName']);
            }
            if (department.isEmpty) {
              department = _profileText(profile, const [
                'department',
                'departmentName',
                'dept',
              ]);
            }
          }
        }
      } catch (e) {
        debugPrint("Attendance: $e");
      }

      if (!mounted) return;
      setState(() {
        data = reportAttendance;
        monthlyData = monthly;
        breakdownData = breakdown;
        previousMonthly = priorMonthly;
        previousSummary = priorSummary;
        leaveItems = leaves;
        permissionItems = permissions;
        compensationItems = compensations;
        overtimeItems = overtimes;
        staffName = name;
        departmentName = department;
        isLoading = false;
        loadFailed = false;
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

  String _profileText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  List<dynamic> _reportMonths(dynamic raw) {
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? 0;
  }

  List<dynamic> _itemList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final list =
          value["data"] ??
          value["leaves"] ??
          value["permissions"] ??
          value["overtimes"] ??
          value["OverTimes"] ??
          value["overtime"] ??
          value["result"] ??
          value["items"];
      if (list is List) return list;
    }
    return [];
  }

  bool _listIsOnlyThisUser(List<dynamic> items, int userId) {
    for (final raw in items) {
      if (raw is! Map) continue;
      final id = _recordUserId(Map<String, dynamic>.from(raw));
      if (id != null && id != userId) return false;
    }
    return true;
  }

  Future<_SelectedAttendance> _recordsForSelectedUser(
    int userId,
    String name,
  ) async {
    var leaves = <dynamic>[];
    var permissions = <dynamic>[];
    var compensations = <dynamic>[];
    var overtimes = <dynamic>[];
    var department = widget.personDepartment.trim();
    if (name.trim().isEmpty) name = widget.personName.trim();
    try {
      final full = await ReportsService.getFullReport(userId: userId);
      final users = full['users'];
      final fromReport = _departmentOf(users, userId);
      if (fromReport.isNotEmpty) department = fromReport;
      final leaveRows = _itemList(full['leaveList']);
      final permissionRows = _itemList(full['permissionList']);
      final compensationRows = _itemList(full['compensationList']);
      final overtimeRows = _itemList(full['overtimeList']);
      leaves = _approvedForUser(
        leaveRows,
        userId,
        name,
        scoped: _listIsOnlyThisUser(leaveRows, userId),
      );
      permissions = _approvedForUser(
        permissionRows,
        userId,
        name,
        scoped: _listIsOnlyThisUser(permissionRows, userId),
      );
      compensations = _approvedForUser(
        compensationRows,
        userId,
        name,
        scoped: _listIsOnlyThisUser(compensationRows, userId),
      );
      overtimes = _approvedOvertimeForUser(
        overtimeRows,
        userId,
        name,
        scoped: _listIsOnlyThisUser(overtimeRows, userId),
      );
      final knownName = _nameOf(users, userId);
      if (knownName.isNotEmpty) name = knownName;
    } catch (e) {
      debugPrint('Selected user report: $e');
    }
    if (compensations.isEmpty && department.isNotEmpty) {
      try {
        compensations = _approvedForUser(
          await OvertimeService.getExtraWorkByDepartments([department]),
          userId,
          name,
          scoped: false,
        );
      } catch (e) {
        debugPrint('Selected user compensation: $e');
      }
    }
    if (name.trim().isEmpty || department.isEmpty) {
      try {
        final people = await SuperAdminService.getAllUsers();
        for (final user in people) {
          if (user.userId != userId) continue;
          if (name.trim().isEmpty) {
            name = user.displayName.isNotEmpty ? user.displayName : user.name;
          }
          if (department.isEmpty) department = user.department;
          break;
        }
      } catch (e) {
        debugPrint('Selected user profile: $e');
      }
    }
    if (overtimes.isEmpty && department.isNotEmpty) {
      try {
        overtimes = _approvedOvertimeForUser(
          await OvertimeService.getOvertimeByDepartments([department]),
          userId,
          name,
          scoped: false,
        );
      } catch (e) {
        debugPrint('Selected user overtime: $e');
      }
    }
    if (overtimes.isEmpty) {
      try {
        final approved = _itemList(await AdminService.getApprovedOvertimes());
        overtimes = [
          for (final raw in approved)
            if (raw is Map &&
                _sameUser(
                  Map<String, dynamic>.from(raw),
                  userId,
                  name.trim().toLowerCase(),
                ))
              Map<String, dynamic>.from(raw),
        ];
        for (final item in overtimes) {
          if (item is Map<String, dynamic>) _prepareAttendanceRow(item);
        }
      } catch (e) {
        debugPrint('Selected user overtime: $e');
      }
    }
    return _SelectedAttendance(
      leaves: leaves,
      permissions: permissions,
      compensations: compensations,
      overtimes: overtimes,
      department: department,
    );
  }

  String _nameOf(dynamic users, int userId) {
    if (users is! List) return '';
    for (final user in users) {
      if (user is! Map) continue;
      final item = Map<String, dynamic>.from(user);
      if (_recordUserId(item) != userId) continue;
      return _profileText(item, const [
        'name',
        'Name',
        'userName',
        'employeeName',
        'staffName',
      ]);
    }
    return '';
  }

  String _departmentOf(dynamic users, int userId) {
    if (users is! List) return '';
    for (final user in users) {
      if (user is! Map) continue;
      final item = Map<String, dynamic>.from(user);
      if (_recordUserId(item) != userId) continue;
      return _profileText(item, const [
        'department',
        'departmentName',
        'Department',
        'DepartmentName',
      ]);
    }
    return '';
  }

  List<dynamic> _approvedOvertimeForUser(
    List<dynamic> items,
    int userId,
    String name, {
    required bool scoped,
  }) {
    final wanted = name.trim().toLowerCase();
    final rows = <dynamic>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      if (!scoped && !_sameUser(item, userId, wanted)) continue;
      if (!_isApprovedOvertime(item)) continue;
      _prepareAttendanceRow(item);
      rows.add(item);
    }
    return rows;
  }

  bool _isApprovedOvertime(Map<String, dynamic> item) {
    final status = (item['status'] ?? item['Status'] ?? '')
        .toString()
        .toLowerCase();
    final manager = (item['managerStatus'] ?? item['ManagerStatus'] ?? '')
        .toString()
        .toLowerCase();
    if (status.contains('reject') || manager.contains('reject')) return false;
    if (item['isApproved'] == true ||
        item['IsApproved'] == true ||
        item['isApprov'] == true) {
      return true;
    }
    if (manager.contains('approv')) return true;
    return status.contains('approv');
  }

  List<dynamic> _approvedForUser(
    List<dynamic> items,
    int userId,
    String name, {
    required bool scoped,
  }) {
    final wanted = name.trim().toLowerCase();
    final rows = <dynamic>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      if (!scoped && !_sameUser(item, userId, wanted)) continue;
      if (!_isApprovedRecord(item)) continue;
      _prepareAttendanceRow(item);
      rows.add(item);
    }
    return rows;
  }

  bool _sameUser(Map<String, dynamic> item, int userId, String wanted) {
    final id = _recordUserId(item);
    if (id != null) return id == userId;
    if (wanted.isEmpty) return false;
    for (final key in const [
      'staffName',
      'StaffName',
      'userName',
      'UserName',
      'employeeName',
      'name',
      'Name',
    ]) {
      final value = (item[key] ?? '').toString().trim().toLowerCase();
      if (value.isEmpty) continue;
        if (value == wanted) return true;
        final valueTail = value.contains('-') ? value.split('-').last.trim() : value;
        final wantedTail = wanted.contains('-') ? wanted.split('-').last.trim() : wanted;
        if (valueTail.isNotEmpty &&
            (valueTail == wantedTail || value == wantedTail || valueTail == wanted)) {
          return true;
        }
    }
    return false;
  }

  int? _recordUserId(Map<String, dynamic> item) {
    for (final key in const [
      'userId',
      'UserId',
      'staffId',
      'StaffId',
      'employeeId',
      'EmployeeId',
      'uid',
      'Uid',
    ]) {
      final value = item[key];
      if (value == null) continue;
      final parsed = value is int ? value : int.tryParse(value.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    for (final key in const ['user', 'User', 'employee', 'staff']) {
      final nested = item[key];
      if (nested is! Map) continue;
      final id = _recordUserId(Map<String, dynamic>.from(nested));
      if (id != null) return id;
    }
    return null;
  }

  bool _isApprovedRecord(Map<String, dynamic> item) {
    final status = (
      item['status'] ??
          item['Status'] ??
          item['managerStatus'] ??
          item['ManagerStatus'] ??
          ''
    ).toString().toLowerCase();
    final staff = (item['staffStatus'] ?? item['StaffStatus'] ?? '')
        .toString()
        .toLowerCase();
    if (status.contains('reject') || staff.contains('reject')) return false;
    if (item['isApproved'] == true || item['IsApproved'] == true) return true;
    return status.contains('approv') ||
        status.contains('accept') ||
        staff.contains('approv') ||
        staff.contains('accept');
  }

  void _prepareAttendanceRow(Map<String, dynamic> item) {
    item['status'] = 'Approved';
    item['fromDate'] ??=
        item['FromDate'] ?? item['leaveDate'] ?? item['date'] ?? item['Date'];
    item['date'] ??= item['Date'] ?? item['fromDate'] ?? item['workDate'];
    item['workDate'] ??= item['WorkDate'] ?? item['workedDate'] ?? item['date'];
    item['totalHours'] ??=
        item['TotalHours'] ?? item['hours'] ?? item['expectedHours'];
    item['totalDays'] ??= item['TotalDays'] ?? item['days'];
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

    final isWeb = !AppLayout.isMobile(context);
    final embedded = widget.onBackToManager != null;
    if (!embedded || widget.replaceShellMenu) {
      bindWebHeader(
        context,
        onReports: _openReports,
        onSettings: _openSettings,
        menuItems: _sidebarMenu(),
        menuOwner: this,
      );
    }

    return Scaffold(
      drawer: isWeb ? null : _buildDrawer(context),
      appBar: isWeb ? null : _mobileAppBar(),

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
                  if (widget.onBackToManager != null) ...[
                    TextButton.icon(
                      onPressed: widget.onBackToManager,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(widget.backToLabel),
                    ),
                    const SizedBox(height: 8),
                  ],
                  StaffReport(
                    year: selectedYear.year,
                    summary: data ?? {},
                    previousSummary: previousSummary,
                    monthly: monthlyData,
                    breakdown: breakdownData,
                    previousMonthly: previousMonthly,
                    taskTiming: taskTiming,
                    attendance: attendanceMap,
                    leaves: leaveItems,
                    permissions: permissionItems,
                    compensations: compensationItems,
                    overtimes: overtimeItems,
                    showOvertime: !_hideOvertime || overtimeItems.isNotEmpty,
                    staffName: staffName,
                    department: departmentName,
                    warningCount: userWarnings.length,
                    dueSoonGoals: dueSoonGoals,
                    dueSoonTasks: dueSoonTasks,
                    onWarnings: _openWarnings,
                    month: selectedMonth,
                    onSelectMonth: (value) => setState(() => selectedMonth = value),
                    onPickYear: _pickYear,
                    onOpenReports: _openReports,
                    onOpenSettings: _openSettings,
                    onOpen: (kind, title, filter) => _openList(
                      kind,
                      title,
                      filter: filter,
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

  PreferredSizeWidget _mobileAppBar() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final name = staffName.trim().isEmpty ? 'Dashboard' : staffName.trim();
    final department = departmentName.trim();
    return AppBar(
      backgroundColor: WebTheme.isDark(context)
          ? WebTheme.headerOf(context)
          : WebTheme.brand,
      foregroundColor: WebTheme.isDark(context)
          ? WebTheme.inkOf(context)
          : Colors.white,
      iconTheme: IconThemeData(
        color: WebTheme.isDark(context) ? WebTheme.inkOf(context) : Colors.white,
      ),
      toolbarHeight: 64,
      titleSpacing: 0,
      automaticallyImplyLeading: true,
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
          if (department.isNotEmpty)
            Text(
              department,
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
        if (userWarnings.isNotEmpty)
          IconButton(
            tooltip: 'Warnings',
            visualDensity: VisualDensity.compact,
            onPressed: _openWarnings,
            icon: Badge(
              isLabelVisible: userWarnings.isNotEmpty,
              label: Text('${userWarnings.length}'),
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
        const SizedBox(width: 8),
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

    final warningCount = userWarnings.length;
    return [
      if (widget.onBackToManager != null)
        WebMenuItem(
          icon: Icons.arrow_back_rounded,
          label: widget.backToLabel,
          group: 'Profile',
          selected: true,
          onTap: widget.onBackToManager!,
        ),
      if (warningCount > 0)
        WebMenuItem(
          icon: Icons.warning_amber_rounded,
          label: 'Warnings ($warningCount)',
          group: 'Requests',
          onTap: () => open(
            StaffWarningsPage(
              userId: widget.userid,
              personName: widget.personName,
            ),
          ),
        ),
      WebMenuItem(
        icon: Icons.event_available_rounded,
        label: 'Leave / Permission',
        group: 'Requests',
        onTap: () => open(const Leavelist()),
      ),
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

class _SelectedAttendance {
  final List<dynamic> leaves;
  final List<dynamic> permissions;
  final List<dynamic> compensations;
  final List<dynamic> overtimes;
  final String department;

  const _SelectedAttendance({
    required this.leaves,
    required this.permissions,
    required this.compensations,
    required this.overtimes,
    required this.department,
  });
}
