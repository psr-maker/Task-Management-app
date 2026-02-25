import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/Models/announcement.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:staff_work_track/services/auth_service.dart';

class AnnouncementService {
  static const String baseUrl = ApiConstants.apiurl;

 static Future<List<Announcement>> fetchAnnouncements() async {
 final token = await AuthService.getToken();
      if (token == null) throw Exception("User not logged in");
      print("JWT token: $token");
  final url = Uri.parse("$baseUrl/Announcement/GetAnouncements");

  final response = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Announcement.fromJson(e)).toList();
  } else if (response.statusCode == 401) {
    throw Exception("Unauthorized - Token expired");
  } else {
    throw Exception("Failed to load announcements");
  }
}

   static Future<bool> postAnnouncement({
  required String title,
  required String description,
  required String targetRole,
  required String createdBy,
  File? file,
}) async {

  var uri = Uri.parse("$baseUrl/Announcement/Uploadanounce");

  var request = http.MultipartRequest("POST", uri);

  request.fields["title"] = title;
  request.fields["description"] = description;
  request.fields["targetRole"] = targetRole;
  request.fields["createdBy"] = createdBy;

  if (file != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        file.path,
      ),
    );
  }

  var response = await request.send();

  return response.statusCode == 200;
}
}