import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/request_workspace.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
import 'package:staff_work_track/utils/time_utils.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';

class DivLeaveManagement extends StatefulWidget {
  final String department;
  const DivLeaveManagement({super.key, required this.department});

  @override
  State<DivLeaveManagement> createState() => _DivLeaveManagementState();
}

class _DivLeaveManagementState extends State<DivLeaveManagement> {
  String activeTab = "Leave";
  late String selectedDepartment;
  String selectedStatus = "All";
  bool isLoading = true;
  bool isActionLoading = false;

  List<Map<String, dynamic>> teamLeaves = [];
  List<Map<String, dynamic>> teamPermissions = [];
  Set<String> expandedItems = {};
  final Set<String> _rejecting = {};
  final Map<String, TextEditingController> _rejectReasons = {};
  String? _loginUserId;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  final statusTabs = const ["All", "Pending", "Approved", "Rejected"];

  List<String> childDepartments = [];

  String get _loginDepartment => widget.department.trim();

  bool _isLoginDepartment(String department) {
    final login = _loginDepartment;
    if (login.isEmpty) return false;
    return DivisionConfig.isAllowedDepartment(department, [login]);
  }

  List<String> get departments {
    final chips = <String>[];
    for (final dept in childDepartments) {
      if (_isLoginDepartment(dept)) continue;
      if (!DivisionConfig.isAllowedDepartment(dept, chips)) {
        chips.add(dept);
      }
    }
    return chips;
  }

  @override
  void dispose() {
    for (final controller in _rejectReasons.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedDepartment = "All";
    _init();
  }

  Future<void> _init() async {
    await _loadLoginUser();
    try {
      final login = _loginDepartment;
      var names = await AdminService.getMySubDepartments(
        headDepartment: login.isEmpty ? null : login,
      );
      if (names.isEmpty) {
        names = await AdminService.getMySubDepartments();
      }
      childDepartments = [
        for (final name in names)
          if (!_isLoginDepartment(name)) name,
      ];
    } catch (_) {}
    await _loadData();
  }

  Future<void> _loadLoginUser() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    _loginUserId = JwtHelper.getuid(token)?.toString().trim();
  }

  bool _canApproveOrReject(Map<String, dynamic> item) {
    final senderId =
        (item["senderId"] ??
                item["SenderId"] ??
                item["userId"] ??
                item["uid"] ??
                item["staffId"] ??
                "")
            .toString()
            .trim();
    if (_loginUserId != null &&
        senderId.isNotEmpty &&
        senderId == _loginUserId) {
      return false;
    }

    final senderRole =
        (item["senderRole"] ?? item["role"] ?? item["Role"] ?? "")
            .toString()
            .trim();
    if (senderRole == AppRoles.divisionHead) return false;

    return true;
  }

  String _statusOf(Map<String, dynamic> item) {
    return (item["status"] ?? "").toString().trim().toLowerCase();
  }

  bool _isPending(Map<String, dynamic> item) => _statusOf(item) == "pending";

  String _departmentOf(Map<String, dynamic> item) {
    return (item["department"] ?? item["dept"] ?? item["departmentName"] ?? "")
        .toString();
  }

  int? _idOf(Map<String, dynamic> item) {
    return int.tryParse(
      (item["id"] ?? item["leaveId"] ?? item["permissionId"] ?? "").toString(),
    );
  }

  List<Map<String, dynamic>> _asMaps(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) {
      final list = data["data"] ?? data["items"] ?? data["leaves"] ?? data["permissions"];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _uniqueById(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final item in items) {
      final key = (item["id"] ?? item["leaveId"] ?? item["permissionId"] ?? "")
          .toString();
      final fallback =
          "${_departmentOf(item)}_${item["name"]}_${item["fromDate"] ?? item["date"]}_${item["reason"]}";
      final id = key.isNotEmpty ? key : fallback;
      if (!seen.add(id)) continue;
      unique.add(item);
    }
    return unique;
  }

  bool _isAllowedDept(String department, List<String> allowed) {
    if (department.trim().isEmpty) return true;
    return DivisionConfig.isAllowedDepartment(department, allowed);
  }

  void _showTop(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showTopMessage = false);
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        expandedItems.clear();
      });
    }

    final allowed = departments;

    try {
      final departmentByUserId = <int, String>{};
      try {
        final staff = await AdminService.getEmployeesByDepartments(allowed);
        departmentByUserId.addAll(
          SuperAdminService.departmentByUserId(staff),
        );
      } catch (_) {}

      bool receivedForDivision(Map<String, dynamic> item) {
        final senderId = int.tryParse(
          (item["senderId"] ??
                  item["SenderId"] ??
                  item["userId"] ??
                  item["uid"] ??
                  item["staffId"] ??
                  "")
              .toString(),
        );
        if (_loginUserId != null &&
            senderId != null &&
            senderId.toString() == _loginUserId) {
          return false;
        }
        final department = _departmentOf(item).trim();
        if (_isLoginDepartment(department)) return false;
        if (department.isEmpty || allowed.isEmpty) return true;
        return _isAllowedDept(department, allowed);
      }

      final loadedTeamLeaves = <Map<String, dynamic>>[];
      final loadedTeamPermissions = <Map<String, dynamic>>[];

      try {
        final leaves = await SuperAdminService.getLeaveList();
        SuperAdminService.attachSenderDepartments(leaves, departmentByUserId);
        loadedTeamLeaves.addAll(
          leaves.where(receivedForDivision).where((item) => !_isHolidayLeave(item)),
        );
      } catch (_) {}

      try {
        final leaves = _asMaps(await AdminService.getDepartmentLeaves());
        SuperAdminService.attachSenderDepartments(leaves, departmentByUserId);
        loadedTeamLeaves.addAll(
          leaves.where(receivedForDivision).where((item) => !_isHolidayLeave(item)),
        );
      } catch (_) {}

      try {
        final permissions = await SuperAdminService.getPermissionList();
        SuperAdminService.attachSenderDepartments(
          permissions,
          departmentByUserId,
        );
        loadedTeamPermissions.addAll(permissions.where(receivedForDivision));
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        teamLeaves = _uniqueById(loadedTeamLeaves);
        teamPermissions = _uniqueById(loadedTeamPermissions);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _sourceItems {
    return activeTab == "Leave" ? teamLeaves : teamPermissions;
  }

  List<Map<String, dynamic>> get _departmentScopedItems {
    if (selectedDepartment == "All") return _sourceItems;
    return _sourceItems.where((item) {
      return DivisionConfig.isAllowedDepartment(_departmentOf(item), [
        selectedDepartment,
      ]);
    }).toList();
  }

  Map<String, int> get _statusCounts {
    final items = _departmentScopedItems;
    var pending = 0;
    var approved = 0;
    var rejected = 0;
    for (final item in items) {
      switch (_statusOf(item)) {
        case "pending":
          pending++;
        case "approved":
          approved++;
        case "rejected":
          rejected++;
      }
    }
    return {
      "All": items.length,
      "Pending": pending,
      "Approved": approved,
      "Rejected": rejected,
    };
  }

  List<Map<String, dynamic>> get _filteredItems {
    return _departmentScopedItems.where((item) {
      if (selectedStatus != "All" &&
          _statusOf(item) != selectedStatus.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByMonth(
    List<Map<String, dynamic>> data,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in data) {
      final dateString =
          item["fromDate"] ?? item["date"] ?? item["submittedDate"];
      final date = dateString != null
          ? DateTime.tryParse(dateString.toString()) ?? DateTime.now()
          : DateTime.now();
      final key = DateFormat("MMMM yyyy").format(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  bool _isHolidayLeave(Map<String, dynamic> item) {
    final fields = [
      item['leaveTyp'],
      item['leavecategory'],
      item['leaveCategory'],
      item['LeaveTyp'],
      item['leaveType'],
      item['type'],
      item['LeaveType'],
    ];
    for (final field in fields) {
      final raw = (field ?? '').toString().trim();
      if (raw.isEmpty || raw.toLowerCase() == 'null') continue;
      final parts = raw
          .split(RegExp(r'[,/|]'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;
      if (parts.every((part) => part.toLowerCase().contains('holiday'))) {
        return true;
      }
    }
    return false;
  }

  String _withoutHoliday(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty || raw == 'null') return '';
    final kept = raw
        .split(RegExp(r'[,/|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && !part.toLowerCase().contains('holiday'))
        .toList();
    return kept.join(', ');
  }

  String _leaveCategory(Map<String, dynamic> item) {
    return _shown(
      _withoutHoliday(item['leaveTyp'] ?? item['leavecategory'] ?? item['leaveCategory']),
    );
  }

  String _leaveDay(Map<String, dynamic> item) {
    return _shown(_withoutHoliday(item['leaveType'] ?? item['type']));
  }

  String _leaveTypeOf(Map<String, dynamic> item) {
    final type = _withoutHoliday(item["leaveType"] ?? item["type"]);
    final session = _withoutHoliday(item["leaveTyp"] ?? item["leavecategory"]);
    if (type.isNotEmpty && session.isNotEmpty) return "$type - $session";
    if (type.isNotEmpty) return type;
    if (session.isNotEmpty) return session;
    return "-";
  }

  String _formatDate(dynamic date) {
    return TimeUtils.formatDateValue(date, empty: "-");
  }

  String _formatTime(dynamic time) {
    return TimeUtils.formatTime12(time, empty: "-");
  }

  String _shown(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty || text == 'null' ? '—' : text;
  }

  String _rejectWhy(Map<String, dynamic> item) {
    if (_statusOf(item) != 'rejected') return '—';
    return _shown(item['rejectionReason']);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return WebTheme.brandOf(context);
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _departmentBanner() {
    final options = ["All", ...departments];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map(_buildDeptChip).toList(),
      ),
    );
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == dept;
    final label = dept == "All" ? "All" : dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;
    final dark = WebTheme.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          selectedDepartment = dept;
          expandedItems.clear();
          _rejecting.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? secondary
                : dark
                    ? WebTheme.surfaceOf(context)
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? secondary
                  : dark
                      ? WebTheme.lineOf(context)
                      : const Color(0xFFD0D5D2),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : dark
                          ? WebTheme.inkOf(context)
                          : secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _filterColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFE8A317);
      case "Approved":
        return const Color(0xFF2E9B57);
      case "Rejected":
        return const Color(0xFFD64545);
      default:
        return WebTheme.brandOf(context);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "Pending":
        return Icons.hourglass_top_rounded;
      case "Approved":
        return Icons.check_circle_rounded;
      case "Rejected":
        return Icons.cancel_rounded;
      default:
        return Icons.layers_rounded;
    }
  }

  Widget _buildStatusFilters() {
    final counts = _statusCounts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: WebTheme.isDark(context)
              ? WebTheme.surfaceOf(context)
              : const Color(0xFFF3F5F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: statusTabs.map((status) {
            final selected = selectedStatus == status;
            final color = _filterColor(status);
            final count = counts[status] ?? 0;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedStatus = status;
                  expandedItems.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 18,
                        color: selected ? Colors.white : color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : WebTheme.isDark(context)
                                  ? WebTheme.mutedOf(context)
                                  : const Color(0xFF5C6560),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _tabButton(String title) {
    final selected = activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = title;
            expandedItems.clear();
            _rejecting.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approve(Map<String, dynamic> item, bool isPermission) async {
    final id = _idOf(item);
    if (id == null) {
      _showTop("Invalid ${isPermission ? "permission" : "leave"} ID.");
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      "Approve",
      isPermission ? "Permission" : "Leave",
    );
    if (confirmed != true) return;

    setState(() => isActionLoading = true);
    try {
      final success = isPermission
          ? await AdminService.updatePermissionStatus(
              id: id,
              status: "Approved",
            )
          : await AdminService.updateLeaveStatus(id: id, status: "Approved");

      _showTop(
        success
            ? "${isPermission ? "Permission" : "Leave"} approved successfully"
            : "Failed to approve ${isPermission ? "permission" : "leave"}",
        isError: !success,
      );
      if (success) await _loadData();
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  Future<String?> _askRejectReason() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject leave'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    final note = controller.text.trim();
    controller.dispose();
    if (ok != true || note.isEmpty) return null;
    return note;
  }

  Future<void> _reject(
    Map<String, dynamic> item,
    bool isPermission, {
    String? reason,
  }) async {
    final id = _idOf(item);
    if (id == null) {
      _showTop("Invalid ${isPermission ? "permission" : "leave"} ID.");
      return;
    }

    var note = reason?.trim() ?? '';
    if (!isPermission && note.isEmpty) {
      final entered = await _askRejectReason();
      if (!mounted) return;
      if (entered == null) return;
      note = entered;
    }

    setState(() => isActionLoading = true);
    try {
      final success = isPermission
          ? await AdminService.updatePermissionStatus(
              id: id,
              status: "Rejected",
            )
          : await AdminService.updateLeaveStatus(
              id: id,
              status: "Rejected",
              reason: note,
            );

      _showTop(
        success
            ? "${isPermission ? "Permission" : "Leave"} rejected successfully"
            : "Failed to reject ${isPermission ? "permission" : "leave"}",
        isError: !success,
      );
      if (success) await _loadData();
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  ButtonStyle _tabStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return WebTheme.brand;
        return WebTheme.surfaceOf(context);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return WebTheme.inkOf(context);
      }),
      side: WidgetStateProperty.all(
        BorderSide(color: WebTheme.brand.withValues(alpha: 0.45)),
      ),
    );
  }

  Widget _webLeave() {
    final items = _filteredItems;
    final isPermission = activeTab == 'Permission';
    final pending = items.where(_isPending).length;
    return Scaffold(
      backgroundColor: WebTheme.canvasOf(context),
      body: RequestWorkspace(
        title: 'Leave & Permission',
        subtitle: 'Review your team requests',
        loading: isLoading,
        scrollable: true,
        banner: _departmentBanner(),
        filters: statusTabs,
        selectedFilter: selectedStatus,
        onFilter: (value) => setState(() {
          selectedStatus = value;
          expandedItems.clear();
        }),
        trailing: SegmentedButton<String>(
          style: _tabStyle(),
          segments: const [
            ButtonSegment(value: 'Leave', label: Text('Leave')),
            ButtonSegment(value: 'Permission', label: Text('Permission')),
          ],
          selected: {activeTab},
          onSelectionChanged: (value) {
            setState(() {
              activeTab = value.first;
              selectedStatus = 'All';
              expandedItems.clear();
              _rejecting.clear();
            });
          },
        ),
        stats: [
          WorkspaceStat(label: 'Showing', value: '${items.length}', icon: Icons.event_available_rounded, color: WebTheme.brandOf(context)),
          WorkspaceStat(label: 'Pending', value: '$pending', icon: Icons.hourglass_top_rounded, color: const Color(0xFFB45309)),
        ],
        emptyTitle: isPermission ? 'No permission found' : 'No leave found',
        columns: isPermission
            ? const ['Name', 'Designation', 'From time', 'To time', 'Total hours', 'Reason', 'Applied on', 'Apply date']
            : const [
                'Name',
                'Designation',
                'Contact number',
                'Leave type',
                'Day',
                'Applied on',
                'Leave date',
                'Reason',
                'Reject reason',
              ],
        records: [
          for (final item in items)
            WorkspaceRecord(
              status: _statusOf(item),
              approvedColor: WebTheme.brandOf(context),
              values: isPermission
                  ? [
                      (item['name'] ?? '').toString(),
                      _shown(item['designation']),
                      _formatTime(item['fromTime'] ?? item['FromTime']),
                      _formatTime(item['toTime'] ?? item['ToTime']),
                      '${item['totalHours'] ?? item['totalhours'] ?? '—'} hours',
                      _shown(item['reason']),
                      _shown(AppHelpers.formatDate((item['submittedDate'] ?? '').toString())),
                      _formatDate(item['date'] ?? item['fromDate']),
                    ]
                  : [
                      (item['name'] ?? '').toString(),
                      _shown(item['designation']),
                      _shown(item['contactNumber']),
                      _leaveCategory(item),
                      _leaveDay(item),
                      _shown(AppHelpers.formatDate((item['submittedDate'] ?? '').toString())),
                      _formatDate(item['fromDate'] ?? item['date']),
                      _shown(item['reason']),
                      _rejectWhy(item),
                    ],
              actions: _isPending(item) && _canApproveOrReject(item)
                  ? [
                      workspaceAction('Approve', () => _approve(item, isPermission), filled: true),
                      workspaceAction('Reject', () => _reject(item, isPermission), color: WebTheme.danger),
                    ]
                  : const [],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final grouped = _groupByMonth(items);
    final isPermission = activeTab == "Permission";

    final web = WebPushedChrome.isWeb(context);
    if (web) return _webLeave();
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        title: web ? null : Text(isPermission ? "Permissions" : "Leaves"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: web ? null : PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _tabButton("Leave"),
                const SizedBox(width: 5),
                _tabButton("Permission"),
              ],
            ),
          ),
        ),
      ),
      body: WebPushedChrome.body(
        context,
        title: 'Leave & Permission',
        subtitle: 'Leaves received from your departments',
        panel: false,
        child: Stack(
        children: [
          Column(
            children: [
              if (web)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: WebChoiceBar(
                    options: const ["Leave", "Permission"],
                    selected: activeTab,
                    onSelected: (value) {
                      setState(() {
                        activeTab = value;
                        expandedItems.clear();
                        _rejecting.clear();
                      });
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ["All", ...departments]
                        .map(_buildDeptChip)
                        .toList(),
                  ),
                ),
              ),
              _buildStatusFilters(),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? const Center(child: RotatingFlower())
                    : items.isEmpty
                    ? Center(
                        child: Text(
                          selectedStatus == "All"
                              ? (isPermission
                                    ? "No permissions found"
                                    : "No leaves found")
                              : "No ${selectedStatus.toLowerCase()} ${isPermission ? "permissions" : "leaves"} found",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          children: grouped.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                ...entry.value.map(
                                  (item) => _buildItem(item, isPermission),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 16 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              child: Msgsnackbar(
                context,
                message: _topMessage!,
                isError: _isErrorMessage,
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _itemKey(Map<String, dynamic> item) {
    return (item["id"] ??
            item["leaveId"] ??
            item["permissionId"] ??
            "${item["name"]}_${item["fromDate"] ?? item["date"]}_${item["reason"]}")
        .toString();
  }

  Widget _buildItem(Map<String, dynamic> item, bool isPermission) {
    final key = _itemKey(item);
    final isExpanded = expandedItems.contains(key);
    final department = _departmentOf(item);
    final status = (item["status"] ?? "Pending").toString();
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: WebTheme.isDark(context)
              ? WebTheme.lineOf(context)
              : Theme.of(context).colorScheme.secondary,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedItems.remove(key);
                } else {
                  expandedItems.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item["name"] ?? "").toString(),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        if (department.isNotEmpty)
                          Text(
                            department,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        const SizedBox(height: 4),
                        if (isPermission) ...[
                          Text(
                            _formatDate(item["date"] ?? item["fromDate"]),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${item["totalHours"] ?? item["totalhours"] ?? "-"} hours",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ] else ...[
                          Text(
                            _leaveTypeOf(item),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Applied on ${AppHelpers.formatDate((item["submittedDate"] ?? item["fromDate"] ?? item["date"])?.toString())}",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade200),
                  _infoRow("Name", item["name"]),
                  _infoRow("Department", department.isEmpty ? "-" : department),
                  if (isPermission) ...[
                    _infoRow(
                      "Date",
                      _formatDate(item["date"] ?? item["fromDate"]),
                    ),
                    _infoRow("From Time", _formatTime(item["fromTime"])),
                    _infoRow("To Time", _formatTime(item["toTime"])),
                    _infoRow(
                      "Total Hours",
                      item["totalHours"] ?? item["totalhours"] ?? "-",
                    ),
                    _infoRow("Reason", item["reason"]),
                    _infoRow(
                      "Applied on",
                      AppHelpers.formatDate(item["submittedDate"]?.toString()),
                    ),
                    _infoRow(
                      "Apply date",
                      _formatDate(item["date"] ?? item["fromDate"]),
                    ),
                  ] else ...[
                    _infoRow("Leave Type", _leaveTypeOf(item)),
                    _infoRow("Designation", item["designation"]),
                    _infoRow("Contact", item["contactNumber"]),
                    _infoRow(
                      "From Date",
                      _formatDate(item["fromDate"] ?? item["date"]),
                    ),
                    _infoRow(
                      "To Date",
                      _formatDate(item["toDate"] ?? item["fromDate"]),
                    ),
                    _infoRow("Reason", item["reason"]),
                    if (_statusOf(item) == "approved")
                      _infoRow(
                        "Approved Date",
                        AppHelpers.formatDate(
                          (item["approvedDate"] ?? item["approvedate"])
                              ?.toString(),
                        ),
                      ),
                    if (_statusOf(item) == "rejected")
                      _infoRow(
                        "Rejected Reason",
                        item["rejectionReason"] ?? item["reason"],
                      ),
                  ],
                  if (_isPending(item) && _canApproveOrReject(item)) ...[
                    const SizedBox(height: 10),
                    _actionButtons(item, isPermission, key),
                  ] else if (_isPending(item) && !_canApproveOrReject(item))
                    _infoRow("Approval", "Awaiting Director approval"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButtons(
    Map<String, dynamic> item,
    bool isPermission,
    String key,
  ) {
    final showRejectBox = _rejecting.contains(key);
    _rejectReasons.putIfAbsent(key, TextEditingController.new);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: "Approve",
                isLoading: isActionLoading,
                onPressed: () => _approve(item, isPermission),
                color: Theme.of(context).colorScheme.primary,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                text: "Reject",
                isLoading: isActionLoading,
                onPressed: () async {
                  if (isPermission) {
                    final confirmed = await showConfirmDialog(
                      context,
                      "Reject",
                      "Permission",
                    );
                    if (confirmed == true) {
                      await _reject(item, true);
                    }
                    return;
                  }
                  setState(() {
                    if (showRejectBox) {
                      _rejecting.remove(key);
                    } else {
                      _rejecting.add(key);
                    }
                  });
                },
                color: Theme.of(context).colorScheme.error,
                txtcolor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        if (!isPermission && showRejectBox) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _rejectReasons[key],
            style: Theme.of(context).textTheme.headlineLarge,
            decoration: InputDecoration(
              hintText: "Enter rejection reason",
              hintStyle: Theme.of(context).textTheme.labelSmall,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppButton(
            text: "Submit Rejection",
            isLoading: isActionLoading,
            onPressed: () => _reject(
              item,
              false,
              reason: _rejectReasons[key]?.text,
            ),
            color: Theme.of(context).colorScheme.error,
            txtcolor: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
