import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';

class AdminService {
  static const String baseUrl = ApiConstants.apiurl;

  static Future<List<UserModel>> getEmployeesByDepartment(
    String department,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Manager/staffbydept/$department'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List employeesJson = data['employees'] ?? [];
      return employeesJson.map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load employees");
    }
  }

  static Future<List<dynamic>> getGoalsByDepartment(String department) async {
    try {
      final url = Uri.parse("$baseUrl/Manager/allStaffGoals/$department");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ API structure:
        // { department, totalGoals, goals: [] }

        return data["goals"] ?? [];
      } else {
        throw Exception("Failed to load goals: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching goals: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminTasks(int adminId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/Manager/userstaskslist/$adminId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        json.decode(response.body)["result"],
      );
    } else {
      throw Exception("Failed to load admin tasks");
    }
  }

  static Future<void> updateTaskStatus({
    required String taskCode,
    required TaskStatus status,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.put(
      Uri.parse("$baseUrl/Manager/update-task-status"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"taskCode": taskCode, "status": status.name}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Status update failed (${response.statusCode}): ${response.body}",
      );
    }
  }

  static Future<List<dynamic>> getTasksByDepartment(String department) async {
    final url = Uri.parse("$baseUrl/Manager/allStafftask/$department");

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["tasks"] ?? [];
      } else {
        throw Exception("Failed to load tasks. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching department tasks: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getCompletedTaskPoints() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/completed-task"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load completed task points");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  static Future<bool> submitReview({
    required String taskCode,
    required int managerPoints,
    required bool isDelayJustified,
    required String delayReason,
    required String comment,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token not found");

    final response = await http.post(
      Uri.parse("$baseUrl/Manager/review-task"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "taskCode": taskCode,
        "managerPoints": managerPoints,
        "isDelayJustified": isDelayJustified,
        "delayReason": delayReason,
        "comment": comment,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Failed to submit review");
    }
  }

  static Future<Map<String, dynamic>?> getReview(String taskCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Manager/getreview/$taskCode'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception("Failed to fetch review");
    }
  }

  static Future<List<dynamic>> getusergoalbyid(int userid) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/usersgoallist/$userid"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("Failed to load manager tasks");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<dynamic>> getgoalAssignedByAdmin(int adminId) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/Managergoalsassigned/$adminId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("Failed to load manager tasks");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<bool> saveFiveSPoints({
    required int staffId,
    required String dept,
    required int month,
    required int week,
    required int points,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Manager/fiveSpoints"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "staffId": staffId,
          "department": dept,
          "month": month,
          "week": week,
          "year": DateTime.now().year,
          "points": points,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("5S Error: $e");
      return false;
    }
  }

  static Future<bool> addWarranty({
    required int staffId,
    required int totalWork,
    required int complaints,
  }) async {
    try {
      final url = Uri.parse(
        "$baseUrl/Manager/add-warranty?staffId=$staffId&totalWork=$totalWork&complaints=$complaints",
      );

      final response = await http.post(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print(response.body);
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
}
