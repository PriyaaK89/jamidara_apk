import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = "token";
  static const String _employeeIdKey = "employeeId";

  // Save data
  static Future<void> saveUser(String token, int employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_employeeIdKey, employeeId);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get employeeId
  static Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_employeeIdKey);
  }

  // Clear (logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}