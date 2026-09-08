import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/overtime_service.dart';

class ManagerOvertimeDetails extends StatefulWidget {
  final String staffId;
  final String staffName;

  const ManagerOvertimeDetails({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<ManagerOvertimeDetails> createState() => _ManagerOvertimeDetailsState();
}

class _ManagerOvertimeDetailsState extends State<ManagerOvertimeDetails> {
  bool loading = true;

  List<dynamic> overtimeList = [];

  @override
  void initState() {
    super.initState();
    loadStaffOvertime();
  }

  Future<void> loadStaffOvertime() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final data = await OvertimeService.getDepartmentOvertime();

      final staffData = data.where((item) {
        final uid = item["uid"]?.toString();

        return uid == widget.staffId;
      }).toList();

      // Newest first
      staffData.sort((a, b) {
        final dateA = _parseDate(a["date"]);
        final dateB = _parseDate(b["date"]);

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        overtimeList = staffData;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load overtime history: $e"),
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

  String _status(dynamic value) {
    return (value ?? "pending").toString().trim().toLowerCase();
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

  String _getStatusText(dynamic item) {
    final staffStatus = _status(item["staffStatus"]);

    final managerStatus = _status(item["managerStatus"]);

    if (managerStatus == "approved") {
      return "Approved";
    }

    if (managerStatus == "rejected") {
      return "Manager Rejected";
    }

    if (staffStatus == "rejected") {
      return "Staff Rejected";
    }

    if (staffStatus == "accepted" && managerStatus == "pending") {
      return "Waiting for Manager Approval";
    }

    if (staffStatus == "pending" && managerStatus == "pending") {
      return "Waiting for Staff";
    }

    return "Pending";
  }

  Color _getStatusColor(dynamic item) {
    final status = _getStatusText(item);

    switch (status) {
      case "Approved":
        return Colors.green;

      case "Manager Rejected":
      case "Staff Rejected":
        return Colors.redAccent;

      case "Waiting for Manager Approval":
        return Colors.blueAccent;

      case "Waiting for Staff":
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(dynamic item) {
    final status = _getStatusText(item);

    switch (status) {
      case "Approved":
        return Icons.check_circle;

      case "Manager Rejected":
      case "Staff Rejected":
        return Icons.cancel;

      case "Waiting for Manager Approval":
        return Icons.pending_actions;

      case "Waiting for Staff":
        return Icons.hourglass_empty;

      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(widget.staffName),
      ),
      body: loading
          ? const Center(child: RotatingFlower())
          : overtimeList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 500, child: _buildEmptyState()),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(15),
                  itemCount: overtimeList.length,
                  itemBuilder: (context, index) {
                    final item = overtimeList[index];
          
                    return _buildOvertimeCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 60, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          const Text(
            "No overtime history",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeCard(dynamic item) {
    final date = _formatDate(item["date"]);

    final fromTime = _formatTime(item["fromTime"]);

    final toTime = _formatTime(item["toTime"]);

    final totalHours = item["totalHours"]?.toString() ?? "-";

    final reason = item["reason"]?.toString() ?? "-";

    final staffStatus = item["staffStatus"]?.toString() ?? "Pending";

    final managerStatus = item["managerStatus"]?.toString() ?? "Pending";

    final staffResponseReason = item["staffResponseReason"]?.toString() ?? "";

    final managerResponseReason =
        item["managerResponseReason"]?.toString() ?? "";

    final statusColor = _getStatusColor(item);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
      
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 19,
                        color:  Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
    
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(item),
                        size: 15,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _getStatusText(item),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    
            const SizedBox(height: 10),
    
            _infoRow(Icons.access_time, "Time", "$fromTime - $toTime"),
    
            const SizedBox(height: 10),
    
            _infoRow(Icons.timelapse, "Total Hours", totalHours),
    
            const SizedBox(height: 10),
    
            _infoRow(Icons.description, "Reason", reason),
    
            const SizedBox(height: 10),
    
            const Divider(color: Colors.black54),
    
            const SizedBox(height: 10),
    
             Text(
              "Staff Response",
           style: Theme.of(context).textTheme.headlineMedium,
            ),
    
            const SizedBox(height: 8),
    
            _responseRow("Status", staffStatus),
    
            if (staffResponseReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _responseRow("Reason", staffResponseReason),
            ],
    
            const SizedBox(height: 10),
    
             Text(
              "Manager Response",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
    
            const SizedBox(height: 8),
    
            _responseRow("Status", managerStatus),
    
            if (managerResponseReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _responseRow("Reason", managerResponseReason),
            ],
          ],
        ),
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
          style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }

  Widget _responseRow(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text(
              title,
            style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
                style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
