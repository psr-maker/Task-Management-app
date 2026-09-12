import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';
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
  List<Map<String, dynamic>> ownLeaves = [];
  List<Map<String, dynamic>> teamPermissions = [];
  List<Map<String, dynamic>> ownPermissions = [];
  Set<String> expandedItems = {};
  final Set<String> _rejecting = {};
  final Map<String, TextEditingController> _rejectReasons = {};
  String? _loginUserId;

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  final statusTabs = const ["All", "Pending", "Approved", "Rejected"];

  List<String> get childDepartments =>
      DivisionConfig.childDepartments(widget.department);

  List<String> get departments {
    final parent = widget.department.trim();
    final children = childDepartments;
    final chips = <String>[];
    if (parent.isNotEmpty) chips.add(parent);
    for (final dept in children) {
      if (!DivisionConfig.isAllowedDepartment(dept, chips)) {
        chips.add(dept);
      }
    }
    return chips;
  }

  bool get _isOwnLeaveTab {
    final parent = widget.department.trim();
    if (parent.isEmpty || selectedDepartment == "All") return false;
    return DivisionConfig.isAllowedDepartment(selectedDepartment, [parent]);
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
    final parent = widget.department.trim();
    selectedDepartment = parent.isNotEmpty ? parent : "All";
    _init();
  }

  Future<void> _init() async {
    await _loadLoginUser();
    await _loadData();
  }

  Future<void> _loadLoginUser() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    _loginUserId = JwtHelper.getuid(token)?.toString().trim();
  }

  bool _canApproveOrReject(Map<String, dynamic> item) {
    if (_isOwnLeaveTab) return false;

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
    if (senderRole == "2" || senderRole == "3") return false;

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

    final allowed = [
      if (widget.department.trim().isNotEmpty) widget.department,
      ...childDepartments,
    ];
    final teamAllowed =
        childDepartments.isNotEmpty ? childDepartments : allowed;

    try {
      final loadedTeamLeaves = <Map<String, dynamic>>[];
      final loadedOwnLeaves = <Map<String, dynamic>>[];
      final loadedTeamPermissions = <Map<String, dynamic>>[];
      final loadedOwnPermissions = <Map<String, dynamic>>[];

      try {
        for (final item in await SuperAdminService.getLeaveList()) {
          if (_isAllowedDept(_departmentOf(item), teamAllowed) ||
              _departmentOf(item).trim().isEmpty) {
            loadedTeamLeaves.add(item);
          }
        }
      } catch (_) {}

      try {
        for (final item in _asMaps(await AdminService.getLeaves())) {
          item["department"] ??= widget.department;
          loadedOwnLeaves.add(item);
        }
      } catch (_) {}

      final departmentByUserId = <int, String>{};
      try {
        final staff = await AdminService.getEmployeesByDepartments(allowed);
        departmentByUserId.addAll(
          SuperAdminService.departmentByUserId(staff),
        );
      } catch (_) {}

      try {
        final permissions = await SuperAdminService.getPermissionList();
        SuperAdminService.attachSenderDepartments(
          permissions,
          departmentByUserId,
        );
        for (final item in permissions) {
          if (_isAllowedDept(_departmentOf(item), teamAllowed) ||
              _departmentOf(item).trim().isEmpty) {
            loadedTeamPermissions.add(item);
          }
        }
      } catch (_) {}

      try {
        for (final item in _asMaps(await AdminService.getPermissions())) {
          item["department"] ??= widget.department;
          loadedOwnPermissions.add(item);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        teamLeaves = _uniqueById(loadedTeamLeaves);
        ownLeaves = _uniqueById(loadedOwnLeaves);
        teamPermissions = _uniqueById(loadedTeamPermissions);
        ownPermissions = _uniqueById(loadedOwnPermissions);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _sourceItems {
    return activeTab == "Leave"
        ? (_isOwnLeaveTab ? ownLeaves : teamLeaves)
        : (_isOwnLeaveTab ? ownPermissions : teamPermissions);
  }

  List<Map<String, dynamic>> get _departmentScopedItems {
    return _sourceItems.where((item) {
      if (!_isOwnLeaveTab &&
          selectedDepartment != "All" &&
          !DivisionConfig.isAllowedDepartment(_departmentOf(item), [
            selectedDepartment,
          ])) {
        return false;
      }
      return true;
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

  String _leaveTypeOf(Map<String, dynamic> item) {
    final type = (item["leaveType"] ?? item["type"] ?? "").toString().trim();
    final session =
        (item["leaveTyp"] ?? item["leavecategory"] ?? "").toString().trim();
    if (type.isNotEmpty && session.isNotEmpty) return "$type - $session";
    if (type.isNotEmpty) return type;
    if (session.isNotEmpty) return session;
    return "-";
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return "-";
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return date.toString();
    return DateFormat("EEE, dd MMMM").format(parsed);
  }

  String _formatTime(dynamic time) {
    if (time == null || time.toString().isEmpty) return "-";
    final value = time.toString();
    final parts = value.split(":");
    if (parts.length >= 2) return "${parts[0]}:${parts[1]}";
    return value;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == dept;
    final label = dept == "All" ? "All" : dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;

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
            color: selected ? secondary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? secondary : const Color(0xFFD0D5D2),
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
                  color: selected ? Colors.white : secondary,
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
        return Theme.of(context).colorScheme.secondary;
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
          color: const Color(0xFFF3F5F4),
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
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
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
              reason: reason,
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

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final grouped = _groupByMonth(items);
    final isPermission = activeTab == "Permission";

    return Scaffold(
      appBar: AppBar(
        title: Text(isPermission ? "Permissions" : "Leaves"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
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
      body: Stack(
        children: [
          Column(
            children: [
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
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
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
                  ] else ...[
                    _infoRow("Leave Type", _leaveTypeOf(item)),
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
                  if (!_isOwnLeaveTab &&
                      _isPending(item) &&
                      _canApproveOrReject(item)) ...[
                    const SizedBox(height: 10),
                    _actionButtons(item, isPermission, key),
                  ] else if (!_isOwnLeaveTab &&
                      _isPending(item) &&
                      !_canApproveOrReject(item))
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
                color: Theme.of(context).colorScheme.secondary,
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
