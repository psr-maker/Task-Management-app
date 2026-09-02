import 'local_worklog_db.dart';
import 'network_service.dart';
import 'announ_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

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
    final imagePath = log['imagePath'] as String;

    final image = XFile(imagePath);
    
    final submittedTime = DateTime.parse(log['createdAt']);

    final latitude = (log['latitude'] as num).toDouble();
    final longitude = (log['longitude'] as num).toDouble();

    // Get location name if it's missing/null
    var locationName = log['locationName'] as String?;
    if (locationName == null || locationName.isEmpty) {
      print("📍 Location name missing, fetching from coordinates...");
      locationName = await _getLocationName(latitude, longitude);
      
      // Update database with fetched location name
      await LocalWorkLogDB.updateLocationName(log['id'], locationName);
      print("✅ Location name updated: $locationName");
    }

    print("🔄 SYNCING WORKLOG:");
    print("   ID: ${log['id']}");
    print("   Original Submission Time (createdAt): ${log['createdAt']}");
    print("   Sending as SubmittedAt: ${submittedTime.toIso8601String()}");
    print("   Location: $locationName");

    await AnnouncementService.addWorkLog(
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

    await LocalWorkLogDB.markAsSynced(log['id']);

    print("✅ Worklog ${log['id']} synced successfully with submission time: ${submittedTime.toIso8601String()}");
  }
}
