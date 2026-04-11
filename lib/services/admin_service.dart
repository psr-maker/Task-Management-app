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

  static Future<bool> applyLeave({
    required int senderId,
    required String name,
    required String designation,
    required String reason,
    required DateTime fromDate,
    required DateTime toDate,
    required String leaveType,
    required double totalDays,
    required String contactNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Manager/apply-leave"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "senderId": senderId,
          "name": name,
          "designation": designation,
          "reason": reason,
          "fromDate": fromDate.toIso8601String(),
          "toDate": toDate.toIso8601String(),
          "leaveType": leaveType,
          "totalDays": totalDays,
          "contactNumber": contactNumber,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print(response.body);
        return false;
      }
    } catch (e) {
      print("Leave Error: $e");
      return false;
    }
  }

  static Future<bool> deleteLeave(int id) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse("$baseUrl/Manager/delete-leave/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Delete failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting leave: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getLeaves() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/get-leaves"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(response.body);
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  static Future<bool> updateLeaveStatus({
    required int id,
    required String status,
    String? reason,
  }) async {
    try {
      final url =
          "$baseUrl/Manager/update-leave-status?id=$id&status=$status&reason=${reason ?? ""}";

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<bool> applyPermission({
    required String name,
    required String designation,
    required String reason,
    required DateTime date,
    required String fromTime, // "HH:mm:ss"
    required String toTime, // "HH:mm:ss"
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("$baseUrl/Manager/apply-permission"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": name,
          "designation": designation,
          "reason": reason,
          "date": date.toIso8601String(),
          "fromTime": fromTime,
          "toTime": toTime,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getPermissions() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/get-permissions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getDepartmentPermissions() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/get-department-permissions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getDepartmentLeaves() async {
    try {
      final token = await AuthService.getToken();

      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/get-department-leaves"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // ✅ Success
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("Failed to load department leaves: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
