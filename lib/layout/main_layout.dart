import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/profile_menu_page.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTabChange;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabChange,
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {

  void _openProfileMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileMenuPage(
          clearSavedCredentialsOnLogout: false,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF255228),
            Color(0xFF306E33),
            Color(0xFF73A775),
          ],
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          // Profile Icon
          InkWell(
            onTap: _openProfileMenu,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF1B5E20),
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
  //  Expense Page → Quick Actions
  if (widget.currentRoute == "expense") {
    widget.onTabChange(4);
    return false;
  }

  //  Visit Report → Profile Menu
  if (widget.currentRoute == "visit_report") {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileMenuPage(
          clearSavedCredentialsOnLogout: false,
        ),
      ),
    );
    return false;
  }

  if (widget.currentRoute == "attendance_report") {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ProfileMenuPage(
        clearSavedCredentialsOnLogout: false,
      ),
    ),
  );
  return false;
}

if (widget.currentRoute == "salary_report") {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ProfileMenuPage(
        clearSavedCredentialsOnLogout: false,
      ),
    ),
  );
  return false;
}

  //  Default tab behavior
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