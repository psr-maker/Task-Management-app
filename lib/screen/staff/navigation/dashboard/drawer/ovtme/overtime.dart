import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/ovtme/overtimes_details.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class OvertimeListttt extends StatefulWidget {
  const OvertimeListttt({super.key});

  @override
  State<OvertimeListttt> createState() => _OvertimeListtttState();
}

class _OvertimeListtttState extends State<OvertimeListttt> {
  bool loading = true;

  List<dynamic> allData = [];
  List<dynamic> filteredData = [];

  DateTime? fromDate;
  DateTime? toDate;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final data = await OvertimeService.getMyOvertime();

      if (!mounted) return;

      debugPrint("==========================================");
      debugPrint("OVERTIME API DATA");
      debugPrint("$data");
      debugPrint("==========================================");

      final pendingManagerRequests = data.where((item) {
        final staffStatus = (item["staffStatus"] ?? "")
            .toString()
            .trim()
            .toLowerCase();

        final managerStatus = (item["managerStatus"] ?? "")
            .toString()
            .trim()
            .toLowerCase();

        final isPendingStaffResponse = staffStatus == "pending";
        final isPendingManagerApproval = managerStatus == "pending";

        return isPendingStaffResponse && isPendingManagerApproval;
      }).toList();

      debugPrint("Pending manager requests: ${pendingManagerRequests.length}");

      for (final item in pendingManagerRequests) {
        debugPrint(
          "Pending Overtime ID: ${item["id"]}, "
          "Staff: ${item["staffName"]}, "
          "Staff Status: ${item["staffStatus"]}, "
          "Manager Status: ${item["managerStatus"]}",
        );
      }

      setState(() {
        allData = pendingManagerRequests;
        loading = false;
      });

      applyFilters();
    } catch (e) {
      debugPrint("Overtime loading error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showTopMessage(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2050),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
    );

    if (picked == null) return;

    setState(() {
      fromDate = picked.start;
      toDate = picked.end;
    });

    applyFilters();
  }

  void clearDateFilter() {
    setState(() {
      fromDate = null;
      toDate = null;
    });

    applyFilters();
  }

  void applyFilters() {
    List<dynamic> temp = [...allData];

    if (fromDate != null && toDate != null) {
      final startDate = DateTime(
        fromDate!.year,
        fromDate!.month,
        fromDate!.day,
      );

      final endDate = DateTime(toDate!.year, toDate!.month, toDate!.day);

      temp = temp.where((item) {
        try {
          final date = DateTime.parse(item["date"].toString());

          final selectedDate = DateTime(date.year, date.month, date.day);

          return !selectedDate.isBefore(startDate) &&
              !selectedDate.isAfter(endDate);
        } catch (_) {
          return false;
        }
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredData = temp;
    });
  }

  String formatTime(dynamic value) {
    if (value == null) return "";

    final text = value.toString().trim();

    if (text.isEmpty) return "";

    try {
      final parsed = DateFormat("HH:mm:ss").parse(text);

      return DateFormat("h:mm a").format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat("HH:mm").parse(text);

        return DateFormat("h:mm a").format(parsed);
      } catch (_) {
        return text;
      }
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return "";

    try {
      return DateFormat("dd MMM yyyy").format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> acceptOvertime(dynamic item) async {
    final overtimeId = int.tryParse(item["id"].toString());

    if (overtimeId == null) {
      showTopMessage("Invalid overtime ID", isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Accept Overtime"),
          content: const Text(
            "Are you sure you want to accept this overtime request?",
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            AppButton(
              text: "Accept",
              isLoading: false,
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              color: Theme.of(context).colorScheme.secondary,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await respondToOvertime(overtimeId: overtimeId, status: "Accepted");
  }

  Future<void> rejectOvertime(dynamic item) async {
    final overtimeId = int.tryParse(item["id"].toString());

    if (overtimeId == null) {
      showTopMessage("Invalid overtime ID", isError: true);
      return;
    }

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        final reasonController = TextEditingController();

        return AlertDialog(
          title: const Text("Reject Overtime"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please provide a reason for rejecting this overtime request.",
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            AppButton(
              text: "Reject",
              isLoading: false,
              onPressed: () {
                final reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  showTopMessage("Please enter a reason", isError: true);
                  return;
                }

                Navigator.pop(dialogContext, reason);
              },
              color: Theme.of(context).colorScheme.error,
              txtcolor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) {
      return;
    }

    await respondToOvertime(
      overtimeId: overtimeId,
      status: "Rejected",
      reason: result.trim(),
    );
  }

  Future<void> respondToOvertime({
    required int overtimeId,
    required String status,
    String? reason,
  }) async {
    try {
      if (!mounted) return;

      setState(() {
        loading = true;
      });

      final response = await OvertimeService.staffResponse(
        overtimeId: overtimeId,
        status: status,
        reason: reason,
      );

      if (!mounted) return;

      final success =
          response["success"] == true || response["success"] == "true";

      if (success) {
        // Remove accepted/rejected request from current list
        setState(() {
          allData.removeWhere(
            (item) => int.tryParse(item["id"].toString()) == overtimeId,
          );

          filteredData.removeWhere(
            (item) => int.tryParse(item["id"].toString()) == overtimeId,
          );

          loading = false;
        });

        showTopMessage(
          status == "Accepted"
              ? "Overtime accepted successfully"
              : "Overtime rejected successfully",
          isError: false,
        );
      } else {
        setState(() {
          loading = false;
        });

        showTopMessage(
          response["message"]?.toString() ?? "Unable to update overtime",
          isError: false,
        );
      }
    } catch (e) {
      debugPrint("Staff overtime response error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showTopMessage(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    }
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
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),

        title: const Text("Manager Overtime Requests"),

        actions: [
          // DATE FILTER
          IconButton(
            onPressed: pickDateRange,
            icon: const Icon(Icons.filter_alt_outlined),
          ),

          // CLEAR FILTER
          if (fromDate != null && toDate != null)
            IconButton(
              onPressed: clearDateFilter,
              icon: const Icon(Icons.clear),
            ),

          // HISTORY
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Myovertime()),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),

      body: Stack(
        children: [
          loading
              ? const Center(child: RotatingFlower())
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: filteredData.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 30),
                          children: _buildGroupedData(),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 180),

        const Icon(Icons.access_time_outlined, size: 55),

        const SizedBox(height: 15),

        const Center(
          child: Text(
            "No pending overtime requests",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Myovertime()),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text("View All Overtime History"),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedData() {
    final Map<String, List<dynamic>> groupedData = {};

    for (final item in filteredData) {
      try {
        final date = DateTime.parse(item["date"].toString());

        final month = DateFormat("MMMM yyyy").format(date);

        groupedData.putIfAbsent(month, () => []).add(item);
      } catch (_) {}
    }

    final widgets = <Widget>[];

    groupedData.forEach((month, items) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            children: [
              Text(
                month,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 4),

              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      );

      for (final item in items) {
        widgets.add(_buildOvertimeCard(item));
      }
    });

    return widgets;
  }

  Widget _buildOvertimeCard(dynamic item) {
    final date = formatDate(item["date"]);

    final from = formatTime(item["fromTime"]);

    final to = formatTime(item["toTime"]);

    final totalHours =
        double.tryParse(item["totalHours"]?.toString() ?? "0") ?? 0;

    final duration = totalHours.toStringAsFixed(2);

    final reason = item["reason"]?.toString() ?? "";

    final staffName = item["staffName"]?.toString() ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(.25)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(.10),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.access_time_rounded,
                  size: 19,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overtime Request",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),

                    if (staffName.isNotEmpty)
                      Text(
                        staffName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.priority_high_rounded,
                      size: 13,
                      color: Colors.orange,
                    ),

                    SizedBox(width: 4),

                    Text(
                      "Pending",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            date,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(Icons.schedule, size: 17),

              const SizedBox(width: 7),

              Text(
                from,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),

              Text(
                to,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              Text(
                "$duration hrs",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.06),
                borderRadius: BorderRadius.circular(8),
              ),

              child: Text(
                reason,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ),
          ],

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: "Reject",
                  isLoading: loading,
                  onPressed: loading ? null : () => rejectOvertime(item),
                  color: Theme.of(context).colorScheme.error,
                  txtcolor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: AppButton(
                  text: "Accept",
                  isLoading: loading,
                  onPressed: loading ? null : () => acceptOvertime(item),
                  color: Theme.of(context).colorScheme.secondary,
                  txtcolor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              "Please respond to this overtime request",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
