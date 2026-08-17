import 'local_worklog_db.dart';
import 'network_service.dart';
import 'announ_service.dart';
import 'package:image_picker/image_picker.dart';

class WorkLogSyncService {
  static bool _isSyncing = false;

  static Future<void> syncPendingWorkLogs() async {
    if (_isSyncing) {
      print("Sync already running...");
      return;
    }

    _isSyncing = true;

    try {
      final hasNetwork = await NetworkService.hasInternet();

      if (!hasNetwork) {
        print("No internet. Sync skipped.");
        return;
      }

      final pendingLogs = await LocalWorkLogDB.getPendingWorkLogs();

      if (pendingLogs.isEmpty) {
        print("No pending worklogs.");
        return;
      }

      print("Found ${pendingLogs.length} pending worklogs");

      // ================================================
      // SYNC ONE BY ONE
      // ================================================

      for (final log in pendingLogs) {
        try {
          await _syncSingleWorkLog(log);
        } catch (e) {
          print("Failed to sync local worklog ${log['id']}: $e");
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _syncSingleWorkLog(Map<String, dynamic> log) async {
    final imagePath = log['imagePath'] as String;

    final image = XFile(imagePath);

    await AnnouncementService.addWorkLog(
      title: log['title'] ?? '',
      workType: log['workType'] ?? '',
      description: log['description'] ?? '',
      workDate: DateTime.parse(log['workDate']),
      isSubmit: log['isSubmit'] == 1,
      latitude: (log['latitude'] as num).toDouble(),
      longitude: (log['longitude'] as num).toDouble(),
      locationName: log['locationName'] ?? '',
      image: image,
    );

    await LocalWorkLogDB.markAsSynced(log['id']);

    print("Worklog ${log['id']} synced successfully");
  }
}
