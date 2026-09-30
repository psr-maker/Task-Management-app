import 'package:flutter/material.dart';
import 'package:staff_work_track/core/responsive/app_layout.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/empty_state.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

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
      backgroundColor: WebTheme.canvasOf(context),
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
              padding: AppLayout.pagePadding(context),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFC2410C),
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Approving a request applies penalty points. That action cannot be undone.',
                                style: TextStyle(
                                  color: Color(0xFF9A3412),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: data.isEmpty
                            ? const AppEmptyState(
                                icon: Icons.assignment_turned_in_outlined,
                                title: 'No removal requests',
                                message: 'Pending task removals will show here.',
                              )
                            : ListView.separated(
                          itemCount: data.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = data[index];
                            final name = (item['userName'] ?? 'Staff').toString();
                            final initial = name.trim().isEmpty
                                ? '?'
                                : name.trim()[0].toUpperCase();

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: WebTheme.surfaceOf(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: WebTheme.lineOf(context)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: WebTheme.brandSoftOf(context),
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: WebTheme.brand,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                color: WebTheme.inkOf(context),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              TimeUtils.formatDateValue(item['removedDate']),
                                              style: TextStyle(
                                                color: WebTheme.mutedOf(context),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    (item['taskName'] ?? '-').toString(),
                                    style: TextStyle(
                                      color: WebTheme.inkOf(context),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Removed by ${(item['removedByName'] ?? '-').toString()}',
                                    style: TextStyle(
                                      color: WebTheme.mutedOf(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: WebTheme.brandSoftOf(context),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (item['reason'] ?? '-').toString(),
                                      style: TextStyle(
                                        color: WebTheme.inkOf(context),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            final confirm = await _showConfirmDialog(
                                              context,
                                              title: 'Remove without penalty',
                                              message: 'This removes the person from the task and does not apply penalty points. Continue?',
                                            );
                                            if (confirm != true) return;
                                            await _processRequest(item, applyPenalty: false);
                                          },
                                          child: const Text('No penalty'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: WebTheme.brand,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            final confirm = await _showConfirmDialog(
                                              context,
                                              title: 'Apply penalty',
                                              message: 'Penalty points will be applied based on task priority. Continue?',
                                            );
                                            if (confirm != true) return;
                                            await _processRequest(item, applyPenalty: true);
                                          },
                                          child: const Text('Apply penalty'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
