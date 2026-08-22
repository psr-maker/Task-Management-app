import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class PunchCorrdeptlist extends StatefulWidget {
  const PunchCorrdeptlist({super.key});

  @override
  State<PunchCorrdeptlist> createState() => _PunchCorrdeptlistState();
}

class _PunchCorrdeptlistState extends State<PunchCorrdeptlist> {
  List<dynamic> corrections = [];
  List<dynamic> filteredCorrections = [];
  bool isLoading = true;

  // Filter tabs
  final List<String> filters = ["Pending", "Approved", "Rejected"];
  String activeFilter = "Pending";

  int? _actioningId;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadPunchCorrections();
  }

  Future<void> loadPunchCorrections() async {
    setState(() => isLoading = true);
    final data = await AdminService.getDepartmentPunchCorrections();

    if (!mounted) return;

    setState(() {
      corrections = data;
      isLoading = false;
    });
    applyFilter();
  }

  void applyFilter() {
    setState(() {
      filteredCorrections = corrections.where((e) {
        final status = (e["status"] ?? "").toString().toLowerCase();
        return status == activeFilter.toLowerCase();
      }).toList();
    });
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

  Future<void> handleDecision(int id, bool approved) async {
    setState(() => _actioningId = id);

    final success = await AdminService.managerPunchCorrection(
      id: id,
      approved: approved,
    );

    if (!mounted) return;
    setState(() => _actioningId = null);

    if (success) {
      showTopMessage(
        approved ? "Punch correction approved" : "Punch correction rejected",
        isError: false,
      );
      await loadPunchCorrections(); // refresh so item moves out of Pending
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update punch correction"),
          backgroundColor: Colors.red,
        ),
      );
      showTopMessage("Failed to update punch correction", isError: true);
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
        title: const Text("Attendance Corrections"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: filters.map((f) {
                final isActive = activeFilter == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => activeFilter = f);
                      applyFilter();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: RotatingFlower())
                    : filteredCorrections.isEmpty
                    ? Center(
                        child: Text(
                          "No $activeFilter attendance corrections found",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadPunchCorrections,
                        color: const Color(0xff194d26),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(15),
                          itemCount: filteredCorrections.length,
                          itemBuilder: (context, index) {
                            final item = filteredCorrections[index];

                            final id = item["id"];

                            return _PunchTimelineItem(
                              name: item["name"] ?? item["employeeName"] ?? "",
                              date: AppHelpers.formatDate(item["date"] ?? ""),
                              type: item["correctionType"] ?? "",
                              time: item["punchTime"] ?? "",
                              reason: item["reason"] ?? "",
                              status: item["status"] ?? "",
                              isLast: index == filteredCorrections.length - 1,
                              isActioning: _actioningId == id,
                              onApprove: () => handleDecision(id, true),
                              onReject: () => handleDecision(id, false),
                            );
                          },
                        ),
                      ),
              ),
            ],
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
              ),
            ),
        ],
      ),
    );
  }
}

class _PunchTimelineItem extends StatelessWidget {
  final String name;
  final String date;
  final String type;
  final String time;
  final String reason;
  final String status;
  final bool isLast;
  final bool isActioning;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PunchTimelineItem({
    required this.name,
    required this.date,
    required this.type,
    required this.time,
    required this.reason,
    required this.status,
    required this.isLast,
    required this.isActioning,
    required this.onApprove,
    required this.onReject,
  });

  Color getStatusColor() {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor();
    final isPending = status.toLowerCase() == "pending";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.25),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),

              if (!isLast)
                Container(width: 2, height: 230, color: Colors.grey.shade300),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: Colors.grey.shade200),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Status
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Color(0xff194d26),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        name.isNotEmpty ? name : "Unknown",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Punch type
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xff194d26).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type.contains("In")
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        color: const Color(0xff194d26),
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 15,
                                color: Colors.grey.shade600,
                              ),

                              const SizedBox(width: 5),

                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Reason
                Text(
                  "Reason",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),

                // Approve / Reject — only for pending items
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isActioning ? null : onReject,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Reject",
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isActioning ? null : onApprove,
                          icon: isActioning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                          label: const Text(
                            "Approve",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff194d26),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
