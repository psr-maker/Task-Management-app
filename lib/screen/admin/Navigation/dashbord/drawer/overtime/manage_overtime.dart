import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/overtime/create_overtime.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/overtime/overtime_details.dart';
import 'package:staff_work_track/screen/admin/Navigation/dashbord/drawer/overtime/select_staff.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class ManagerOvertime extends StatefulWidget {
  final String dept;

  const ManagerOvertime({super.key, required this.dept});

  @override
  State<ManagerOvertime> createState() => _ManagerOvertimeState();
}

class _ManagerOvertimeState extends State<ManagerOvertime> {
  bool loading = true;

  List<dynamic> allData = [];
  List<dynamic> filteredData = [];

  String searchQuery = "";

  DateTime? startDate;
  DateTime? endDate;

  int? processingId;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final data = await OvertimeService.getDepartmentOvertime();

      if (!mounted) return;

      allData = List<dynamic>.from(data);

      _applyFilters();

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        allData = [];
        filteredData = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load overtime: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void _applyFilters() {
    List<dynamic> result = List<dynamic>.from(allData);
    result = result.where((item) {
      return _isCurrentRequest(item);
    }).toList();

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();

      result = result.where((item) {
        final staffName = item["staffName"]?.toString().toLowerCase() ?? "";

        final reason = item["reason"]?.toString().toLowerCase() ?? "";

        final dept = item["dept"]?.toString().toLowerCase() ?? "";

        return staffName.contains(query) ||
            reason.contains(query) ||
            dept.contains(query);
      }).toList();
    }

    // Start date filter
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);

      result = result.where((item) {
        final date = _parseDate(item["date"]);

        final itemDate = DateTime(date.year, date.month, date.day);

        return !itemDate.isBefore(start);
      }).toList();
    }

    // End date filter
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);

      result = result.where((item) {
        final date = _parseDate(item["date"]);

        final itemDate = DateTime(date.year, date.month, date.day);

        return !itemDate.isAfter(end);
      }).toList();
    }

    // Latest date first
    result.sort((a, b) {
      final dateA = _parseDate(a["date"]);
      final dateB = _parseDate(b["date"]);

      return dateB.compareTo(dateA);
    });

    filteredData = result;
  }

  String _status(dynamic value) {
    return (value ?? "pending").toString().trim().toLowerCase();
  }

  bool _isWaitingForStaff(dynamic item) {
    final staffStatus = _status(item["staffStatus"]);
    final managerStatus = _status(item["managerStatus"]);

    return staffStatus == "pending" && managerStatus == "pending";
  }

  bool _isWaitingForManager(dynamic item) {
    final staffStatus = _status(item["staffStatus"]);
    final managerStatus = _status(item["managerStatus"]);

    return staffStatus == "accepted" && managerStatus == "pending";
  }

  bool _isCurrentRequest(dynamic item) {
    return _isWaitingForStaff(item) || _isWaitingForManager(item);
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime(1900);
    }

    return DateTime.tryParse(value.toString()) ?? DateTime(1900);
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date.year == 1900) {
      return "-";
    }

    return DateFormat("dd MMM yyyy").format(date);
  }

  String _formatTime(dynamic value) {
    if (value == null) {
      return "-";
    }

    final text = value.toString();

    try {
      final parts = text.split(":");

      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final time = TimeOfDay(hour: hour, minute: minute);

        return time.format(context);
      }
    } catch (_) {}

    return text;
  }

  String formatHours(dynamic value) {
    if (value == null) {
      return "-";
    }

    final hoursDecimal = double.tryParse(value.toString());

    if (hoursDecimal == null) {
      return "-";
    }

    final hours = hoursDecimal.floor();

    final minutes = ((hoursDecimal - hours) * 60).round();

    if (minutes == 60) {
      return "${hours + 1} hrs 0 mins";
    }

    return "$hours hrs $minutes mins";
  }

  Future<void> _managerDecision(dynamic item, bool approve) async {
    final id = int.tryParse(item["id"]?.toString() ?? "");

    if (id == null) {
      showTopMessage("Invalid overtime ID", isError: true);
      return;
    }

    if (!_isWaitingForManager(item)) {
      showTopMessage(
        "This overtime is not ready for manager approval.",
        isError: true,
      );
      return;
    }

    String? reason;

    if (!approve) {
      reason = await _showRejectDialog();

      if (reason == null) {
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      processingId = id;
    });

    try {
      await OvertimeService.managerResponse(
        overtimeId: id,
        status: approve ? "Approved" : "Rejected",
        reason: reason,
      );

      if (!mounted) return;

      showTopMessage(
        approve
            ? "Overtime approved successfully"
            : "Overtime rejected successfully",
        isError: approve ? false : true,
      );
      await loadData();
    } catch (e) {
      if (!mounted) return;

      showTopMessage("Failed to update overtime: $e", isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        processingId = null;
      });
    }
  }

  Future<String?> _showRejectDialog() async {
    String reason = "";

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                "Reject Overtime",
                style: TextStyle(color: Colors.white),
              ),
              content: TextField(
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  reason = value;
                },
                decoration: InputDecoration(
                  hintText: "Enter rejection reason",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final trimmedReason = reason.trim();

                    if (trimmedReason.isEmpty) {
                      showTopMessage(
                        "Please enter rejection reason",
                        isError: true,
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, trimmedReason);
                  },
                  child: const Text(
                    "Reject",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _openDetails(dynamic item) async {
    final uid = item["uid"]?.toString();

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Staff ID not found"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerOvertimeDetails(
          staffId: uid,
          staffName: item["staffName"]?.toString() ?? "Staff",
        ),
      ),
    );

    if (!mounted) return;

    await loadData();
  }

  Future<void> _openOvertimeHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerOvertimeHistory(dept: widget.dept),
      ),
    );

    if (!mounted) return;

    await loadData();
  }

  void showTopMessage(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _isErrorMessage = isError;
      _showTopMessage = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showTopMessage = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Overtime Management"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: _openOvertimeHistory,
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerOvertimeCreate(dept: widget.dept),
                ),
              );

              if (!mounted) return;

              await loadData();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: Stack(
        children: [
          loading
              ? const Center(child: RotatingFlower())
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(15),
                    children: [
                      if (filteredData.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredData.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildOvertimeCard(item),
                          ),
                        ),
                    ],
                  ),
                ),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 20 : -120,
              left: 16,
              right: 16,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Msgsnackbar(
               context,
                message: _topMessage!,
                isError: _isErrorMessage,
                backgroundColor: _isErrorMessage
                    ? Colors.red
                    : Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.secondary,
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 60, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          const Text(
            "No pending overtime requests",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Staff pending or manager pending requests\n"
            "will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeCard(dynamic item) {
    final staffName = item["staffName"]?.toString() ?? "Unknown Staff";

    final date = _formatDate(item["date"]);

    final fromTime = _formatTime(item["fromTime"]);

    final toTime = _formatTime(item["toTime"]);

    final totalHours = formatHours(item["totalHours"]);

    final reason = item["reason"]?.toString() ?? "-";

    final waitingForStaff = _isWaitingForStaff(item);

    final waitingForManager = _isWaitingForManager(item);

    final id = int.tryParse(item["id"]?.toString() ?? "");

    final isProcessing = id != null && processingId == id;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: waitingForManager
              ? Colors.green.withOpacity(0.4)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openDetails(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        child: Text(
                          staffName.isNotEmpty
                              ? staffName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staffName,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.chevron_right),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _infoRow(Icons.calendar_today, "Date", date),

                  const SizedBox(height: 10),

                  _infoRow(Icons.access_time, "Time", "$fromTime - $toTime"),

                  const SizedBox(height: 10),

                  _infoRow(Icons.timelapse, "Total Hours", totalHours),

                  const SizedBox(height: 10),

                  _infoRow(Icons.description, "Reason", reason),

                  const SizedBox(height: 14),

                  if (waitingForStaff)
                    _statusContainer(
                      icon: Icons.hourglass_empty,
                      text: "Waiting for Staff",
                      color: Colors.orange,
                    )
                  else if (waitingForManager)
                    _statusContainer(
                      icon: Icons.check_circle,
                      text: "Waiting for Manager Approval",
                      color: Colors.green,
                    ),
                ],
              ),
            ),
          ),

          if (waitingForManager)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _managerDecision(item, false),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Reject"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _managerDecision(item, true),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(isProcessing ? "Processing..." : "Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 25, 77, 38),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        SizedBox(
          width: 85,
          child: Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusContainer({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
