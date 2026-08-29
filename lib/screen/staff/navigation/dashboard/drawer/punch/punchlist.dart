import 'package:flutter/material.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/staff/navigation/dashboard/drawer/punch/punchcorr_apply.dart';
import 'package:staff_work_track/services/admin_service.dart';
import 'package:staff_work_track/utils/app_helper.dart';

class PunchCorrectionList extends StatefulWidget {
  const PunchCorrectionList({super.key});

  @override
  State<PunchCorrectionList> createState() => _PunchCorrectionListState();
}

class _PunchCorrectionListState extends State<PunchCorrectionList> {
  List<dynamic> corrections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPunchCorrections();
  }

  Future<void> loadPunchCorrections() async {
    final data = await AdminService.getMyPunchCorrections();

    if (!mounted) return;

    setState(() {
      corrections = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Punch Corrections"),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PunchCorrection(),
                ),
              );
              if (result == true) {
                loadPunchCorrections();
              }
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: RotatingFlower())
          : corrections.isEmpty
          ? const Center(
              child: Text(
                "No punch corrections found",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadPunchCorrections,
              color: const Color(0xff194d26),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
                itemCount: corrections.length,
                itemBuilder: (context, index) {
                  final item = corrections[index];

                  return _PunchTimelineItem(
                    date: AppHelpers.formatDate(item["date"] ?? ""),
                    type: item["correctionType"] ?? "",
                    time: item["punchTime"] ?? "",
                    reason: item["reason"] ?? "",
                    status: item["status"] ?? "",
                    isLast: index == corrections.length - 1,
                  );
                },
              ),
            ),
    );
  }
}

class _PunchTimelineItem extends StatelessWidget {
  final String date;
  final String type;
  final String time;
  final String reason;
  final String status;
  final bool isLast;

  const _PunchTimelineItem({
    required this.date,
    required this.type,
    required this.time,
    required this.reason,
    required this.status,
    required this.isLast,
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
                Container(width: 2, height: 190, color: Colors.grey.shade300),
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
                // Date + Status
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Color(0xff194d26),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const Spacer(),

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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
