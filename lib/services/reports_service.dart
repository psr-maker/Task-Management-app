import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/services/auth_service.dart';

class ReportsService {
  static const String baseUrl = ApiConstants.apiurl;

  static Future<Map<String, dynamic>> fetchReport({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{};

    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final uri = Uri.parse(
      '$baseUrl/Reports/overall-summary',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to fetch dashboard report: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching dashboard report: $e');
    }
  }

  static Future<List<String>> getAllDepartments() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/Reports/GetAllDepartments"),
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load departments");
    }

    final decoded = json.decode(response.body);
    final raw = decoded is List
        ? decoded
        : decoded is Map
        ? decoded["data"] ??
              decoded["Data"] ??
              decoded["departments"] ??
              decoded["Departments"]
        : null;
    if (raw is! List) return [];

    final names = <String>[];
    for (final item in raw) {
      final name = item is String
          ? item
          : item is Map
          ? (item["departmentName"] ??
                    item["DepartmentName"] ??
                    item["name"] ??
                    item["Name"] ??
                    "")
                .toString()
          : item.toString();
      final value = name.trim();
      if (value.isEmpty || value == "null") continue;
      if (names.any((existing) => existing.toLowerCase() == value.toLowerCase())) {
        continue;
      }
      names.add(value);
    }
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  static Future<Map<String, dynamic>> getdeptMonthlyProductivity(
    String department,
    int year,
  ) async {
    final url = Uri.parse(
      "$baseUrl/Reports/department-monthly-productivity/$department?year=$year",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load department productivity");
    }
  }

  static Future<Map<String, dynamic>> fetchDepartmentReport(
    String department, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final uri = Uri.parse(
      '$baseUrl/Reports/department-summary/$department',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load department report");
    }
  }

  static Future<Map<String, dynamic>> getEmployeeReport(
    int employeeId,
    int year,
  ) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/Reports/Staff/$employeeId/Year/$year"),
      headers: {
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load employee report");
    }
  }

  static Future<List<dynamic>> getMonthlyProductivity(
    int userId,
    int year,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/Reports/monthly-productivity/$userId?year=$year"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final monthly = data is Map ? data["monthlyData"] : null;
      if (monthly is List) return monthly;
      return [];
    } else {
      throw Exception("Failed to load monthly productivity");
    }
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static Future<Map<String, dynamic>> fetchDivisionReport(
    List<String> departments, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (departments.isEmpty) {
      return {
        "totalUsers": 0,
        "totalDepartments": 0,
        "totalGoals": 0,
        "completedGoals": 0,
        "pendingGoals": 0,
        "overdueGoals": 0,
        "totalTasks": 0,
        "completedTasks": 0,
        "pendingTasks": 0,
        "overdueTasks": 0,
        "goalCompletionPercentage": 0,
        "onTimeGoalCompletionPercentage": 0,
        "delayedGoalPercentage": 0,
        "departmentData": <Map<String, dynamic>>[],
        "overdueTasksList": <Map<String, dynamic>>[],
        "overdueGoalsList": <Map<String, dynamic>>[],
      };
    }

    final results = await Future.wait(
      departments.map((department) async {
        try {
          return await fetchDepartmentReport(
            department,
            fromDate: fromDate,
            toDate: toDate,
          );
        } catch (_) {
          return <String, dynamic>{};
        }
      }),
    );

    int totalUsers = 0;
    int totalGoals = 0;
    int completedGoals = 0;
    int pendingGoals = 0;
    int overdueGoals = 0;
    int totalTasks = 0;
    int completedTasks = 0;
    int pendingTasks = 0;
    int overdueTasks = 0;
    double onTimeWeighted = 0;
    double delayedWeighted = 0;
    int onTimeWeight = 0;
    int delayedWeight = 0;

    final departmentData = <Map<String, dynamic>>[];
    final overdueTasksList = <Map<String, dynamic>>[];
    final overdueGoalsList = <Map<String, dynamic>>[];

    for (var i = 0; i < departments.length; i++) {
      final data = results[i];
      final users = _asInt(data["totalUsers"]);
      final goalsTotal = _asInt(data["totalGoals"]);
      final goalsCompleted = _asInt(data["completedGoals"]);
      final goalsPending = _asInt(data["pendingGoals"]);
      final goalsOverdue = _asInt(data["overdueGoals"]);
      final tasksTotal = _asInt(data["totalTasks"]);
      final tasksCompleted = _asInt(data["completedTasks"]);
      final tasksPending = _asInt(data["pendingTasks"]);
      final tasksOverdue = _asInt(data["overdueTasks"]);

      totalUsers += users;
      totalGoals += goalsTotal;
      completedGoals += goalsCompleted;
      pendingGoals += goalsPending;
      overdueGoals += goalsOverdue;
      totalTasks += tasksTotal;
      completedTasks += tasksCompleted;
      pendingTasks += tasksPending;
      overdueTasks += tasksOverdue;

      if (goalsTotal > 0) {
        onTimeWeighted +=
            _asDouble(data["onTimeGoalCompletionPercentage"]) * goalsTotal;
        delayedWeighted += _asDouble(data["delayedGoalPercentage"]) * goalsTotal;
        onTimeWeight += goalsTotal;
        delayedWeight += goalsTotal;
      }

      departmentData.add({
        "department": departments[i],
        "totalUsers": users,
        "tasks": {
          "total": tasksTotal,
          "completed": tasksCompleted,
          "pending": tasksPending,
          "overdue": tasksOverdue,
        },
        "goals": {
          "total": goalsTotal,
          "completed": goalsCompleted,
          "pending": goalsPending,
          "overdue": goalsOverdue,
        },
      });

      overdueTasksList.addAll(
        List<Map<String, dynamic>>.from(data["overdueTasksList"] ?? []),
      );
      overdueGoalsList.addAll(
        List<Map<String, dynamic>>.from(data["overdueGoalsList"] ?? []),
      );
    }

    return {
      "totalUsers": totalUsers,
      "totalDepartments": departments.length,
      "totalGoals": totalGoals,
      "completedGoals": completedGoals,
      "pendingGoals": pendingGoals,
      "overdueGoals": overdueGoals,
      "totalTasks": totalTasks,
      "completedTasks": completedTasks,
      "pendingTasks": pendingTasks,
      "overdueTasks": overdueTasks,
      "goalCompletionPercentage": totalGoals == 0
          ? 0
          : (completedGoals / totalGoals) * 100,
      "onTimeGoalCompletionPercentage": onTimeWeight == 0
          ? 0
          : onTimeWeighted / onTimeWeight,
      "delayedGoalPercentage": delayedWeight == 0
          ? 0
          : delayedWeighted / delayedWeight,
      "departmentData": departmentData,
      "overdueTasksList": overdueTasksList,
      "overdueGoalsList": overdueGoalsList,
    };
  }

  static List<dynamic> _reportList(Map decoded, List<String> keys) {
    for (final key in keys) {
      final value = decoded[key];
      if (value is List) return value;
    }

    for (final entry in decoded.entries) {
      final name = entry.key.toString().toLowerCase();
      final matches = keys.any((key) => key.toLowerCase() == name);
      if (matches && entry.value is List) {
        return entry.value as List;
      }
    }

    return [];
  }

  static Future<Map<String, dynamic>> getFullReport({
    int? userId,
    String? department,
  }) async {
    final token = await AuthService.getToken();
    final departmentName = department?.trim();
    final uri = Uri.parse("$baseUrl/Reports/FilteredFullReport").replace(
      queryParameters: {
        if (userId != null) "userId": userId.toString(),
        if (departmentName != null && departmentName.isNotEmpty)
          "department": departmentName,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load report (${response.statusCode})");
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception("Report response was not valid");
    }

    return {
      "users": _reportList(decoded, ["users", "Users"]),
      "tasks": _reportList(decoded, ["tasks", "Tasks"]),
      "goals": _reportList(decoded, ["goals", "Goals"]),
      "leaveList": _reportList(decoded, ["leaveList", "LeaveList"]),
      "permissionList": _reportList(decoded, [
        "permissionList",
        "PermissionList",
      ]),
    };
  }
}
