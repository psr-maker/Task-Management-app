import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:staff_work_track/core/theme/web_theme.dart';
import 'package:staff_work_track/core/widgets/buttons.dart';
import 'package:staff_work_track/core/widgets/loading.dart';
import 'package:staff_work_track/core/widgets/msgsnackbar.dart';
import 'package:staff_work_track/screen/staff/navigation/fullimg.dart';
import 'package:staff_work_track/screen/staff/navigation/worklog/checkout_worklog.dart';
import 'package:staff_work_track/services/local_worklog_db.dart';
import 'package:staff_work_track/services/worklog_sync_service.dart';
import 'package:staff_work_track/utils/time_utils.dart';

class OfflineWorkLogs extends StatefulWidget {
  const OfflineWorkLogs({super.key});

  @override
  State<OfflineWorkLogs> createState() => _OfflineWorkLogsState();
}

class _OfflineWorkLogsState extends State<OfflineWorkLogs> {
  List<Map<String, dynamic>> pendingLogs = [];

  bool isLoading = true;
  bool isSyncingAll = false;

  // IDs currently syncing
  final Set<int> syncingIds = {};
  String? _topMessage;

  bool _isErrorMessage = true;

  bool _showTopMessage = false;
  @override
  void initState() {
    super.initState();
    loadPendingLogs();
  }

  Future<void> loadPendingLogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await LocalWorkLogDB.getPendingWorkLogs();

      if (!mounted) return;

      setState(() {
        pendingLogs = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showTopMessage("Failed to load offline worklogs", isError: true);
    }
  }

  Future<void> syncAll() async {
    if (pendingLogs.isEmpty) {
      showTopMessage("No pending worklogs", isError: false);
      return;
    }

    setState(() {
      isSyncingAll = true;
    });

    try {
      final result = await WorkLogSyncService.syncPendingWorkLogs();

      await loadPendingLogs();

      if (!mounted) return;

      showTopMessage(result.message, isError: result.isError);
    } catch (e) {
      if (!mounted) return;

      showTopMessage(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSyncingAll = false;
        });
      }
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
        title: const Text("Local worklogs"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Sync All",
            onPressed: isSyncingAll ? null : syncAll,
            icon: isSyncingAll ? RotatingFlower() : const Icon(Icons.sync),
          ),
        ],
      ),

      body: Stack(
        children: [
          _buildBody(),
          if (_topMessage != null)
            AnimatedPositioned(
              top: _showTopMessage ? 0 : -120,

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
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    if (pendingLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.cloud_done_outlined,
              size: 70,
              color: Colors.green.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              "No Pending Worklogs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "All offline worklogs are synced",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadPendingLogs,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: pendingLogs.length,

        itemBuilder: (context, index) {
          final log = pendingLogs[index];

          return _buildWorkLogCard(log);
        },
      ),
    );
  }

  Future<void> _checkOut(Map<String, dynamic> log) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutWorklogPage(
          localId: log['id'] as int,
          title: (log['title'] ?? '').toString(),
        ),
      ),
    );

    if (!mounted || result == null) return;
    showTopMessage('Your check out saved locally.', isError: false);
    await loadPendingLogs();
  }

  Widget _buildWorkLogCard(Map<String, dynamic> log) {
    final int id = log['id'];
    final bool syncing = syncingIds.contains(id);
    final title = (log['title'] ?? '').toString();
    final description = (log['description'] ?? '').toString();
    final inPath = (log['imagePath'] ?? '').toString();
    final outPath = (log['outImagePath'] ?? '').toString();
    final inLocation = (log['locationName'] ?? '').toString();
    final outLocation = (log['outLocationName'] ?? '').toString();
    final serverId = log['serverId'];
    final queuedCheckout = serverId != null && outPath.isNotEmpty && inPath == outPath;
    final hasOut = outPath.isNotEmpty;
    final dateText = TimeUtils.formatDateValue(log['workDate'], empty: '');
    final inTime = TimeUtils.formatTime12(log['createdAt'], empty: '--');
    final outTime = TimeUtils.formatTime12(log['outTime'], empty: '--');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: WebTheme.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? 'Worklog' : title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WebTheme.inkOf(context),
            ),
          ),
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(dateText, style: TextStyle(color: WebTheme.mutedOf(context))),
          ],
          if (description.isNotEmpty && !queuedCheckout) ...[
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: WebTheme.mutedOf(context))),
          ],
          const SizedBox(height: 12),
          if (queuedCheckout)
            _localPhoto(
              label: 'OUT  $outTime',
              path: outPath,
              location: outLocation,
              color: const Color(0xFFC2410C),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _localPhoto(
                    label: 'IN  $inTime',
                    path: inPath,
                    location: inLocation,
                    color: const Color(0xFF166534),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _localPhoto(
                    label: hasOut ? 'OUT  $outTime' : 'OUT',
                    path: outPath,
                    location: outLocation,
                    color: const Color(0xFFC2410C),
                    emptyText: 'Not checked out',
                  ),
                ),
              ],
            ),
          if (!hasOut) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Check Out',
                onPressed: () => _checkOut(log),
                color: WebTheme.brand,
                txtcolor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 5),
              Text(
                syncing ? 'Syncing...' : 'Pending sync',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _localPhoto({
    required String label,
    required String path,
    required String location,
    required Color color,
    String emptyText = 'No photo',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: path.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(imageFile: File(path)),
                    ),
                  );
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: path.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade100,
                      child: Text(emptyText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  : kIsWeb
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          location.isEmpty ? 'No location' : location,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: WebTheme.mutedOf(context)),
        ),
      ],
    );
  }
}
