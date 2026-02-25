import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:staff_work_track/Models/table.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';

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
    final response = await http.get(
      Uri.parse("$baseUrl/Reports/GetAllDepartments"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['data']);
    } else {
      throw Exception("Failed to load departments");
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

  static Future<Map<String, dynamic>> getEmployeeReport(int employeeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/Reports/Staff/$employeeId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load employee report");
    }
  }


   Future<List<ReportTask>> getFilteredTasks({
    int? userId,
    String? department,
  }) async {
    String url = "$baseUrl/Reports/FilteredTasks";

    final queryParams = {
      if (userId != null) "userId": userId.toString(),
      if (department != null) "department": department,
    };

    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body);

  final List data =
      decoded is List ? decoded : decoded['data'];

  print("Decoded list length: ${data.length}");

  return data.map((e) => ReportTask.fromJson(e)).toList();
} else {
      throw Exception("Failed to load tasks");
    }
  }
}
