import 'package:flutter/material.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/screen/super%20admin/Navigation/dashboard/warnings/overduetask.dart';
import 'package:staff_work_track/services/announ_service.dart';

class DeptWarning extends StatefulWidget {
  final List<Map<String, dynamic>> overdueTasks;
  final List<Map<String, dynamic>> overdueGoals;
  const DeptWarning({
    super.key,
    required this.overdueTasks,
    required this.overdueGoals,
  });

  @override
  State<DeptWarning> createState() => _WarningState();
}

class _WarningState extends State<DeptWarning> {
  List<WarningModel> warnings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWarnings();
  }

  Future<void> loadWarnings() async {
    try {
      final data = await AnnouncementService.getDepartmentWarnings();
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
    final theme = Theme.of(context);
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
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFff4d4d), Color(0xFFff884d)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 50,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Warning Center",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "${warnings.length + widget.overdueTasks.length + widget.overdueGoals.length} Active Alerts",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(15),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (widget.overdueTasks.isNotEmpty) ...[
                        Text(
                          "Overdue Tasks",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 15),
                        OverdueTaskList(overdueTasks: widget.overdueTasks),
                        const SizedBox(height: 20),
                      ],
                      if (widget.overdueGoals.isNotEmpty) ...[
                        Text(
                          "Overdue Goals",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 15),
                        OverdueGoalList(overdueGoals: widget.overdueGoals),
                        const SizedBox(height: 20),
                      ],
                      if (warnings.isNotEmpty) ...[
                        Text(
                          "Warnings",
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 15),

                        ...warnings.map((warning) {
                          final severityColor = getSeverityColor(
                            warning.severity,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius:
                                  theme.cardTheme.shape
                                      is RoundedRectangleBorder
                                  ? (theme.cardTheme.shape
                                            as RoundedRectangleBorder)
                                        .borderRadius
                                  : BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Left Color Indicator
                                Container(
                                  width: 5,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: severityColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// Title + Date
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                warning.title,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${warning.createdDate.day}/${warning.createdDate.month}/${warning.createdDate.year}",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        /// Message
                                        Text(
                                          warning.message,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                        ),

                                  
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "${warning.receiverName} • ${warning.receiverRole}",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineSmall,
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: severityColor
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                "Warning ${warning.escalationLevel}",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: severityColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
