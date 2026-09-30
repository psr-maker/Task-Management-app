import 'local_worklog_db.dart';
import 'network_service.dart';
import 'announ_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

class WorkLogSyncResult {
  const WorkLogSyncResult({
    required this.online,
    required this.syncedCount,
    required this.failedCount,
  });

  final bool online;
  final int syncedCount;
  final int failedCount;

  String get message {
    if (!online) {
      return "Internet is not available to save to the cloud.";
    }
    if (syncedCount > 0 && failedCount == 0) {
      return "Successfully saved to the cloud.";
    }
    if (failedCount > 0) {
      return "Could not save the worklog to the cloud.";
    }
    return "No worklogs waiting to sync.";
  }

  bool get isError => !online || failedCount > 0;
}

class WorkLogSyncService {
  static bool _isSyncing = false;

  static Future<WorkLogSyncResult> syncPendingWorkLogs() async {
    if (_isSyncing) {
      print("Sync already running...");
      return const WorkLogSyncResult(online: true, syncedCount: 0, failedCount: 0);
    }

    _isSyncing = true;

    try {
      final hasNetwork = await NetworkService.hasInternet();

      if (!hasNetwork) {
        print("No internet. Sync skipped.");
        return const WorkLogSyncResult(online: false, syncedCount: 0, failedCount: 0);
      }

      final pendingLogs = await LocalWorkLogDB.getPendingWorkLogs();

      if (pendingLogs.isEmpty) {
        print("No pending worklogs.");
        return const WorkLogSyncResult(online: true, syncedCount: 0, failedCount: 0);
      }

      print("Found ${pendingLogs.length} pending worklogs");

      var syncedCount = 0;
      var failedCount = 0;

      for (final log in pendingLogs) {
        try {
          await _syncSingleWorkLog(log);
          syncedCount++;
        } catch (e) {
          failedCount++;
          print("Failed to sync local worklog ${log['id']}: $e");
        }
      }

      return WorkLogSyncResult(
        online: true,
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    } finally {
      _isSyncing = false;
    }
  }

  static bool _missingLocation(String? name) {
    final text = (name ?? '').trim().toLowerCase();
    return text.isEmpty || text == 'unknown location';
  }

  static Future<String> _getLocationName(double latitude, double longitude) async {
    String locationName = "Unknown Location";

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final fullAddress = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        locationName = fullAddress.isNotEmpty
            ? fullAddress
            : "Unknown Location";
      }
    } catch (e) {
      print("⚠️ Failed to get location name during sync: $e");
    }

    return locationName;
  }

  static Future<void> _syncSingleWorkLog(Map<String, dynamic> log) async {
    final localId = log['id'] as int;
    final serverRaw = log['serverId'];
    int? serverId = serverRaw == null
        ? null
        : (serverRaw is int ? serverRaw : int.tryParse(serverRaw.toString()));

    if (serverId == null) {
      final imagePath = log['imagePath'] as String;
      final image = XFile(imagePath);
      final submittedTime = DateTime.parse(log['createdAt']);
      final latitude = (log['latitude'] as num).toDouble();
      final longitude = (log['longitude'] as num).toDouble();

      var locationName = (log['locationName'] ?? '').toString();
      if (_missingLocation(locationName)) {
        locationName = await _getLocationName(latitude, longitude);
        await LocalWorkLogDB.updateLocationName(localId, locationName);
      }

      serverId = await AnnouncementService.addWorkLog(
        title: log['title'] ?? '',
        workType: log['workType'] ?? '',
        description: log['description'] ?? '',
        workDate: DateTime.parse(log['workDate']),
        isSubmit: log['isSubmit'] == 1,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        image: image,
        submittedAt: submittedTime,
      );

      await LocalWorkLogDB.setServerId(localId, serverId);
    }

    final outPath = (log['outImagePath'] ?? '').toString();
    if (outPath.isNotEmpty) {
      final outLatitude = (log['outLatitude'] as num?)?.toDouble() ?? 0;
      final outLongitude = (log['outLongitude'] as num?)?.toDouble() ?? 0;
      var outLocation = (log['outLocationName'] ?? '').toString();
      if (_missingLocation(outLocation)) {
        outLocation = await _getLocationName(outLatitude, outLongitude);
        await LocalWorkLogDB.updateOutLocationName(localId, outLocation);
      }

      await AnnouncementService.checkOutWorkLog(
        workLogId: serverId,
        latitude: outLatitude,
        longitude: outLongitude,
        locationName: outLocation,
        image: XFile(outPath),
      );
    }

    await LocalWorkLogDB.markAsSynced(localId);
  }
}
