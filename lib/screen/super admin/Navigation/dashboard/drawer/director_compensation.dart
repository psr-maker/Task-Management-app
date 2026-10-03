import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/constant/division_config.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/core/widgets/web_ui.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/dept_compensation.dart/add_compen.dart';
import 'package:staff_work_track/services/overtime_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class DirectorCompensation extends StatefulWidget {
  const DirectorCompensation({super.key});

  @override
  State<DirectorCompensation> createState() => _DirectorCompensationState();
}

class _DirectorCompensationState extends State<DirectorCompensation> {
  bool isLoading = true;
  String selectedDepartment = "All";
  List<String> departments = [];
  List<UserModel> users = [];
  List<Map<String, dynamic>> extraWorks = [];
  int? _processingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  dynamic _field(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) return item[key];
    }
    final lower = {
      for (final entry in item.entries)
        entry.key.toString().toLowerCase(): entry.value,
    };
    for (final key in keys) {
      final value = lower[key.toLowerCase()];
      if (value != null) return value;
    }
    return null;
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

  String _status(Map<String, dynamic> item) {
    return (_field(item, ["status"]) ?? "").toString().trim();
  }

  UserModel? _userFor(Map<String, dynamic> item) {
    final staffId = _staffId(item);
    if (staffId != null) {
      for (final user in users) {
        if (user.userId == staffId) return user;
      }
    }
    final name = (_field(item, ["staffName", "name"]) ?? "")
        .toString()
        .trim()
        .toLowerCase();
    if (name.isEmpty) return null;
    for (final user in users) {
      if (user.name.trim().toLowerCase() == name) return user;
    }
    return null;
  }

  bool _isLeaderWork(Map<String, dynamic> item) {
    final role = (_field(item, ["staffRole", "senderRole", "role"]) ?? "")
        .toString();
    if (AppRoles.isScoreLeader(role)) return true;
    final staff = _field(item, ["staff", "employee"]);
    if (staff is Map &&
        AppRoles.isScoreLeader(
          (staff["role"] ?? staff["Role"] ?? staff["staffRole"] ?? "")
              .toString(),
        )) {
      return true;
    }
    final user = _userFor(item);
    return user != null && AppRoles.isScoreLeader(user.role);
  }

  String _departmentOf(Map<String, dynamic> item) {
    final fromItem = (_field(item, ["department", "dept"]) ?? "")
        .toString()
        .trim();
    if (fromItem.isNotEmpty) return fromItem;
    final fromUser = _userFor(item)?.department.trim() ?? "";
    return fromUser.isEmpty ? "Other" : fromUser;
  }

  bool _inDepartment(Map<String, dynamic> item, String department) {
    if (department == "All") return true;
    return DivisionConfig.isAllowedDepartment(
      _departmentOf(item),
      [department],
    );
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

  List<Map<String, dynamic>> get _visibleWorks {
    final visible = extraWorks
        .where((item) => _inDepartment(item, selectedDepartment))
        .toList();
    visible.sort((a, b) {
      final departmentCompare = _departmentOf(
        a,
      ).toLowerCase().compareTo(_departmentOf(b).toLowerCase());
      if (departmentCompare != 0) return departmentCompare;
      final rank = _statusRank(a).compareTo(_statusRank(b));
      if (rank != 0) return rank;
      final nameA = (_field(a, ["staffName", "name"]) ?? "").toString();
      final nameB = (_field(b, ["staffName", "name"]) ?? "").toString();
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });
    return visible;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedWorks {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in _visibleWorks) {
      grouped.putIfAbsent(_departmentOf(item), () => []).add(item);
    }
    return grouped;
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      List<UserModel> loadedUsers = [];
      try {
        loadedUsers = await SuperAdminService.getAllUsers();
      } catch (_) {}

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

      for (final user in loadedUsers) {
        if (user.status.trim().toLowerCase() == "inactive") continue;
        if (!AppRoles.isScoreLeader(user.role)) continue;
        addDepartment(user.department);
      }

      List<Map<String, dynamic>> works = [];
      if (names.isNotEmpty) {
        try {
          works = await OvertimeService.getExtraWorkByDepartments(
            names,
            asDirector: true,
          );
        } catch (_) {
          for (final department in names) {
            try {
              final items = await OvertimeService.getExtraWorkByDepartments(
                [department],
                asDirector: true,
              );
              works.addAll(items);
            } catch (_) {}
          }
        }
      }

      users = loadedUsers;
      final leaderWorks = works.where(_isLeaderWork).toList();
      for (final item in leaderWorks) {
        addDepartment(_departmentOf(item));
      }
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (!mounted) return;
      setState(() {
        departments = names;
        extraWorks = leaderWorks;
        if (selectedDepartment != "All" &&
            !names.any(
              (name) => DivisionConfig.isAllowedDepartment(
                selectedDepartment,
                [name],
              ),
            )) {
          selectedDepartment = "All";
        }
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showAppMessage(
        context,
        e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  Future<void> _openApply() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateExtraWorkPage(
          department: "",
          forLeaders: true,
        ),
      ),
    );
    if (!mounted || created != true) return;
    await _loadData();
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
    final grouped = _groupedWorks;
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
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _openApply,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: WebPushedChrome.body(
        context,
        title: "Compensation Work",
        subtitle: "Compensation work by department",
        panel: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildDeptChip("All"),
                    ...departments.map(_buildDeptChip),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : grouped.isEmpty
                  ? Center(
                      child: Text(
                        selectedDepartment == "All"
                            ? "No compensation found"
                            : "No compensation found for $selectedDepartment",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(15),
                        children: [
                          for (final entry in grouped.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "${entry.key} (${entry.value.length})",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ...entry.value.map(_card),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptChip(String dept) {
    final selected = selectedDepartment == dept ||
        (dept != "All" &&
            DivisionConfig.isAllowedDepartment(selectedDepartment, [dept]));
    final label = dept == "All" ? "All" : dept.replaceAll(" Department", "");
    final secondary = Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          if (selectedDepartment == dept) return;
          setState(() => selectedDepartment = dept);
        },
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

  Widget _card(Map<String, dynamic> item) {
    final person = _userFor(item);
    final staffName = (_field(item, ["staffName", "name"]) ?? person?.name ?? "")
        .toString()
        .trim();
    final roleLabel = AppRoles.leaderLabel(
      (_field(item, ["staffRole", "role"]) ?? person?.role ?? "").toString(),
    );
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
    final waiting =
        _status(item).toLowerCase() == "accepted" && _isLeaderWork(item);
    final statusInfo = _statusInfo(item);

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
                        staffName.isEmpty ? "Unknown" : staffName,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (roleLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          roleLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusInfo.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    statusInfo.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusInfo.color,
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
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
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
    final confirmed = await showConfirmDialog(
      context,
      "Approve",
      "compensation",
    );
    if (confirmed != true || !mounted) return;
    setState(() => _processingId = id);
    try {
      await OvertimeService.updateManagerResponse(
        extraWorkId: id,
        status: "Approved",
        asDirector: true,
      );
      if (!mounted) return;
      showAppMessage(context, "Compensation approved", isError: false);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, e.toString().replaceFirst("Exception: ", ""));
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
        asDirector: true,
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
