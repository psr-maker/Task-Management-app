import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/services/auth_service.dart';

class OvertimeService {
  static const String baseUrl = ApiConstants.apiurl;

  static Future<Map<String, dynamic>> createOvertime({
    required int uid,
    required String dept,
    required DateTime date,
    required String fromTime,
    required String toTime,
    required String reason,
  }) async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        print("OVERTIME ERROR: Token is null or empty");

        return {"success": false, "message": "User is not logged in"};
      }

      print("OVERTIME TOKEN EXISTS: ${token.isNotEmpty}");

      final response = await http.post(
        Uri.parse("$baseUrl/Manager/create_overtime"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "uid": uid,
          "dept": dept,
          "date": date.toIso8601String(),
          "fromTime": fromTime,
          "toTime": toTime,
          "reason": reason,
        }),
      );

      print("CREATE OVERTIME STATUS: ${response.statusCode}");
      print("CREATE OVERTIME RESPONSE: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      return {"success": false, "message": response.body};
    } catch (e) {
      print("Error creating overtime: $e");

      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> staffResponse({
    required int overtimeId,
    required String status,
    String? reason,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.put(
        Uri.parse("$baseUrl/Manager/$overtimeId/staff-response"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "status": status,
          if (reason != null && reason.trim().isNotEmpty) "reason": reason,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        print("Staff overtime response error: ${response.body}");

        return {"success": false, "message": response.body};
      }
    } catch (e) {
      print("Error in staff overtime response: $e");

      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> managerResponse({
    required int overtimeId,
    required String status,
    String? reason,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.put(
        Uri.parse("$baseUrl/Manager/$overtimeId/manager-response"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "status": status,
          if (reason != null && reason.trim().isNotEmpty) "reason": reason,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        print("Manager overtime response error: ${response.body}");

        return {"success": false, "message": response.body};
      }
    } catch (e) {
      print("Error in manager overtime response: $e");

      return {"success": false, "message": e.toString()};
    }
  }

  static Future<List<dynamic>> getDepartmentOvertime() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/department"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Get department overtime error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getting department overtime: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getMyOvertime() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/Manager/my"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Get my overtime error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getting my overtime: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> createExtraWork({
    required int staffId,
    String? taskId,
    required String workType,
    required DateTime workDate,
    required double expectedHours,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final uri = Uri.parse('$baseUrl/Manager/create-compensation');

    final body = {
      'staffId': staffId,
      'taskId': taskId,
      'workType': workType,
      'workDate': _formatDateTime(workDate),
      'expectedHours': expectedHours,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> responseData = {};

    try {
      responseData = jsonDecode(response.body);
    } catch (_) {
      responseData = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    throw Exception(
      responseData['message'] ??
          'Failed to create extra work request. '
              'Status: ${response.statusCode}',
    );
  }

  static Future<List<Map<String, dynamic>>> getDepartmentExtraWork() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final uri = Uri.parse('$baseUrl/Manager/department-extra-work');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Department ExtraWork Status: ${response.statusCode}');
    print('Department ExtraWork Response: ${response.body}');

    Map<String, dynamic> responseData = {};

    try {
      responseData = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = responseData['extraWorks'];

      if (data is List) {
        return data
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      return [];
    }

    throw Exception(
      responseData['message'] ??
          'Failed to load department extra work. '
              'Status: ${response.statusCode}',
    );
  }

  static Future<List<Map<String, dynamic>>> getMyExtraWork() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Manager/my-extra-work'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('My ExtraWork Status: ${response.statusCode}');
      print('My ExtraWork Response: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item as Map),
              )
              .toList();
        }

        throw Exception('Invalid response format.');
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }

      if (response.statusCode == 404) {
        throw Exception('Extra work API endpoint not found.');
      }

      throw Exception(
        'Failed to get extra work. '
        'Status: ${response.statusCode}, '
        'Response: ${response.body}',
      );
    } catch (e) {
      print('Get My ExtraWork Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateStaffResponse({
    required int extraWorkId,
    required String status,
    String? staffRemarks,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Manager/staff-response/$extraWorkId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status, 'staffRemarks': staffRemarks}),
      );

      print('Staff Response Status: ${response.statusCode}');
      print('Staff Response Body: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(decoded);
      }

      if (response.statusCode == 400) {
        throw Exception(
          decoded is Map
              ? decoded['message'] ?? 'Invalid request.'
              : 'Invalid request.',
        );
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }

      if (response.statusCode == 404) {
        throw Exception(
          decoded is Map
              ? decoded['message'] ?? 'Extra work not found.'
              : 'Extra work not found.',
        );
      }

      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Failed to update extra work.'
            : 'Failed to update extra work.',
      );
    } catch (e) {
      print('Update Staff Response Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateManagerResponse({
    required int extraWorkId,
    required String status,
    String? managerRemarks,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/Manager/manager-response/$extraWorkId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status, 'managerRemarks': managerRemarks}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Failed to update extra work.',
    );
  }

  static String _formatDateTime(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
