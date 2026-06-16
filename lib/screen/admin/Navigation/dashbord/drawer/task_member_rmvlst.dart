import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/superadmin_service.dart';

class TaskRemovalRequest extends StatefulWidget {
  const TaskRemovalRequest({super.key});

  @override
  State<TaskRemovalRequest> createState() => _TaskRemovalRequestState();
}

class _TaskRemovalRequestState extends State<TaskRemovalRequest> {
  List data = [];
  bool loading = true;
  String? _topMessage;
  bool _isErrorMessage = true;
  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final result = await SuperAdminService.getTaskMemberRemovals();

    setState(() {
      data = result;
      loading = false;
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

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Proceed",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processRequest(
    Map<String, dynamic> item, {
    required bool applyPenalty,
  }) async {
    final taskCode = item["taskCode"];
    final userId = item["userId"];

    if (taskCode == null || userId == null) return;

    final success = await SuperAdminService.processRemovalRequest(
      taskCode: taskCode,
      userId: userId,
      applyPenalty: applyPenalty,
    );

    if (success) {
      showTopMessage("successfully", isError: false);
      loadData();
    } else {
      showTopMessage("Failed ", isError: true);
    }
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
        title: const Text("Task Removal Requests"),
      ),
      body: loading
          ? const Center(child: RotatingFlower())
          : Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Approving this request will apply penalty points to the user. This action cannot be undone.",
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Color.fromARGB(255, 15, 35, 20),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 15,
                                          child: Text(
                                            item["userName"][0].toUpperCase(),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item["userName"],
                                            style: Theme.of(
                                              context,
                                            ).textTheme.displaySmall,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    Text(
                                      item["taskName"],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Removed By: ${item["removedByName"]}",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            DateFormat('yyyy-MM-dd').format(
                                              DateTime.parse(
                                                item["removedDate"],
                                              ),
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 15),
                                    Text(
                                      "Removal Reason",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.background,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["reason"] ?? "-",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final confirm =
                                                  await _showConfirmDialog(
                                                    context,
                                                    title: "No",
                                                    message:
                                                        "This will remove task without applying penalty. Continue?",
                                                  );

                                              if (confirm != true) return;

                                              await _processRequest(
                                                item,
                                                applyPenalty: false,
                                              );
                                            },
                                            icon: const Icon(Icons.close),
                                            label: const Text("No"),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final confirm =
                                                  await _showConfirmDialog(
                                                    context,
                                                    title: "Apply",
                                                    message:
                                                        "Penalty points will be applied based on task priority. Continue?",
                                                  );

                                              if (confirm != true) return;

                                              await _processRequest(
                                                item,
                                                applyPenalty: true,
                                              );
                                            },
                                            icon: const Icon(Icons.gavel),
                                            label: const Text("Apply"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                      child: Msgsnackbar(
                        context,
                        message: _topMessage!,
                        isError: _isErrorMessage,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
