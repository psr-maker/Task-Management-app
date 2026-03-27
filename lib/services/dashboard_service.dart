import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';

class DashboardService {

  static const String baseUrl = ApiConstants.apiurl;


  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse("$baseUrl/Dashboard/dashboard-summary"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load dashboard data");
    }
  }

  static Future<List<Map<String, dynamic>>> allgetDepartmentsProductivity({
    required int year,
    int? month,
    int? quarter,
  }) async {
    try {
      // Build query params
      final queryParams = <String, String>{'year': year.toString()};
      if (month != null) queryParams['month'] = month.toString();
      if (quarter != null) queryParams['quarter'] = quarter.toString();

      final uri = Uri.parse('$baseUrl/Dashboard/all-departments-productivity')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load productivity');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

 static Future<Map<String, dynamic>> fetchmanagerDepartment(
    String department, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final uri = Uri.parse(
      '$baseUrl/Dashboard/Manager-dashboard/$department',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri);
 
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load department report");
    }
  }

//  static Future<List<dynamic>> getDepartmentSummary() async {
//    final response = await http.get(
//       Uri.parse("$baseUrl/Dashboard/department-summary"),
//       headers: {
//         "Content-Type": "application/json",
//       },
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data["data"];
//     } else {
//       throw Exception("Failed to load department summary");
//     }
//   }
   /// get pending users
  
  static Future<List<UserModel>> getPendingUsers() async {
    final response = await http.get(
      Uri.parse("$baseUrl/Dashboard/pending-users"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load users");
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    final List list = json['pendingUsers'] ?? [];

    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  // approve users

  static Future<void> approveUser(int userId, bool approve) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Dashboard/approve-user"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "approve": approve}),
    );

    if (response.statusCode != 200) {
      throw Exception("Approval failed");
    }
  }

}
