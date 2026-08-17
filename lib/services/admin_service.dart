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
    required String leavetyp,
    int? compensationExtraWorkId,
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
          "leavetyp": leavetyp,
          if (compensationExtraWorkId != null)
            "compensationExtraWorkId": compensationExtraWorkId,
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

  static Future<bool> updatePermissionStatus({
    required int id,
    required String status,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(
          "$baseUrl/Manager/update-permission-status?id=$id&status=$status",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deletePermission(int id) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.delete(
        Uri.parse("$baseUrl/Manager/delete-permission/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      return response.statusCode == 200;
    } catch (e) {
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

  static Future<void> applyOvertime({
    required int uid,
    required String dept,
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Manager/overtime-entry'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "uid": uid,
        "dept": dept,
        "date": date,
        "fromTime": startTime,
        "toTime": endTime,
        "reason": reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to apply overtime");
    }
  }

  static Future<List<dynamic>> getMyOverTimes() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/Manager/my-overtimes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load my overtime data");
  }

  static Future<List<dynamic>> getDepartmentOverTimes() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/Manager/department-overtimes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load department overtime data");
  }

  static Future<Map<String, dynamic>> approveOvertime(
    int id,
    bool isApproved,
  ) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/Manager/overtime-approve/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"isApproved": isApproved}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  static Future<List<dynamic>> getApprovedOvertimes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Manager/getovertimes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load overtimes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching overtimes: $e');
    }
  }

  Future<Map<String, dynamic>> addExtraWork({
    required DateTime workedDate,
    required String workType,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    final url = Uri.parse('$baseUrl/Manager/extra-work');

    final body = {
      'workedDate': workedDate.toIso8601String(),
      'workType': workType,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final responseData = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    throw Exception(
      responseData['message'] ??
          responseData['title'] ??
          'Failed to submit extra work',
    );
  }

  Future<List<dynamic>> getMyExtraWork() async {
    final token = await AuthService.getToken();

    final url = Uri.parse('$baseUrl/Manager/get-extra-work');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      return [];
    }

    final data = _decodeResponse(response);

    throw Exception(
      data['message'] ?? data['title'] ?? 'Failed to get extra work',
    );
  }

  Future<List<dynamic>> getDepartmentExtraWork() async {
    final token = await AuthService.getToken();

    final url = Uri.parse('$baseUrl/Manager/get-department-extra-work');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      return [];
    }

    final data = _decodeResponse(response);

    throw Exception(
      data['message'] ?? data['title'] ?? 'Failed to get department extra work',
    );
  }

  Future<Map<String, dynamic>> updateExtraWorkStatus({
    required int id,
    required String status,
    String? remarks,
  }) async {
    final token = await AuthService.getToken();

    final url = Uri.parse('$baseUrl/Manager/approve-extra-work/$id');

    final body = {'status': status, 'remarks': remarks};

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message'] ?? data['title'] ?? 'Failed to update extra work status',
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    } catch (_) {
      return {'message': response.body};
    }
  }

  static Future<bool> createPunchCorrection({
    required DateTime date,
    required String correctionType,
    required String punchTime,
    required String reason,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/Manager/punch-correction"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "date": date.toIso8601String(),
          "correctionType": correctionType,
          "punchTime": punchTime,
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Punch Correction Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Punch Correction Error: $e");
      return false;
    }
  }

  static Future<bool> managerPunchCorrection({
    required int id,
    required bool approved,
  }) async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        print("Token not found");
        return false;
      }

      final response = await http.put(
        Uri.parse("$baseUrl/Manager/punch-correction/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"approved": approved}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("Punch Correction Updated");
        print("Status: ${data["status"]}");

        return true;
      } else if (response.statusCode == 401) {
        print("Unauthorized - token expired or invalid");
        return false;
      } else if (response.statusCode == 404) {
        print("Punch correction not found");
        return false;
      } else if (response.statusCode == 400) {
        print("Already processed: ${response.body}");
        return false;
      } else {
        print(
          "Manager Punch Correction Error: "
          "${response.statusCode} ${response.body}",
        );
        return false;
      }
    } catch (e) {
      print("Manager Punch Correction Error: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getDepartmentPunchCorrections() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        print("Token not found");
        return [];
      }

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/department-punch-corrections"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("Department: ${data["department"]}");
        print("Count: ${data["count"]}");

        return data["data"] ?? [];
      } else if (response.statusCode == 403) {
        print("User does not have permission to view department corrections");
        return [];
      } else if (response.statusCode == 401) {
        print("Unauthorized - token expired or invalid");
        return [];
      } else {
        print(
          "Department Punch Correction Error: "
          "${response.statusCode} ${response.body}",
        );

        return [];
      }
    } catch (e) {
      print("Department Punch Correction Error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getMyPunchCorrections() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        print("Token not found");
        return [];
      }

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/my-punch-corrections"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["data"] ?? [];
      } else {
        print(
          "My Punch Correction Error: "
          "${response.statusCode} ${response.body}",
        );

        return [];
      }
    } catch (e) {
      print("My Punch Correction Error: $e");
      return [];
    }
  }

  static Future<bool> addAttitudeBehaviourScore({
    required int staffId,
    required int communication,
    required int punctuality,
    required int integrity,
    required DateTime date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Manager/add-attitude-behaviour-score'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "staffId": staffId,
          "communication": communication,
          "punctuality": punctuality,
          "integrity": integrity,
          "date": date.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          "Add Attitude Behaviour Score Error: "
          "${response.statusCode} - ${response.body}",
        );
        return false;
      }
    } catch (e) {
      print("Add Attitude Behaviour Score Exception: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>>
  getDepartmentAttitudeBehaviourScores() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/Manager/department-attitude-behaviour-scores'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List scores = data['scores'] ?? [];

        return scores
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      print(
        "Get Department Behaviour Scores Error: "
        "${response.statusCode} - ${response.body}",
      );

      throw Exception("Failed to load attitude & behaviour scores");
    } catch (e) {
      print("Get Department Behaviour Scores Exception: $e");

      rethrow;
    }
  }
}
