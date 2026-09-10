import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/reports_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class DivLeaveManagement extends StatefulWidget {
  final String department;
  const DivLeaveManagement({super.key, required this.department});

  @override
  State<DivLeaveManagement> createState() => _DivLeaveManagementState();
}

class _DivLeaveManagementState extends State<DivLeaveManagement> {
  String activeTab = "Leave";
  String selectedDepartment = "All";
  String selectedStatus = "Pending";
  bool isLoading = true;
  bool isActionLoading = false;

  List<Map<String, dynamic>> leaves = [];
  List<Map<String, dynamic>> permissions = [];
  Set<String> expandedItems = {};
  final Set<String> _rejecting = {};
  final Map<String, TextEditingController> _rejectReasons = {};

  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  final statusTabs = const ["All", "Pending", "Approved", "Rejected"];

  List<String> get departments => [
    if (widget.department.trim().isNotEmpty) widget.department,
    ...DivisionConfig.childDepartments(widget.department),
  ];

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
    _loadData();
  }

  bool get _isOperationsSelected => DivisionConfig.isAllowedDepartment(
    selectedDepartment,
    const ["Operations Department"],
  );

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

  int? _userIdOf(Map<String, dynamic> item) {
    final value =
        item["userId"] ??
        item["staffId"] ??
        item["employeeId"] ??
        item["uid"] ??
        item["senderId"];
    if (value == null) return null;
    return int.tryParse(value.toString());
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

    try {
      final allowed = departments;
      final loadedLeaves = <Map<String, dynamic>>[];
      final loadedPermissions = <Map<String, dynamic>>[];

      final staff = await AdminService.getEmployeesByDepartments(allowed);
      final namesById = {
        for (final user in staff)
          if (user.name.trim().isNotEmpty) user.userId: user.name.trim(),
      };

      final reports = await Future.wait(
        staff.map((user) async {
          try {
            final report = await ReportsService.getFullReport(
              userId: user.userId,
            );
            return MapEntry(user, report);
          } catch (_) {
            return MapEntry(user, <String, dynamic>{});
          }
        }),
      );

      for (final entry in reports) {
        final user = entry.key;
        final report = entry.value;

        for (final raw in List<dynamic>.from(report["leaveList"] ?? [])) {
          final item = Map<String, dynamic>.from(raw as Map);
          item["name"] = user.name;
          item["department"] ??= user.department;
          if (_isAllowedDept(_departmentOf(item), allowed)) {
            loadedLeaves.add(item);
          }
        }

        for (final raw in List<dynamic>.from(report["permissionList"] ?? [])) {
          final item = Map<String, dynamic>.from(raw as Map);
          item["name"] = user.name;
          item["department"] ??= user.department;
          if (_isAllowedDept(_departmentOf(item), allowed)) {
            loadedPermissions.add(item);
          }
        }
      }

      try {
        for (final item in _asMaps(await AdminService.getDepartmentLeaves())) {
          final userId = _userIdOf(item);
          if ((item["name"] ?? "").toString().trim().isEmpty &&
              userId != null &&
              namesById[userId] != null) {
            item["name"] = namesById[userId];
          }
          if (_isAllowedDept(_departmentOf(item), allowed)) {
            loadedLeaves.add(item);
          }
        }
      } catch (_) {}

      try {
        for (final item in _asMaps(await AdminService.getDepartmentPermissions())) {
          final userId = _userIdOf(item);
          if ((item["name"] ?? "").toString().trim().isEmpty &&
              userId != null &&
              namesById[userId] != null) {
            item["name"] = namesById[userId];
          }
          if (_isAllowedDept(_departmentOf(item), allowed)) {
            loadedPermissions.add(item);
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        leaves = _uniqueById(loadedLeaves);
        permissions = _uniqueById(loadedPermissions);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    final source = activeTab == "Leave" ? leaves : permissions;
    return source.where((item) {
      if (selectedDepartment != "All" &&
          !DivisionConfig.isAllowedDepartment(_departmentOf(item), [
            selectedDepartment,
          ])) {
        return false;
      }

      if (_isOperationsSelected) {
        if (selectedStatus != "All" &&
            _statusOf(item) != selectedStatus.toLowerCase()) {
          return false;
        }
        return true;
      }

      return _statusOf(item) == "approved" || _statusOf(item).isEmpty;
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
    final type = (item["type"] ?? "").toString().trim();
    final session = (item["leavecategory"] ?? "").toString().trim();
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
          if (DivisionConfig.isAllowedDepartment(dept, const [
            "Operations Department",
          ])) {
            selectedStatus = "Pending";
          }
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

  Widget _buildStatusChip(String status) {
    final selected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          selectedStatus = status;
          expandedItems.clear();
        }),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : const Color(0xFFD0D5D2),
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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
              if (_isOperationsSelected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: statusTabs.map(_buildStatusChip).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? const Center(child: RotatingFlower())
                    : items.isEmpty
                    ? Center(
                        child: Text(
                          !_isOperationsSelected
                              ? (isPermission
                                    ? "No approved permissions found"
                                    : "No approved leaves found")
                              : selectedStatus == "All"
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
                  if (_isOperationsSelected && _isPending(item)) ...[
                    const SizedBox(height: 10),
                    _actionButtons(item, isPermission, key),
                  ],
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
