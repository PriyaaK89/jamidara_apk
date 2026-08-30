 import 'package:flutter/material.dart';
import 'main_layout.dart';
import '../pages/dashboard_page.dart';
import '../pages/attendance_page.dart';
import '../pages/visit_page.dart';
import '../pages/EmpProfile/visit_report_page.dart';
import '../pages/order_page.dart';
import "../pages/expense_page.dart";
import '../pages/quick_action_page.dart';
import '../pages/EmpProfile/attendance_report_page.dart';
import '../pages/EmpProfile/salary_report_page.dart';
import '../pages/EmpProfile/distributor_onbording_page.dart';
import '../pages/profile_page.dart';
import '../pages/my_team_page.dart';
import "../pages/EmpProfile/team_attendance_report.dart";
import "../pages/EmpProfile/team_visit_report_page.dart";
import "../services/storage_service.dart";
import '../pages/EmpProfile/team_menu_page.dart';

class AppRouter extends StatefulWidget {
  final int employeeId;
  final String token;
  final String initialRoute;

  /// True ONLY for the very first AppRouter created right after login.
  /// Every AppRouter reached via Navigator.push(...) from inside the app
  /// (Team menu, My Team, Profile tiles, etc.) must pass isRoot: false
  /// (the default) so its back button just pops the route instead of
  /// switching tabs or closing the app.
  final bool isRoot;

  const AppRouter({
    super.key,
    required this.employeeId,
    required this.token,
    this.initialRoute = "dashboard",
    this.isRoot = false,
  });

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int currentIndex = 0;
  String currentRoute = "dashboard";
  Widget? customOrderPage;

  int _myLevel = 1;

  @override
  void initState() {
    super.initState();
    currentRoute = widget.initialRoute;
    currentIndex = _indexForRoute(currentRoute);
    _loadLevel();
  }

  // Central place mapping every route to a bottom-nav index.
  // Anything not on the 5 main tabs falls under the "More" tab (index 4)
  // so the correct bottom-nav icon stays highlighted.
  int _indexForRoute(String route) {
    switch (route) {
      case "dashboard":
        return 0;
      case "attendance":
        return 1;
      case "visit":
        return 2;
      case "order":
        return 3;
      case "my_team":
      case "quick_actions":
      case "profile_page":
      case "team_menu":
      case "team_attendance_report":
      case "team_visit_report":
      case "visit_report":
      case "salary_report":
      case "distributor_onboarding":
      case "attendance_report":
      case "expense":
        return 4;
      default:
        return 0;
    }
  }

  Future<void> _loadLevel() async {
    final level = await StorageService.getJobRoleLevel();
    if (mounted) {
      setState(() => _myLevel = level);
    }
  }

  String currentExpenseType = "HOTEL";
  String currentTitle = "Hotel Expense";
  String currentRemarks = "hotel stay";

  Widget getCurrentPage() {
    switch (currentRoute) {
      case "dashboard":
        return DashboardPage(employeeId: widget.employeeId);

      case "attendance":
        return AttendancePage(
          employeeId: widget.employeeId,
          token: widget.token,
        );

      case "profile_page":
        return const ProfilePage();

      case "visit":
        return const VisitPage();

      case "visit_report":
        return const VisitReportPage();

      case "salary_report":
        return const SalaryReportPage();

      case "team_attendance_report":
        return TeamAttendancePage(myLevel: _myLevel);

      case "team_visit_report":
        return TeamVisitReportPage(myLevel: _myLevel);

      case "order":
        return customOrderPage ??
            OrderPage(
              onOpenPage: (page) {
                setState(() {
                  customOrderPage = page;
                });
              },
            );

      case "my_team":
        return const MyTeamPage();

      case "team_menu":
        return const TeamMenuPage();

      case "distributor_onboarding":
        return const DistributorOnboardingPage();

      case "quick_actions":
        return QuickActionsPage(
          onTabChange: (index) {
            if (index == -1) {
              navigate("expense");
            } else if (index == -2) {
              navigate("distributor_onboarding");
            } else {
              onTabChange(index);
            }
          },
          onExpenseSelect: (type, title, remarks) {
            setState(() {
              currentExpenseType = type;
              currentTitle = title;
              currentRemarks = remarks;
            });
          },
        );

      case "expense":
        return ExpensePage(
          expenseType: currentExpenseType,
          title: currentTitle,
          remarks: currentRemarks,
          onBackToQuickActions: () {
            setState(() {
              currentRoute = "quick_actions";
              currentIndex = 4;
            });
          },
        );

      case "attendance_report":
        return const AttendanceReportPage();

      default:
        return DashboardPage(employeeId: widget.employeeId);
    }
  }

  void onTabChange(int index) {
    setState(() {
      currentIndex = index;
      customOrderPage = null;

      switch (index) {
        case 0:
          currentRoute = "dashboard";
          break;
        case 1:
          currentRoute = "attendance";
          break;
        case 2:
          currentRoute = "visit";
          break;
        case 3:
          currentRoute = "order";
          break;
        case 4:
          currentRoute = "quick_actions";
          break;
        default:
          currentRoute = "dashboard";
      }
    });
  }

  void navigate(String route) {
    setState(() {
      currentRoute = route;
      currentIndex = _indexForRoute(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      isRoot: widget.isRoot,
      currentIndex: currentIndex,
      currentRoute: currentRoute,
      onTabChange: onTabChange,
      child: getCurrentPage(),
      isOrderSubPageOpen: customOrderPage != null,
      onCloseOrderSubPage: () {
        setState(() {
          customOrderPage = null;
        });
      },
      onExpenseBack: () {
        setState(() {
          currentRoute = "quick_actions";
          currentIndex = 4;
        });
      },
    );
  }
}