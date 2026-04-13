import 'package:flutter/foundation.dart';

class UserService {
  //  Reactive user data (auto updates UI)
  static ValueNotifier<Map<String, dynamic>?> currentUser =
      ValueNotifier<Map<String, dynamic>?>(null);

  //  Set user data
  static void setUser(Map<String, dynamic> user) {
    currentUser.value = user;
  }

  //  Clear user (logout)
  static void clearUser() {
    currentUser.value = null;
  }

  //  Get user (shortcut)
  static Map<String, dynamic>? get user => currentUser.value;
}