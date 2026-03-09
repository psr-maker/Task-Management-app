import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    required String createdBy,
    File? file,
  }) async {
    var uri = Uri.parse("$baseUrl/Announcement/upload-announcement");
    final token = await AuthService.getToken();

    var request = http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = "Bearer $token";

    request.fields["title"] = title;
    request.fields["description"] = description;
    request.fields["targetRole"] = targetRole;
    request.fields["createdBy"] = createdBy;

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath("file", file.path));
    }

    var response = await request.send();

    return response.statusCode == 200;
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
    required String description,
    required DateTime workDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool isSubmit,
  }) async {
    final startDateTime = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
      endTime.hour,
      endTime.minute,
    );

    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/Announcement/addworklog"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "workDate": workDate.toIso8601String(),
        "startTime": startDateTime.toIso8601String(),
        "endTime": endDateTime.toIso8601String(),
        "title": title,
        "description": description,
        "isSubmit": isSubmit,
      }),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode != 200) {
      throw Exception("Failed to save worklog");
    }
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

  static Future<void> editWorkLog({
    required int workLogId,
    required String title,
    required String description,
    required DateTime workDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final token = await AuthService.getToken();

    final startStr =
        "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00";
    final endStr =
        "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00";

    final formattedDate =
        "${workDate.year}-${workDate.month.toString().padLeft(2, '0')}-${workDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "$baseUrl/Announcement/editworklog/$workLogId"
      "?title=${Uri.encodeComponent(title)}"
      "&description=${Uri.encodeComponent(description)}"
      "&workDate=$formattedDate"
      "&startTime=$startStr"
      "&endTime=$endStr",
    );

    final response = await http.put(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception("Failed to edit worklog");
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
}
