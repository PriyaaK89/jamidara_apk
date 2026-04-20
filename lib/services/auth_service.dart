import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../pages/login_page.dart';
import 'user_service.dart';

class AuthService {
  ///  MAIN LOGOUT FUNCTION
  static Future<void> logout(
    BuildContext context, {
    String message = "Session expired",
    bool clearSavedCredentials = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    try {
      //  Clear session data
      await prefs.remove('token');
      await prefs.remove('employee_id');

      //  Clear cached user (your custom service)
      UserService.clearUser();

      //  Optional: clear saved login credentials
      if (clearSavedCredentials) {
        await prefs.remove('saved_email');
        await secureStorage.delete(key: 'saved_password');
      }

      //  Stop background service (VERY IMPORTANT)
      FlutterBackgroundService().invoke("stopService");
      

    } catch (e) {
      print("Logout error: $e");
    }

    //  Navigate to login
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(message: message),
      ),
      (route) => false,
    );
  }
}