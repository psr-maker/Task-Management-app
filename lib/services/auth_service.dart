import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staff_work_track/core/constant/apiurl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = ApiConstants.apiurl;
  static const String _tokenKey = "auth_token";
  static const _storage = FlutterSecureStorage();
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
      body: jsonEncode({
        "name": name,
        "email": email,
        "department": department,
        "role": role,
      }),
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

  static Future<void> updateProfile(String name, String email) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse("$baseUrl/auth/update-profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"name": name, "email": email}),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update profile");
    }
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/auth/my-profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load profile");
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

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }
    await _storage.delete(key: _tokenKey);
  }
}
