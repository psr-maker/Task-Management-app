import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static const String versionApi =
      'https://staff.poornasreecloud.com/api/AppVersion';

  static Future<Map<String, dynamic>?> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(versionApi),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      return {
        'currentVersion': currentVersion,
        'latestVersion': data['latestVersion'],
        'downloadUrl': data['downloadUrl'],
        'forceUpdate': data['forceUpdate'] ?? false,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      print('Version check error: $e');
      return null;
    }
  }

  static bool isNewerVersion(
    String current,
    String latest,
  ) {
    final currentParts =
        current.split('.').map(int.parse).toList();

    final latestParts =
        latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final currentValue =
          i < currentParts.length ? currentParts[i] : 0;

      final latestValue =
          i < latestParts.length ? latestParts[i] : 0;

      if (latestValue > currentValue) {
        return true;
      }

      if (latestValue < currentValue) {
        return false;
      }
    }

    return false;
  }
}