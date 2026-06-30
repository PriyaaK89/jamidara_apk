import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = "token";
  static const String _employeeIdKey = "employeeId";
  static const String _userKey = "user"; //  NEW
  static const String _jobRoleLevelKey = "job_role_level";
static const String _jobRoleNameKey = "job_role_name";

  static Future<void> saveUser(String token, int employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_employeeIdKey, employeeId);
  }

  static Future<void> saveFullUser(
    String token, int employeeId, Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(_tokenKey, token);
  await prefs.setInt(_employeeIdKey, employeeId);
  await prefs.setString(_userKey, jsonEncode(user));

  // ── NEW: save role info for quick access ──
  await prefs.setInt(_jobRoleLevelKey, user['job_role_level'] ?? 99);
  await prefs.setString(_jobRoleNameKey, user['job_role_name'] ?? '');
}

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_employeeIdKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);

    if (data == null) return null;

    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }


  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<int> getJobRoleLevel() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_jobRoleLevelKey) ?? 99;
}

static Future<String> getJobRoleName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_jobRoleNameKey) ?? '';
}
}