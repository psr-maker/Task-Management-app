import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/Models/getusers.dart';
import 'package:staff_work_track/utils/enum.dart';
import 'package:staff_work_track/services/auth_service.dart';
import 'package:staff_work_track/services/superadmin_service.dart';
import 'package:staff_work_track/utils/goal_quantity.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/core/constant/division_config.dart';

class AdminService {
  static const String baseUrl = ApiConstants.apiurl;

  static Future<List<String>> getMySubDepartments({
    String? headDepartment,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    for (final path in [
      "/Manager/my-department-access",
      "/Director/my-department-access",
    ]) {
      final response = await http.get(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 404 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        continue;
      }
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return [];
      final heads = decoded["headDepartments"] ?? decoded["HeadDepartments"];
      if (heads is! List) return [];

      final names = <String>[];
      final parent = headDepartment?.trim() ?? "";
      for (final group in heads) {
        if (group is! Map) continue;
        if (parent.isNotEmpty && !_isHeadGroup(group, parent, heads.length)) {
          continue;
        }
        final subs = group["subDepartments"] ?? group["SubDepartments"];
        if (subs is! List) continue;
        for (final sub in subs) {
          if (sub is! Map) continue;
          final name = (sub["name"] ?? sub["Name"] ?? "").toString().trim();
          if (name.isEmpty) continue;
          if (parent.isNotEmpty &&
              DivisionConfig.isAllowedDepartment(name, [parent])) {
            continue;
          }
          if (names.any((item) => DivisionConfig.isAllowedDepartment(name, [item]))) {
            continue;
          }
          names.add(name);
        }
      }
      if (names.isNotEmpty || parent.isEmpty) return names;
    }
    return [];
  }

  static bool _isHeadGroup(Map group, String headDepartment, int groupCount) {
    final headName = (group["headDepartmentName"] ??
            group["HeadDepartmentName"] ??
            group["departmentName"] ??
            group["DepartmentName"] ??
            group["name"] ??
            group["Name"] ??
            "")
        .toString()
        .trim();
    if (headName.isEmpty) return groupCount == 1;
    return DivisionConfig.isAllowedDepartment(headName, [headDepartment]);
  }

  static Future<List<String>> getDivisionHeadDepartments(
    List<UserModel> users,
  ) async {
    final token = await AuthService.getToken();
    final divisionHeads = users
        .where((user) => AppRoles.isDivisionHead(user.role))
        .toList();
    final owned = <String>[];

    void addName(String name) {
      final value = name.trim();
      if (value.isEmpty) return;
      if (owned.any(
        (item) => DivisionConfig.isAllowedDepartment(value, [item]),
      )) {
        return;
      }
      owned.add(value);
    }

    for (final head in divisionHeads) {
      addName(head.department);
    }

    final departmentNamesById = <int, String>{};
    try {
      final departments = await SuperAdminService().getDepartments();
      for (final department in departments) {
        final id = department.id;
        final name = department.departmentName.trim();
        if (id != null && name.isNotEmpty) {
          departmentNamesById[id] = name;
        }
        final parentOwned = divisionHeads.any(
          (head) => DivisionConfig.isAllowedDepartment(
            head.department,
            [department.departmentName],
          ),
        );
        if (!parentOwned) continue;
        addName(department.departmentName);
        addName(department.subDepartment ?? "");
      }
    } catch (_) {}

    if (token == null) return owned;

    final paths = [
      "/Director/department-access",
      "/Director/get-department-access",
      "/Director/my-department-access",
      "/Manager/my-department-access",
    ];

    for (final path in paths) {
      final response = await http.get(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 404 || response.statusCode != 200) continue;
      _collectDivisionDepartments(
        jsonDecode(response.body),
        divisionHeads,
        departmentNamesById,
        addName,
      );
    }

    return owned;
  }

  static void _collectDivisionDepartments(
    dynamic decoded,
    List<UserModel> divisionHeads,
    Map<int, String> departmentNamesById,
    void Function(String name) addName,
  ) {
    if (decoded is List) {
      for (final item in decoded) {
        _collectDivisionDepartments(
          item,
          divisionHeads,
          departmentNamesById,
          addName,
        );
      }
      return;
    }
    if (decoded is! Map) return;

    final nested =
        decoded["headDepartments"] ??
        decoded["HeadDepartments"] ??
        decoded["departmentAccess"] ??
        decoded["DepartmentAccess"] ??
        decoded["data"] ??
        decoded["Data"];
    if (nested is List) {
      for (final item in nested) {
        _collectDivisionDepartments(
          item,
          divisionHeads,
          departmentNamesById,
          addName,
        );
      }
    }

    void addDepartmentId(dynamic rawId) {
      final id = int.tryParse("${rawId ?? ""}");
      if (id == null || id <= 0) return;
      addName(departmentNamesById[id] ?? "");
    }

    final role = (decoded["role"] ??
            decoded["Role"] ??
            decoded["roleId"] ??
            decoded["RoleId"] ??
            "")
        .toString();
    final userId = int.tryParse(
      "${decoded["userId"] ?? decoded["UserId"] ?? ""}",
    );
    final headName = (decoded["headDepartmentName"] ??
            decoded["HeadDepartmentName"] ??
            decoded["headName"] ??
            decoded["name"] ??
            decoded["Name"] ??
            decoded["departmentName"] ??
            decoded["DepartmentName"] ??
            "")
        .toString();
    final isDivisionGroup = AppRoles.isDivisionHead(role) ||
        (userId != null &&
            divisionHeads.any((head) => head.userId == userId)) ||
        divisionHeads.any(
          (head) => DivisionConfig.isAllowedDepartment(head.department, [
            headName,
          ]),
        );
    if (!isDivisionGroup) return;

    addDepartmentId(decoded["subDepartmentId"] ?? decoded["SubDepartmentId"]);
    addName(headName);
    final subName = (decoded["subDepartmentName"] ??
            decoded["SubDepartmentName"] ??
            decoded["subDepartment"] ??
            decoded["SubDepartment"] ??
            "")
        .toString();
    addName(subName);

    final subs = decoded["subDepartments"] ?? decoded["SubDepartments"];
    if (subs is List) {
      for (final sub in subs) {
        if (sub is Map) {
          addName((sub["name"] ?? sub["Name"] ?? sub["departmentName"] ?? "")
              .toString());
        } else {
          addName(sub.toString());
        }
      }
    }
  }

  static Future<List<UserModel>> getEmployeesByDepartment(
    String department,
  ) async {
    final token = await AuthService.getToken();
    final encodedDepartment = Uri.encodeComponent(department.trim());
    final response = await http.get(
      Uri.parse('$baseUrl/Manager/staffbydept/$encodedDepartment'),
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final raw = data is Map
          ? (data['employees'] ??
              data['Employees'] ??
              data['users'] ??
              data['Users'] ??
              data['staff'] ??
              data['Staff'] ??
              data['data'] ??
              data['Data'] ??
              [])
          : data;
      final List employeesJson = raw is List ? raw : [];
      return employeesJson
          .whereType<Map>()
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      throw Exception("Failed to load employees");
    }
  }

  static Future<List<UserModel>> getEmployeesByDepartments(
    List<String> departments,
  ) async {
    if (departments.isEmpty) return [];

    final results = await Future.wait(
      departments.map((department) async {
        try {
          return await getEmployeesByDepartment(department);
        } catch (_) {
          return <UserModel>[];
        }
      }),
    );

    final uniqueUsers = <int, UserModel>{};
    for (final list in results) {
      for (final user in list) {
        uniqueUsers[user.userId] = user;
      }
    }
    return uniqueUsers.values.toList();
  }

  static Future<List<dynamic>> getGoalsByDepartment(String department) async {
    try {
      final token = await AuthService.getToken();
      final encoded = Uri.encodeComponent(department.trim());
      final url = Uri.parse("$baseUrl/Manager/allStaffGoals/$encoded");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        return data["goals"] ?? data["data"] ?? [];
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
      final decoded = json.decode(response.body);
      final list = decoded is List
          ? decoded
          : (decoded["result"] ?? decoded["tasks"] ?? decoded["data"] ?? []);
      final tasks = List<Map<String, dynamic>>.from(list);
      for (final task in tasks) {
        if (memberUserStatus(task, adminId) != null) continue;
        final code = (task["taskCode"] ?? task["TaskCode"] ?? "").toString();
        if (code.isEmpty) continue;
        try {
          final details = await SuperAdminService.getTaskByCode(code);
          final people = details["assignedTo"] ?? details["AssignedTo"];
          if (people is List) task["assignedTo"] = people;
          final splits = details["quantitySplits"] ?? details["QuantitySplits"];
          if (splits is List) task["quantitySplits"] = splits;
        } catch (_) {}
      }
      return tasks;
    } else {
      throw Exception("Failed to load admin tasks");
    }
  }

  static Future<void> updateTaskStatus({
    required String taskCode,
    required TaskStatus status,
    int? achievedQuantity,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("User not logged in");

    final response = await http.put(
      Uri.parse("$baseUrl/Manager/update-task-status"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "taskCode": taskCode,
        "status": status.name,
        if (achievedQuantity != null) "completedQuantity": achievedQuantity,
      }),
    );

    if (response.statusCode != 200) {
      var message = "Status update failed";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded["message"] != null) {
          message = decoded["message"].toString();
        } else if (decoded is String && decoded.trim().isNotEmpty) {
          message = decoded;
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<List<dynamic>> getTasksByDepartment(String department) async {
    final encoded = Uri.encodeComponent(department.trim());
    final url = Uri.parse("$baseUrl/Manager/allStafftask/$encoded");

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
    required int staffId,
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/Manager/review-task"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "taskCode": taskCode,
        "staffId": staffId, // ⭐ MISSING IN YOUR CODE
        "managerPoints": managerPoints,
        "isDelayJustified": isDelayJustified,
        "delayReason": delayReason,
        "comment": comment,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        response.body.isNotEmpty ? response.body : "Failed to submit review",
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getReview(String taskCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Manager/getreview/$taskCode'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return List<Map<String, dynamic>>.from(
          decoded.map((item) => Map<String, dynamic>.from(item)),
        );
      }

      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception("Failed to fetch review: ${response.statusCode}");
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
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return decoded['goals'] ??
              decoded['data'] ??
              decoded['result'] ??
              decoded['Goals'] ??
              [];
        }
        return [];
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
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/Manager/apply-leave"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
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

  static List<dynamic> _decodeList(String body) {
    final data = jsonDecode(body);
    if (data is List) return data;
    if (data is Map) {
      final list =
          data["data"] ??
          data["leaves"] ??
          data["permissions"] ??
          data["result"] ??
          data["items"];
      if (list is List) return list;
    }
    return [];
  }

  static Future<List<dynamic>> _getFirstSuccessfulList(
    List<String> paths,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token not found");

    http.Response? last;
    for (final path in paths) {
      final response = await http.get(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      last = response;
      if (response.statusCode == 200) {
        return _decodeList(response.body);
      }
      if (response.statusCode != 404) {
        throw Exception("Failed to load: ${response.body}");
      }
    }
    throw Exception("Failed to load: ${last?.body ?? "no response"}");
  }

  static Future<bool> _postFirstSuccessful(
    List<String> paths,
  ) async {
    final token = await AuthService.getToken();
    http.Response? last;
    for (final path in paths) {
      final response = await http.post(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      last = response;
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
      if (response.statusCode == 200) return true;
      if (response.statusCode != 404) return false;
    }
    print("STATUS: ${last?.statusCode}");
    print("BODY: ${last?.body}");
    return false;
  }

  static Future<bool> updateLeaveStatus({
    required int id,
    required String status,
    String? reason,
    bool asDirector = false,
  }) async {
    try {
      final encodedReason = Uri.encodeQueryComponent(reason ?? "");
      final query =
          "id=$id&status=$status&reason=$encodedReason";
      final paths = asDirector
          ? [
              "/Director/update-leave-status?$query",
              "/Manager/update-leave-status?$query",
            ]
          : ["/Manager/update-leave-status?$query"];
      return await _postFirstSuccessful(paths);
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<List<dynamic>> getDirectorLeaves() {
    return _getFirstSuccessfulList([
      "/Director/get-leaves",
      "/Director/get-department-leaves",
    ]);
  }

  static Future<List<dynamic>> getDirectorPermissions() {
    return _getFirstSuccessfulList([
      "/Director/get-permissions",
      "/Director/get-department-permissions",
    ]);
  }

  static Future<Map<String, dynamic>?> applyPermission({
    required String name,
    required String designation,
    required String reason,
    required DateTime date,
    required String fromTime,
    required String toTime,
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

      print("======================================");
      print("PERMISSION API");
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("======================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("APPLICATION TYPE: ${data["applicationType"]}");

        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e, stackTrace) {
      print("PERMISSION EXCEPTION: $e");
      print(stackTrace);
      return null;
    }
  }

  static Future<bool> updatePermissionStatus({
    required int id,
    required String status,
    bool asDirector = false,
  }) async {
    try {
      final query = "id=$id&status=$status";
      final paths = asDirector
          ? [
              "/Director/update-permission-status?$query",
              "/Manager/update-permission-status?$query",
            ]
          : ["/Manager/update-permission-status?$query"];
      return await _postFirstSuccessful(paths);
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

  static Map<String, dynamic> _normalizePermission(Map raw) {
    final item = Map<String, dynamic>.from(raw);
    item["id"] ??= item["Id"];
    item["senderId"] ??= item["SenderId"];
    item["receiverId"] ??= item["ReceiverId"];
    item["name"] ??= item["Name"];
    item["designation"] ??= item["Designation"];
    item["reason"] ??= item["Reason"];
    item["date"] ??= item["Date"] ?? item["fromDate"] ?? item["FromDate"];
    item["fromTime"] ??= item["FromTime"];
    item["toTime"] ??= item["ToTime"];
    item["totalHours"] ??= item["TotalHours"] ?? item["totalhours"];
    item["status"] ??= item["Status"];
    item["submittedDate"] ??= item["SubmittedDate"];
    item["department"] ??=
        item["senderDepartment"] ??
        item["SenderDepartment"] ??
        item["dept"] ??
        item["departmentName"];
    return item;
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
        return _decodeList(response.body)
            .whereType<Map>()
            .map(_normalizePermission)
            .toList();
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
        return _decodeList(response.body)
            .whereType<Map>()
            .map(_normalizePermission)
            .toList();
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
        return _decodeList(response.body);
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
    bool asDirector = false,
  }) async {
    try {
      final body = jsonEncode({
        "staffId": staffId,
        "communication": communication,
        "punctuality": punctuality,
        "integrity": integrity,
        "date": date.toIso8601String(),
      });

      if (!asDirector) {
        final response = await http.post(
          Uri.parse('$baseUrl/Manager/add-attitude-behaviour-score'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        }

        print(
          "Add Attitude Behaviour Score Error: "
          "${response.statusCode} - ${response.body}",
        );
        return false;
      }

      final token = await AuthService.getToken();
      final paths = [
        "/Director/add-attitude-behaviour-score",
        "/Manager/add-attitude-behaviour-score",
      ];

      http.Response? last;
      for (final path in paths) {
        final response = await http.post(
          Uri.parse("$baseUrl$path"),
          headers: {
            "Content-Type": "application/json",
            if (token != null && token.isNotEmpty)
              "Authorization": "Bearer $token",
          },
          body: body,
        );
        last = response;
        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        }
        if (response.statusCode != 404) break;
      }

      print(
        "Add Attitude Behaviour Score Error: "
        "${last?.statusCode} - ${last?.body}",
      );
      return false;
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

  static List<Map<String, dynamic>> _parseAttitudeScores(String body) {
    final decoded = jsonDecode(body);
    final dynamic raw = decoded is List
        ? decoded
        : decoded is Map
        ? decoded["scores"] ??
              decoded["Scores"] ??
              decoded["data"] ??
              decoded["result"]
        : null;
    final List scores = raw is List ? raw : [];

    return scores
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>>
  getDirectorAttitudeBehaviourScores() async {
    final token = await AuthService.getToken();
    final paths = [
      "/Director/attitude-behaviour-scores",
      "/Director/department-attitude-behaviour-scores",
      "/Manager/department-attitude-behaviour-scores",
    ];

    http.Response? last;
    for (final path in paths) {
      final response = await http.get(
        Uri.parse("$baseUrl$path"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );
      last = response;
      if (response.statusCode == 200) {
        return _parseAttitudeScores(response.body);
      }
      if (response.statusCode == 404 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        continue;
      }
    }

    throw Exception(
      "Failed to load attitude & behaviour scores: ${last?.body ?? ""}",
    );
  }
}
