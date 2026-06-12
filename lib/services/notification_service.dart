import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'auth_service.dart';

class NotificationService {
  static const String baseUrl = ApiConstants.apiurl;
  static Future<List<dynamic>> getMyNotifications() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/Notification/MyNotifications"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load notifications");
    }
  }

  static Future<bool> deleteNotification(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/Notification/delete-notification/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteAllNotifications() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/Notification/delete-all'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  static Future<void> markAllRead() async {
  final token = await AuthService.getToken();

  await http.put(
    Uri.parse('$baseUrl/Notification/mark-all-read'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );
}
}
