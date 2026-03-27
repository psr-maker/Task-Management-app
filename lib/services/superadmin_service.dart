import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/Models/auditlog.dart';
import 'package:staff_work_track/Models/department.dart';

import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/Models/userstask.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';

class SuperAdminService {
  static const String baseUrl = ApiConstants.apiurl;

  static Future<List<UserModel>> getAllUsers() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Director/getallusers"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List list = decoded['users'];

        return list.map((e) => UserModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load users");
      }
    } catch (e) {
      throw Exception("UserService Error: $e");
    }
  }

  static Future<List<dynamic>> getGoals() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Director/GetGoalsWithTasks"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load goals");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  // get all admin
 static Future<List<dynamic>> getGoalsname() async {
   final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/Director/GetGoals"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load goals");
    }
  }
  static Future<List<UserModel>> getAdmins() async {
    final response = await http.get(
      Uri.parse("$baseUrl/Director/getAllManager"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load admins");
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    // Fix key here
    final List list = json['admins'] ?? [];

    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  // get admin details
  static Future<UsersDetails> getAdminDetails(int adminId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/Director/usersdetails/$adminId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return UsersDetails.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load admin details");
    }
  }

  // update users status

  static Future<void> updateusersstatus(int userId, String status) async {
    final response = await http.put(
      Uri.parse("$baseUrl/Director/update-usersstatus/$userId/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Status": status}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update status");
    }
  }

  // get all employees

  static Future<List<UserModel>> getEmployees() async {
    final response = await http.get(
      Uri.parse("$baseUrl/Director/getallstaff"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load employees");
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final List list = json['employees'] ?? [];

    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  // create task to users

  static Future<bool> createGoal({
    required String title,
    required String priority,
    required DateTime startDate,
    required DateTime dueDate,
    required String assignTo,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("User not logged in");
    print("JWT token: $token");
    final response = await http.post(
      Uri.parse("$baseUrl/Director/CreateGoal"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "priority": priority,
        "startDate": startDate.toIso8601String(),
        "dueDate": dueDate.toIso8601String(),
        "assign_To": assignTo,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> createTask({
    required String task,
    required String description,
    required String goalCode,
    required String priority,
    required DateTime assignedAt,
    required DateTime dueDate,

    required List<int> assignedToIds,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception("User not logged in");
      print("JWT token: $token");
      final response = await http.post(
        Uri.parse("$baseUrl/Director/Task-assign"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "task": task,
          "description": description,
          "goalCode": goalCode,
          "priority": priority,
          "start_date": assignedAt.toIso8601String(),
          "due_Date": dueDate.toIso8601String(),
          "assignedToIds": assignedToIds,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Create task failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error creating task: $e");
      return false;
    }
  }

  // get all users task

  static Future<Map<String, dynamic>> getAllTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/Director/tasks"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load tasks");
    }
  }

  static Future<Map<String, dynamic>> getTaskByCode(String taskCode) async {
    final response = await http.get(
      Uri.parse("$baseUrl/Director/taskbyid/$taskCode"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load task details");
    }
  }

  static Future<bool> updateTask(EditTaskRequest request) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.put(
        Uri.parse("$baseUrl/Director/Task-edit"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Update task failed: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Update task error: $e");
      return false;
    }
  }

  static Future<bool> deleteTask(String taskCode) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/Director/Task-delete/$taskCode"),
        headers: {
          "Authorization": "Bearer ${await AuthService.getToken()}",
          "Content-Type": "application/json",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete task error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String name,
    required String email,
    required String department,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/Director/user-edit/$userId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "department": department,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update user");
    }
  }

  static Future<bool> deleteUser(int userId) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/Director/user-delete/$userId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<AuditLogModel>> getAuditLogs() async {
    // final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/Director/auditlog"),
      headers: {
        "Content-Type": "application/json",
        // "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print("AUDIT RESPONSE✨✨✨: ${response.body}");
      return data.map((e) => AuditLogModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load audit logs");
    }
  }

  Future<List<Department>> getDepartments() async {
    final response = await http.get(
      Uri.parse("$baseUrl/Director/getdepartments"),
    );

    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((e) => Department.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load departments');
    }
  }

  Future<Department> addDepartment(Department department) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Director/adddepartment"),
      headers: {
        'Content-Type': 'application/json',
        // add Authorization if your API requires it
      },
      body: json.encode(department.toJson()),
    );

    print("POST JSON: ${json.encode(department.toJson())}");
    print("Response status: ${response.statusCode}, body: ${response.body}");

    if (response.statusCode == 201) {
      return Department.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400) {
      // Show validation errors
      final error = jsonDecode(response.body);
      throw Exception("Validation error: $error");
    } else {
      throw Exception('Failed to add department');
    }
  }
}
