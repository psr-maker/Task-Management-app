import 'package:image_picker/image_picker.dart';

import 'announ_service.dart';
import 'local_worklog_db.dart';
import 'network_service.dart';

class WorkLogRepository {
  /// Returns true when the worklog was stored on the phone.
  static Future<bool> saveWorkLog({
    required String title,
    required String description,
    required DateTime workDate,
    required String workType,
    required bool isSubmit,
    required double latitude,
    required double longitude,
    String? locationName,
    required XFile image,
  }) async {
    final hasNetwork = await NetworkService.hasInternet();

    // =====================================================
    // TRY CLOUD FIRST
    // =====================================================

    if (hasNetwork) {
      try {
        await AnnouncementService.addWorkLog(
          title: title,
          workType: workType,
          description: description,
          workDate: workDate,
        
          isSubmit: isSubmit,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName ?? "Unknown Location",
          image: image,
          submittedAt: DateTime.now(),
        );

        print("✅ WorkLog saved to CLOUD");

        return false;
      } catch (e) {
        print(
          "⚠️ Cloud save failed. Saving locally: $e",
        );
      }
    }

    // =====================================================
    // OFFLINE OR CLOUD FAILED
    // =====================================================

    await LocalWorkLogDB.insertWorkLog({
      'title': title,

      'description': description,

      'workDate': workDate.toIso8601String(),

      'workType': workType,

      'latitude': latitude,

      'longitude': longitude,

      'locationName': locationName,

      'imagePath': image.path,

      'isSubmit': isSubmit ? 1 : 0,

      'syncStatus': 'pending',

      'createdAt':
          DateTime.now().toIso8601String(),
    });

    print("📱 WorkLog saved LOCALLY");
    return true;
  }

  static Future<void> saveLocalCheckOut({
    required int localId,
    required double latitude,
    required double longitude,
    required String locationName,
    required XFile image,
  }) async {
    await LocalWorkLogDB.saveCheckOut(
      id: localId,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      imagePath: image.path,
    );
  }

  static Future<void> queueServerCheckOut({
    required int serverWorkLogId,
    required String title,
    required double latitude,
    required double longitude,
    required String locationName,
    required XFile image,
  }) async {
    final existing = await LocalWorkLogDB.findPendingByServerId(serverWorkLogId);
    if (existing != null) {
      await LocalWorkLogDB.saveCheckOut(
        id: existing['id'] as int,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        imagePath: image.path,
      );
      return;
    }

    final now = DateTime.now().toIso8601String();
    await LocalWorkLogDB.insertWorkLog({
      'title': title,
      'description': '',
      'workDate': now,
      'workType': 'IN',
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'imagePath': image.path,
      'isSubmit': 1,
      'syncStatus': 'pending',
      'createdAt': now,
      'outLatitude': latitude,
      'outLongitude': longitude,
      'outLocationName': locationName,
      'outImagePath': image.path,
      'outTime': now,
      'serverId': serverWorkLogId,
    });
  }

  static Future<void> checkOutWorkLog({
    required int workLogId,
    required double latitude,
    required double longitude,
    required String locationName,
    required XFile image,
  }) async {
    final hasNetwork = await NetworkService.hasInternet();
    if (!hasNetwork) {
      throw Exception("Internet is required to check out");
    }

    await AnnouncementService.checkOutWorkLog(
      workLogId: workLogId,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      image: image,
    );
  }
}