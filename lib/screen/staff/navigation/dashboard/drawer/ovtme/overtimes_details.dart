import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class Myovertime extends StatefulWidget {
  const Myovertime({super.key});

  @override
  State<Myovertime> createState() => _MyovertimeState();
}

class _MyovertimeState extends State<Myovertime> {
  List<dynamic> staffOvertimes = [];

  bool loading = true;
  bool processing = false;

  bool hasChanged = false;

  @override
  void initState() {
    super.initState();
    loadStaffOvertime();
  }

  Future<void> loadStaffOvertime() async {
    try {
      setState(() {
        loading = true;
      });

      final data = await OvertimeService.getMyOvertime();

      if (!mounted) return;

      setState(() {
        staffOvertimes = data;

        loading = false;
      });
    } catch (e) {
      debugPrint("Load staff overtime error: $e");

      if (!mounted) return;
      _showMessage("Unable to load overtime history", true);
    }
  }

  String getStaffStatus(dynamic item) {
    return (item["staffStatus"] ?? "Pending").toString();
  }

  String getManagerStatus(dynamic item) {
    return (item["managerStatus"] ?? "Pending").toString();
  }

  bool staffAccepted(dynamic item) {
    return getStaffStatus(item) == "Accepted";
  }

  bool staffRejected(dynamic item) {
    return getStaffStatus(item) == "Rejected";
  }

  bool staffPending(dynamic item) {
    return getStaffStatus(item) == "Pending";
  }

  bool managerApproved(dynamic item) {
    return getManagerStatus(item) == "Approved";
  }

  bool managerRejected(dynamic item) {
    return getManagerStatus(item) == "Rejected";
  }

  bool waitingForManager(dynamic item) {
    return staffAccepted(item) && getManagerStatus(item) == "Pending";
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) {
      return "";
    }

    try {
      final parsed = DateFormat("HH:mm:ss").parse(time);

      return DateFormat("h:mm a").format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat("HH:mm").parse(time);

        return DateFormat("h:mm a").format(parsed);
      } catch (_) {
        return time;
      }
    }
  }

  String formatDate(dynamic date) {
    if (date == null) {
      return "-";
    }

    try {
      return DateFormat("dd MMM yyyy").format(DateTime.parse(date.toString()));
    } catch (_) {
      return date.toString();
    }
  }

  String formatTotalHours(dynamic value) {
    if (value == null) {
      return "0m";
    }

    final double hours = double.tryParse(value.toString()) ?? 0;

    final int totalMinutes = (hours * 60).round();

    final int h = totalMinutes ~/ 60;

    final int m = totalMinutes % 60;

    if (h > 0 && m > 0) {
      return "${h}h ${m}m";
    }

    if (h > 0) {
      return "${h}h";
    }

    return "${m}m";
  }

  void _showMessage(String message, bool error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasChanged);

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, hasChanged);
            },
          ),
          title: const Text("Overtime Details"),
        ),

        body: loading
            ? const Center(child: RotatingFlower())
            : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: loadStaffOvertime,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // STAFF NAME
                        const SizedBox(height: 20),

                        // ALL REQUESTS
                        ...staffOvertimes
                            .map((item) => _buildOvertimeHistoryCard(item))
                            .toList(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  if (processing)
                    Container(
                      color: Colors.black.withOpacity(.15),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildOvertimeHistoryCard(dynamic item) {
    final date = formatDate(item["date"]);

    final from = formatTime(item["fromTime"]);

    final to = formatTime(item["toTime"]);

    final totalHours = formatTotalHours(item["totalHours"]);

    final staffStatus = getStaffStatus(item);

    final managerStatus = getManagerStatus(item);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (staffStatus == "Pending") {
      statusText = "Requested";
      statusColor = Colors.orange;
      statusIcon = Icons.pending_actions;
    } else if (staffStatus == "Rejected") {
      statusText = "Rejected";
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (managerStatus == "Rejected") {
      statusText = "Rejected";
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (managerStatus == "Approved") {
      statusText = "Approved";
      statusColor = Colors.green;
      statusIcon = Icons.verified;
    } else {
      statusText = "Accepted";
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
       
            children: [
               Text(
                  "Overtime Request",
                 style: Theme.of(context).textTheme.headlineLarge,
                ),
              // CIRCLE ICON
              Expanded(
                child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(.12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // STATUS
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

           
            ],
          ),
              const SizedBox(height: 10),
              Text(
                date,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
         

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 17),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  "$from - $to",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                totalHours,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

           Text(
            "Reason",
           style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 8),

          Text(
            item["reason"]?.toString() ?? "-",
            style: const TextStyle(fontSize: 13),
          ),

          if (staffPending(item)) ...[
            const SizedBox(height: 12),

            _buildWaitingSection(
              message: "Waiting for Your Response",
              color: Colors.orange
            ),
          ],
          if (staffAccepted(item)) ...[
            const SizedBox(height: 16),

            _buildStaffAcceptedSection(item),
          ],
          if (staffRejected(item)) ...[
            const SizedBox(height: 16),

            _buildReasonSection(
              title: "You Rejected Reason",
              reason: item["staffResponseReason"],
              color: Colors.red,
            ),
          ],
          if (managerRejected(item)) ...[
            const SizedBox(height: 10),

            _buildReasonSection(
              title: "Manager Rejected Reason",
              reason: item["managerResponseReason"],
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaitingSection({
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStaffAcceptedSection(dynamic item) {
    final managerStatus = getManagerStatus(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),

            const SizedBox(width: 8),

            const Expanded(
              child: Text(
                "Your Response",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),

            Text(
              "Accepted",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Text(
          managerStatus == "Pending"
              ? "Waiting for manager approval."
              : "",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildReasonSection({
    required String title,
    required dynamic reason,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 19),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            reason?.toString().trim().isNotEmpty == true
                ? reason.toString()
                : "No reason provided",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
