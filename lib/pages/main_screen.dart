import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'attendance_page.dart';
import 'target_page.dart';
import 'visit_page.dart';
import 'order_page.dart';
import 'profile_menu_page.dart';
import '../pages/expense_page.dart';
import '../pages/quick_action_page.dart';
import '../pages/dashboard_page.dart';

class MainScreen extends StatefulWidget {
  final int employeeId;
  final String token;
  final Function(String, String, String)? onExpenseSelect;
  final Widget? customPage;

  const MainScreen({
    super.key,
    required this.employeeId,
    required this.token,
    this.onExpenseSelect,
    this.customPage,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  String currentExpenseType = "HOTEL";
  String currentTitle = "Hotel Expense";
  String currentRemarks = "hotel stay";

  @override
  void initState() {
    super.initState();

    _pages = [
       DashboardPage(employeeId: widget.employeeId), //  FIRST PAGE
  AttendancePage(employeeId: widget.employeeId, token: widget.token),

      const VisitPage(),
      const OrderPage(),
      // const Center(child: Text("More Page", style: TextStyle(fontSize: 20))),
      QuickActionsPage(
  onTabChange: (index) {
    if (index == -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExpensePage(
  expenseType: currentExpenseType,
  title: currentTitle,
  remarks: currentRemarks,
  onBackToQuickActions: () {
    Navigator.pop(context); //  go back to QuickActionsPage
  },
),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  },

  onExpenseSelect: (type, title, remarks) {
    setState(() {
      currentExpenseType = type;
      currentTitle = title;
      currentRemarks = remarks;
    });
  },
),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openProfileMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
      builder: (_) => ProfileMenuPage(
  clearSavedCredentialsOnLogout: false,
  onTabChange: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 37, 82, 40),
            Color.fromARGB(255, 48, 110, 51),
            Color.fromARGB(255, 115, 167, 117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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

          // Right icons
          Row(
            children: [
              const SizedBox(width: 12),

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
                  child: const Icon(Icons.person, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
if (Navigator.canPop(context)) {
  return true; // let current screen handle back
}

if (_selectedIndex != 0) {
  setState(() {
    _selectedIndex = 0;
  });
  return false;
} else {
  SystemNavigator.pop();
  return false;
}
    },

    child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: Column(
        children: [
          _buildHeader(),
          // Expanded(child: _pages[_selectedIndex]),
          Expanded( child: widget.customPage ?? _pages[_selectedIndex],),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
