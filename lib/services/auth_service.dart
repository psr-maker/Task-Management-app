import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_work_track/core/constant/apiurl.dart';

class AuthService {
  static const String baseUrl = ApiConstants.apiurl;
  static const String _tokenKey = "auth_token";

  // SEND OTP

  Future<int> sendOtp(String identifier) async {
    final url = Uri.parse("$baseUrl/auth/send-otp");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(identifier),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["attempts"];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Error sending OTP");
    }
  }

  // VERIFY OTP

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse("$baseUrl/auth/verify-otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"EmailorName": email, "Otp": otp}),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    } else {
      throw Exception(decoded["message"]);
    }
  }

  /// CREATE USER

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
     required String department,
    required String role,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("User not logged in");

    final url = Uri.parse("$baseUrl/auth/create-user");
    print("JWT token: $token");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"name": name, "email": email, "department":department,"role": role}),
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: '${response.body}'");

    if (response.body.isEmpty) {
      throw Exception(
        "Server returned empty response. Status code: ${response.statusCode}",
      );
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    } else {
      throw Exception(decoded["message"] ?? "Failed to create user");
    }
  }

  static Future<String?> checkEmailRole(String email) async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/check-email-role?email=$email"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["exists"] == true) {
        return data["role"];
      }
      return null;
    } else {
      throw Exception("Email check failed");
    }
  }

  /// SAVE TOKEN
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// GET TOKEN (USED IN SPLASH)
 static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// LOGOUT
  // static Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(_tokenKey);
  // }

  static Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token != null) {
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
}
