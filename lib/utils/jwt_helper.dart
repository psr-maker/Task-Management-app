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
}
