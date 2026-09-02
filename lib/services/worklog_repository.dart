import 'package:image_picker/image_picker.dart';

import 'announ_service.dart';
import 'local_worklog_db.dart';
import 'network_service.dart';

class WorkLogRepository {
  static Future<void> saveWorkLog({
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

        return;
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
  }
}