import 'package:flutter/foundation.dart';

class NotificationService {
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static void setUnreadCount(int count) {
    unreadCount.value = count;
  }
}
