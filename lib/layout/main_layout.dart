import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/profile_menu_page.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTabChange;
  final String currentRoute;
  final bool isOrderSubPageOpen;
  final VoidCallback? onCloseOrderSubPage;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabChange,
    required this.currentRoute,
    required this.isOrderSubPageOpen,
    this.onCloseOrderSubPage,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // late VoidCallback _logoutListener;

  @override
  void initState() {
    super.initState();
    FlutterBackgroundService().on("forceLogout").listen((event) {
      print(" Force logout received in UI");
      AuthService.logout(context);
    });
    _loadUserProfile();
  }

  @override
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
          // Company Name
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

                  return InkWell(
                    onTap: _openProfileMenu,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildInitialAvatar(name);
                                },
                              )
                            : _buildInitialAvatar(name),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {

if (widget.isOrderSubPageOpen) {
  widget.onCloseOrderSubPage?.call();
  return false;
}

        //  Expense Page → Quick Actions
        if (widget.currentRoute == "expense") {
          widget.onTabChange(4);
          return false;
        }
        if (widget.currentRoute == "my_team") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfileMenuPage(clearSavedCredentialsOnLogout: false),
            ),
          );

          return false;
        }

        if (widget.currentRoute == "visit_report") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfileMenuPage(clearSavedCredentialsOnLogout: false),
            ),
          );
          return false;
        }

        if (widget.currentRoute == "attendance_report") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfileMenuPage(clearSavedCredentialsOnLogout: false),
            ),
          );
          return false;
        }

        if (widget.currentRoute == "salary_report") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfileMenuPage(clearSavedCredentialsOnLogout: false),
            ),
          );
          return false;
        }

        if (widget.currentIndex != 0) {
          widget.onTabChange(0);
          return false;
        } else {
          SystemNavigator.pop();
          return false;
        }
      },
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
