import 'package:jwt_decode/jwt_decode.dart';

class JwtHelper {
  static bool isExpired(String token) {
    return Jwt.isExpired(token);
  }

  static String? getRole(String token) {
    final decoded = Jwt.parseJwt(token);
    return decoded["Role"];
  }
  static String? getuid(String token) {
    final decoded = Jwt.parseJwt(token);
    return decoded["UserId"];
  }

  static String? getDepartment(String token) {
    final decoded = Jwt.parseJwt(token);
    return decoded["Department"];
  }

  static String displayName(String token) {
    final decoded = Jwt.parseJwt(token);
    final raw = decoded['unique_name'] ??
        decoded['name'] ??
        decoded['Name'] ??
        decoded['given_name'] ??
        decoded['email'] ??
        decoded['Email'];
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return 'there';
    if (value.contains('@')) {
      return value.split('@').first;
    }
    return value;
  }

  static String greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
