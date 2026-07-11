import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/profile_menu_page.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/notify_service.dart';
import '../widgets/notification_modal.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTabChange;
  final String currentRoute;
  final bool isOrderSubPageOpen;
  final VoidCallback? onCloseOrderSubPage;

  /// Called when back is pressed while on the "expense" route, so the
  /// AppRouter can drop back to "quick_actions" without popping the page.
  final VoidCallback? onExpenseBack;

  /// True only for the very first AppRouter (right after login).
  /// Controls what happens when the user is on tab 0 ("dashboard")
  /// and presses back: root closes the app, non-root just pops the route.
  final bool isRoot;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabChange,
    required this.currentRoute,
    required this.isOrderSubPageOpen,
    this.onCloseOrderSubPage,
    this.onExpenseBack,
    this.isRoot = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {

    @override
  void initState() {
    super.initState();
    FlutterBackgroundService().on("forceLogout").listen((event) {
      print(" Force logout received in UI");
      AuthService.logout(context);
    });
    _loadUserProfile();
    _loadNotificationCount();
  }

   Future<void> _loadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      if (token.isEmpty) return;

      final res = await ApiService.getNotificationCounts(token);
      debugPrint("Notification counts response: $res");

      if (res["success"] == true) {
        // final List rows = res["data"] ?? [];
        final List rawRows = res["data"] ?? [];
        final groups = rawRows.map((e) => NotificationCountGroup.fromJson(Map<String, dynamic>.from(e))).toList();
       final total = groups.fold<int>(0, (sum, g) => sum + g.total);
        NotificationService.setUnreadCount(total);

      }
    } catch (e) {
      debugPrint("Notification count load error: $e");
    }
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationModal(),
    ).then((_) => _loadNotificationCount()); // refresh badge after closing
  }
  

  @override
  void dispose() {
    super.dispose();
  }

  void _openProfileMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileMenuPage(clearSavedCredentialsOnLogout: false),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '',
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      if (UserService.user != null) return;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      if (token.isEmpty) return;
      final res = await ApiService.getMyProfile(token);
      if (res["success"] == true) {
        UserService.setUser(res["data"]);
      } else {
        debugPrint("Profile API failed");
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF255228), Color(0xFF306E33), Color(0xFF73A775)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Jamidara Seeds",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Corporation",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: _openNotifications,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: ValueListenableBuilder<int>(
                    valueListenable: NotificationService.unreadCount,
                    builder: (context, count, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications, color: Colors.white, size: 26),
                          if (count > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  count > 99 ? "99+" : "$count",
                                  style: const TextStyle(color: Colors.white, fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openProfileMenu,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 254, 255, 255),
                    shape: BoxShape.circle,
                  ),
                  child: ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: UserService.currentUser,
                    builder: (context, user, _) {
                      final imageUrl = user?['profile_image_url'];
                      final name = user?['name'] ?? '';

                      return ClipOval(
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildInitialAvatar(name);
                                },
                              )
                            : _buildInitialAvatar(name),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handles the hardware/gesture back button.
  /// Returns true to let the pop actually happen, false to swallow it.
  Future<bool> _handleWillPop() async {
    // 1. Close an open order sub-page first, regardless of root or not.
    if (widget.isOrderSubPageOpen) {
      widget.onCloseOrderSubPage?.call();
      return false;
    }

    // 2. "expense" is an internal state within THIS SAME AppRouter instance
    //    (not a separate pushed route), so back should just drop to
    //    quick_actions instead of popping the whole page.
    if (widget.currentRoute == "expense") {
      widget.onExpenseBack?.call();
      return false;
    }

    // 3. If the user switched tabs within this instance (currentIndex != 0),
    //    first back press returns to the Dashboard tab of THIS instance.
    if (widget.currentIndex != 0) {
      widget.onTabChange(0);
      return false;
    }

    if (widget.isRoot) {
      SystemNavigator.pop();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 241, 245, 243),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: widget.child),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: widget.currentIndex,
          onTap: widget.onTabChange,
          selectedItemColor: const Color(0xFF1B5E20),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint),
              label: "Attendance",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: "Visit",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: "Order",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: "More",
            ),
          ],
        ),
      ),
    );
  }
}