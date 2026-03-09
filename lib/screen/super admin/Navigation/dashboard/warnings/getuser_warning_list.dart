import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/services/announ_service.dart';

class UsersWarning extends StatefulWidget {
  const UsersWarning({super.key});

  @override
  State<UsersWarning> createState() => _UsersWarningState();
}

class _UsersWarningState extends State<UsersWarning> {
  List<WarningModel> warnings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWarnings();
  }

  Future<void> loadWarnings() async {
    try {
      final data = await AnnouncementService.getWarnings();
      setState(() {
        warnings = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load warnings")));
    }
  }

  Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Warnings"),
      ),

      body: isLoading
          ? const Center(child: RotatingFlower())
          : Column(
              children: [
                /// 🔴 WARNING HEADER SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "WARNING CENTER",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${warnings.length} Active Warnings",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                /// 🟠 WARNINGS LIST
                Expanded(
                  child: warnings.isEmpty
                      ? const Center(
                          child: Text(
                            "No warnings found",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: warnings.length,
                          itemBuilder: (context, index) {
                            final warning = warnings[index];
                            final severityColor = getSeverityColor(
                              warning.severity,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: severityColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// LEFT BIG ICON
                                  Icon(
                                    Icons.report_problem,
                                    color: severityColor,
                                    size: 38,
                                  ),

                                  const SizedBox(width: 14),

                                  /// CONTENT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// TITLE
                                        Text(
                                          warning.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        /// MESSAGE
                                        Text(
                                          warning.message,
                                          style: const TextStyle(fontSize: 14),
                                        ),

                                        const SizedBox(height: 10),

                                        /// ESCALATION + DATE
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Escalation Level: ${warning.escalationLevel}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: severityColor,
                                              ),
                                            ),
                                            Text(
                                              "${warning.createdDate.day}/${warning.createdDate.month}/${warning.createdDate.year}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
