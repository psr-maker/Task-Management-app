import 'package:flutter/material.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/dept_compensation.dart/add_compen.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/utils/jwt_helper.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class DivCompensation extends StatefulWidget {
  final String department;
  const DivCompensation({super.key, required this.department});

  @override
  State<DivCompensation> createState() => _DivCompensationState();
}

class _DivCompensationState extends State<DivCompensation> {
  bool isLoading = true;
  String selectedDepartment = "";
  List<String> departments = [];
  List<Map<String, dynamic>> extraWorks = [];
  List<Map<String, dynamic>> ownWorks = [];
  Set<int> _managerIds = {};
  int? _myId;
  int? _processingId;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final names = <String>[];

    void addDepartment(String name) {
      final value = name.trim();
      if (value.isEmpty) return;
      if (names.any(
        (item) => DivisionConfig.isAllowedDepartment(value, [item]),
      )) {
        return;
      }
      names.add(value);
    }

    addDepartment(widget.department);
    try {
      final subs = await AdminService.getMySubDepartments(
        headDepartment: widget.department,
      );
      for (final name in subs) {
        addDepartment(name);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      departments = names;
      selectedDepartment = names.isNotEmpty ? names.first : widget.department;
    });
    await _loadData();
  }

  dynamic _field(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) return item[key];
    }
    final lower = {
      for (final entry in item.entries) entry.key.toString().toLowerCase(): entry.value,
    };
    for (final key in keys) {
      final value = lower[key.toLowerCase()];
      if (value != null) return value;
    }
    return null;
  }

  String _status(Map<String, dynamic> item) {
    return (_field(item, ["status"]) ?? "").toString().trim();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "");
  }

  int? _staffId(Map<String, dynamic> item) {
    return _asInt(_field(item, ["staffId", "userId", "employeeId"]));
  }

  int? _extraWorkId(Map<String, dynamic> item) {
    return _asInt(_field(item, ["id", "extraWorkId", "compensationId"]));
  }

  bool _belongsToManager(Map<String, dynamic> item, Set<int> managerIds) {
    final role = (_field(item, ["staffRole", "senderRole"]) ?? "").toString();
    if (role.trim().isNotEmpty && AppRoles.isManager(role)) return true;
    final staff = _field(item, ["staff", "employee"]);
    if (staff is Map &&
        AppRoles.isManager(
          (staff["role"] ?? staff["Role"] ?? staff["staffRole"] ?? "")
              .toString(),
        )) {
      return true;
    }
    final staffId = _staffId(item);
    return staffId != null && managerIds.contains(staffId);
  }

  bool _needsApproval(Map<String, dynamic> item) {
    return _status(item).toLowerCase() == "accepted" &&
        _isManagerCompensation(item);
  }

  bool _isManagerCompensation(Map<String, dynamic> item) {
    return _belongsToManager(item, _managerIds);
  }

  int _statusRank(Map<String, dynamic> item) {
    switch (_status(item).toLowerCase()) {
      case "pending":
        return 0;
      case "accepted":
        return 1;
      default:
        return 2;
    }
  }

  ({String text, Color color}) _statusInfo(Map<String, dynamic> item) {
    switch (_status(item).toLowerCase()) {
      case "approved":
        return (text: "Approved", color: Colors.green);
      case "accepted":
        return (text: "Staff Accepted", color: Colors.blueAccent);
      case "staffrejected":
      case "managerrejected":
      case "rejected":
        return (text: "Rejected", color: Colors.redAccent);
      default:
        return (text: "Pending", color: Colors.amber.shade800);
    }
  }

  Future<void> _selectDepartment(String department) async {
    if (selectedDepartment == department) return;
    setState(() => selectedDepartment = department);
    await _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> result = [];
      Set<int> managerIds = {};
      try {
        result = await OvertimeService.getExtraWorkByDepartments([
          selectedDepartment,
        ]);
      } catch (_) {}
      try {
        final employees = await AdminService.getEmployeesByDepartment(
          selectedDepartment,
        );
        managerIds = employees
            .where((user) => AppRoles.isManager(user.role))
            .map((user) => user.userId)
            .toSet();
      } catch (_) {}

      if (!mounted) return;
      final token = await AuthService.getToken();
      final myId = int.tryParse(
        '${token == null ? '' : JwtHelper.getuid(token) ?? ''}',
      );
      final mine = <Map<String, dynamic>>[];
      final seen = <int>{};

      void addOwn(Map<String, dynamic> item, {bool personalList = false}) {
        final staff = _staffId(item);
        if (myId != null && staff != null && staff != myId) return;
        if (!personalList && staff != myId) return;
        if (personalList && staff == null) {
          final id = _extraWorkId(item);
          final belongsToSomeoneElse = id != null &&
              result.any((other) {
                final otherStaff = _staffId(other);
                return _extraWorkId(other) == id &&
                    otherStaff != null &&
                    otherStaff != myId;
              });
          if (belongsToSomeoneElse) return;
        }
        final id = _extraWorkId(item);
        if (id != null && seen.contains(id)) return;
        if (id != null) seen.add(id);
        mine.add(item);
      }

      try {
        final personal = await OvertimeService.getMyExtraWork();
        for (final item in personal) {
          addOwn(item, personalList: true);
        }
      } catch (_) {}

      final headDepartment = widget.department.trim();
      if (headDepartment.isNotEmpty &&
          !DivisionConfig.isAllowedDepartment(headDepartment, [
            selectedDepartment,
          ])) {
        try {
          final headWorks = await OvertimeService.getExtraWorkByDepartments([
            headDepartment,
          ]);
          for (final item in headWorks) {
            addOwn(item);
          }
        } catch (_) {}
      }
      for (final item in result) {
        addOwn(item);
      }
      final visible = result.where((item) {
        final status = _status(item).toLowerCase();
        return status == "approved" ||
            status == "pending" ||
            status == "accepted";
      }).toList();
      final ownIds = mine.map(_extraWorkId).whereType<int>().toSet();
      final ownVisible = mine.where((item) {
        final status = _status(item).toLowerCase();
        return status == "approved" ||
            status == "pending" ||
            status == "accepted" ||
            status.isEmpty;
      }).toList();
      visible.removeWhere((item) {
        final id = _extraWorkId(item);
        return id != null && ownIds.contains(id);
      });
      visible.sort((a, b) => _statusRank(a).compareTo(_statusRank(b)));
      ownVisible.sort((a, b) => _statusRank(a).compareTo(_statusRank(b)));
      final viewingOwn = DivisionConfig.isAllowedDepartment(
        selectedDepartment,
        [widget.department],
      );
      final managerWorks = visible
          .where((item) => _belongsToManager(item, managerIds))
          .toList();
      setState(() {
        _managerIds = managerIds;
        _myId = myId;
        ownWorks = viewingOwn ? ownVisible : [];
        extraWorks = viewingOwn ? [] : managerWorks;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        extraWorks = [];
        ownWorks = [];
        isLoading = false;
      });
    }
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == dept;
    final label = dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectDepartment(dept),
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

  String _formatDate(dynamic value) {
    return TimeUtils.formatDateValue(value, empty: "-");
  }

  String _formatTime(dynamic value) {
    return TimeUtils.formatTime12(value, empty: "--:--");
  }

  String _formatHours(dynamic value) {
    if (value == null) return "0";
    final number = double.tryParse(value.toString());
    if (number == null) return value.toString();
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toStringAsFixed(2);
  }

  String _formatWorkType(String value) {
    switch (value) {
      case "WeeklyOff":
        return "Weekly Off";
      case "PublicHoliday":
        return "Public Holiday";
      case "CompanyHoliday":
        return "Company Holiday";
      default:
        return value.isEmpty ? "Other" : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebPushedChrome.background(context),
      appBar: AppBar(
        title: WebPushedChrome.isWeb(context)
            ? null
            : const Text("Compensation Work"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedDepartment.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateExtraWorkPage(
                      department: selectedDepartment,
                    ),
                  ),
                );
                if (!mounted || created != true) return;
                _loadData();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: WebPushedChrome.body(
        context,
        title: 'Compensation Work',
        subtitle: 'Pending and approved compensation by department',
        panel: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: departments.map(_buildDeptChip).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : extraWorks.isEmpty && ownWorks.isEmpty
                  ? Center(
                      child: Text(
                        "No compensation found for $selectedDepartment",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(15),
                        children: [
                          if (ownWorks.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "My Compensation",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ...ownWorks.map(_card),
                            const SizedBox(height: 8),
                          ],
                          ...extraWorks.map(_card),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final staffName = (_field(item, ["staffName", "name"]) ?? "")
        .toString()
        .trim();
    final taskName = (_field(item, ["taskName", "task", "title"]) ?? "")
        .toString()
        .trim();
    final reason = (_field(item, ["reason"]) ?? "").toString().trim();
    final workType = (_field(item, ["workType"]) ?? "").toString();
    final managerRemarks = (_field(item, ["managerRemarks"]) ?? "")
        .toString()
        .trim();
    final staffRemarks = (_field(item, ["staffRemarks"]) ?? "")
        .toString()
        .trim();
    final totalHours = _field(item, [
      "expectedHours",
      "totalHours",
      "totalhours",
    ]);
    final workDate = _field(item, ["workDate", "date"]);
    final startTime = _field(item, ["startTime"]);
    final endTime = _field(item, ["endTime"]);
    final waiting = _needsApproval(item) && !_isOwn(item);
    final canAccept = _isOwn(item) && _status(item).toLowerCase() == "pending";
    final statusInfo = _statusInfo(item);
    final statusText = statusInfo.text;
    final statusColor = statusInfo.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: WebPushedChrome.isWeb(context)
          ? WebTheme.card(context)
          : BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    staffName.isNotEmpty ? staffName[0].toUpperCase() : "?",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffName.isEmpty ? "Unknown Staff" : staffName,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        taskName.isEmpty ? "No Task" : taskName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 125),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _infoRow(Icons.calendar_today_outlined, _formatDate(workDate)),
            const SizedBox(height: 10),
            _infoRow(
              Icons.access_time_rounded,
              "${_formatTime(startTime)} - ${_formatTime(endTime)}",
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.timer_outlined,
              "${_formatHours(totalHours)} Hours",
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.work_outline_rounded, _formatWorkType(workType)),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text("Reason", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 5),
            Text(
              reason.isEmpty ? "No reason provided" : reason,
              style: const TextStyle(fontSize: 13),
            ),
            if (staffRemarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _remarksBox("Staff Remarks", staffRemarks),
            ],
            if (managerRemarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _remarksBox("Manager Remarks", managerRemarks),
            ],
            if (canAccept) ...[
              const SizedBox(height: 18),
              _acceptButtons(item),
            ],
            if (waiting) ...[
              const SizedBox(height: 18),
              _approvalButtons(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  bool _isOwn(Map<String, dynamic> item) {
    if (_myId == null) return false;
    return _staffId(item) == _myId;
  }

  Widget _acceptButtons(Map<String, dynamic> item) {
    final id = _extraWorkId(item);
    final busy = id != null && _processingId == id;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => _rejectOwn(item),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text("Reject"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: busy ? null : () => _acceptOwn(item),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(busy ? "Processing..." : "Accept"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 25, 77, 38),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptOwn(Map<String, dynamic> item) async {
    final id = _extraWorkId(item);
    if (id == null || _processingId != null) return;
    setState(() => _processingId = id);
    try {
      await OvertimeService.updateStaffResponse(
        extraWorkId: id,
        status: "Accepted",
      );
      if (!mounted) return;
      showAppMessage(context, "Compensation accepted", isError: false);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectOwn(Map<String, dynamic> item) async {
    final id = _extraWorkId(item);
    if (id == null || _processingId != null) return;
    final reason = await _askRejectReason();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _processingId = id);
    try {
      await OvertimeService.updateStaffResponse(
        extraWorkId: id,
        status: "StaffRejected",
        staffRemarks: reason.trim(),
      );
      if (!mounted) return;
      showAppMessage(context, "Compensation rejected", isError: false);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Widget _approvalButtons(Map<String, dynamic> item) {
    final id = _extraWorkId(item);
    final busy = id != null && _processingId == id;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => _reject(item),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text("Reject"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: busy ? null : () => _approve(item),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(busy ? "Processing..." : "Approve"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 25, 77, 38),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final id = _extraWorkId(item);
    if (id == null || _processingId != null) return;
    final confirmed = await showConfirmDialog(context, "Approve", "compensation");
    if (confirmed != true || !mounted) return;
    setState(() => _processingId = id);
    try {
      await OvertimeService.updateManagerResponse(
        extraWorkId: id,
        status: "Approved",
      );
      if (!mounted) return;
      showAppMessage(context, "Compensation approved", isError: false);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final id = _extraWorkId(item);
    if (id == null || _processingId != null) return;
    final reason = await _askRejectReason();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _processingId = id);
    try {
      await OvertimeService.updateManagerResponse(
        extraWorkId: id,
        status: "ManagerRejected",
        managerRemarks: reason.trim(),
      );
      if (!mounted) return;
      showAppMessage(context, "Compensation rejected", isError: false);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<String?> _askRejectReason() {
    var reason = "";
    var showError = false;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Reject Compensation"),
              content: TextField(
                autofocus: true,
                minLines: 3,
                maxLines: 4,
                onChanged: (value) {
                  reason = value;
                  if (showError && value.trim().isNotEmpty) {
                    setDialogState(() => showError = false);
                  }
                },
                decoration: InputDecoration(
                  hintText: "Enter rejection reason...",
                  errorText: showError ? "Rejection reason is required" : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (reason.trim().isEmpty) {
                      setDialogState(() => showError = true);
                      return;
                    }
                    Navigator.pop(dialogContext, reason.trim());
                  },
                  child: const Text("Reject"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _remarksBox(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
