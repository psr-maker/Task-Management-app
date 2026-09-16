import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static const String versionApi =
      'https://staff.poornasreecloud.com/api/AppVersion';

  static const String defaultDownloadUrl =
      'https://staff.poornasreecloud.com/downloads/workpulse.apk';

  static bool get shouldCheckUpdate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<Map<String, dynamic>?> checkVersion() async {
    if (!shouldCheckUpdate) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      final response = await http.get(
        Uri.parse('$versionApi?t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: const {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Version check HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final data = Map<String, dynamic>.from(decoded);
      final latestVersion = (data['latestVersion'] ??
              data['LatestVersion'] ??
              data['version'] ??
              '')
          .toString()
          .trim();

      var downloadUrl = (data['downloadUrl'] ??
              data['downloadURL'] ??
              data['DownloadUrl'] ??
              data['apkUrl'] ??
              '')
          .toString()
          .trim();
      if (downloadUrl.isEmpty) {
        downloadUrl = defaultDownloadUrl;
      }

      return {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'downloadUrl': downloadUrl,
        'message': (data['message'] ?? data['Message'] ?? '').toString(),
      };
    } catch (e) {
      debugPrint('Version check error: $e');
      return null;
    }
  }

  static bool isNewerVersion(String current, String latest) {
    final currentParts = _versionParts(current);
    final latestParts = _versionParts(latest);
    if (currentParts.isEmpty || latestParts.isEmpty) return false;

    final length = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (int i = 0; i < length; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final latestValue = i < latestParts.length ? latestParts[i] : 0;

      if (latestValue > currentValue) return true;
      if (latestValue < currentValue) return false;
    }

    return false;
  }

  static List<int> _versionParts(String value) {
    final cleaned = value.trim().toLowerCase().replaceFirst(RegExp(r'^v'), '');
    if (cleaned.isEmpty) return [];

    return cleaned.split('.').map((part) {
      final digits = RegExp(r'\d+').firstMatch(part)?.group(0);
      return int.tryParse(digits ?? '') ?? 0;
    }).toList();
  }
}
