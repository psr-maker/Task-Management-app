import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/Models/warning_model.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/services/auth_service.dart';

class AnnouncementService {
  static const String baseUrl = ApiConstants.apiurl;

  static Future<List<Announcement>> fetchAnnouncements() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("User not logged in");
    print("JWT token: $token");
    final url = Uri.parse("$baseUrl/Announcement/GetAnouncements");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      print("❌❌😍😍😍");
      print(response.body);
      return data.map((e) => Announcement.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      throw Exception("Failed to load announcements");
    }
  }

  static Future<bool> postAnnouncement({
    required String title,
    required String description,
    required String targetRole,

    // mobile
    File? file,

    // web
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final token = await AuthService.getToken();

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/Announcement/postannouncements"),
      );

      // 🔐 AUTH
      request.headers["Authorization"] = "Bearer $token";

      // 📝 FIELDS
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['targetRole'] = targetRole;

      // 📎 FILE HANDLING (FIXED)
      if (kIsWeb) {
        // 🌐 WEB
        if (fileBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileName ?? "upload.jpg",
            ),
          );
        }
      } else {
        // 📱 MOBILE
        if (file != null && await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('file', file.path),
          );
        }
      }

      // 🔥 SEND
      final response = await request.send();
      final body = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $body");

      return response.statusCode == 200;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteAnnouncement(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/Announcement/delete-announcement/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(response.body);
      return false;
    }
  }

 static Future<void> addWorkLog({
  required String title,
  required String workType, // IN / OUT
  required String description,
  required DateTime workDate,
  required bool isSubmit,
  required double latitude,
  required double longitude,
  required String locationName,
  required XFile image,
  DateTime? submittedAt,
}) async {
  final token = await AuthService.getToken();

  final request = http.MultipartRequest(
    'POST',
    Uri.parse("$baseUrl/Announcement/addworklog"),
  );

  request.headers['Authorization'] = 'Bearer $token';

  request.fields['Title'] = title;
  request.fields['WorkType'] = workType;
  request.fields['Description'] = description;
  
  // Send workDate as UTC ISO8601 string
  final workDateUtc = workDate.toUtc().toIso8601String();
  request.fields['WorkDate'] = workDateUtc;
  
  request.fields['IsSubmit'] = isSubmit.toString();
  request.fields['Latitude'] = latitude.toString();
  request.fields['Longitude'] = longitude.toString();
  request.fields['LocationName'] = locationName;
  
  // Add submission timestamp for offline worklogs
  if (submittedAt != null) {
    // Send as UTC ISO8601 string so backend stores correct time
    final utcTime = submittedAt.toUtc().toIso8601String();
    request.fields['SubmittedAt'] = utcTime;
  }

  // ==========================================
  // IMAGE
  // ==========================================

  if (kIsWeb) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'Image',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );
  } else {
    request.files.add(
      await http.MultipartFile.fromPath(
        'Image',
        image.path,
        filename: image.name,
      ),
    );
  }

  final streamedResponse = await request.send();

  final response =
      await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    throw Exception(
      response.body.isNotEmpty
          ? response.body
          : "Worklog upload failed",
    );
  }

  print("WORKLOG SUCCESS: ${response.body}");
}

  static Future<List<Map<String, dynamic>>> getMyWorkLogs(DateTime date) async {
    final token = await AuthService.getToken();

    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse("$baseUrl/Announcement/myworklogs?date=$formattedDate"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load worklogs");
    }
  }

  static Future<List<dynamic>> getDepartmentWorklogs() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/Announcement/department-worklogs"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load worklogs");
    }
  }

  static Future<List<dynamic>> getWorklogs({
    String? department,
    DateTime? date,
  }) async {
    String url = "$baseUrl/Announcement/all-worklogs";

    List<String> params = [];

    if (department != null && department.isNotEmpty) {
      params.add("department=$department");
    }

    if (date != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      params.add("date=$formattedDate");
    }

    if (params.isNotEmpty) {
      url += "?${params.join("&")}";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load worklogs");
    }
  }

  static Future<Map<String, dynamic>> updateWorkLogStatus({
    required DateTime workDate,
    required String status,
  }) async {
    final token = await AuthService.getToken();

    final uri = Uri.parse(
      "$baseUrl/Announcement/updateworklogstatus?workDate=${workDate.toIso8601String()}&status=$status",
    );

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to update worklog status");
    }
  }

  Future<Map<String, dynamic>> sendWarning({
    required int receiverId,
    required String title,
    required String message,
    required String severity,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/Announcement/send-warning"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "receiverId": receiverId,
        "title": title,
        "message": message,
        "severity": severity,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send warning");
    }
  }

  static Future<List<WarningModel>> getWarnings() async {
    final token = await AuthService.getToken();
    print("TOKEN: $token");

    final response = await http.get(
      Uri.parse("$baseUrl/Announcement/get-warnings"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((warning) => WarningModel.fromJson(warning)).toList();
    } else {
      throw Exception("Failed to load warnings");
    }
  }

  static Future<List<WarningModel>> getDepartmentWarnings() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Announcement/get-department-warnings"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // ✅ Convert to model list
        return data.map((e) => WarningModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<WarningModel>> getWarningsByUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Announcement/get-warnings-by-user/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        return data.map((e) => WarningModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load warnings");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
