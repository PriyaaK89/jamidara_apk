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

class AppRouter extends StatefulWidget {
  final int employeeId;
  final String token;
  final String initialRoute;

  const AppRouter({
    super.key,
    required this.employeeId,
    required this.token,
    this.initialRoute = "dashboard",
  });

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int currentIndex = 0;
  String currentRoute = "dashboard";

  @override
  void initState() {
    super.initState();
    currentRoute = widget.initialRoute;

    //  Sync tab index
    switch (currentRoute) {
      case "dashboard":
        currentIndex = 0;
        break;
      case "attendance":
        currentIndex = 1;
        break;
      case "visit":
        currentIndex = 2;
        break;
      case "order":
        currentIndex = 3;
        break;
      case "quick_actions":
        currentIndex = 4;
        break;
      default:
        currentIndex = 0;
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

      case "visit":
        return const VisitPage();

      case "visit_report":
        return const VisitReportPage();

      case "salary_report":
        return const SalaryReportPage();

      case "order":
        return const OrderPage();

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
              currentIndex = 4; //  VERY IMPORTANT
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
          currentRoute = "quick_actions"; // IMPORTANT
          break;
      }
    });
  }

  void navigate(String route) {
    setState(() {
      currentRoute = route;
    });
  }

  String getRouteFromIndex(int index) {
    switch (index) {
      case 0:
        return "dashboard";
      case 1:
        return "attendance";
      case 2:
        return "visit";
      case 3:
        return "order";
      case 4:
        return "quick_actions";
      default:
        return "dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: currentIndex,
      currentRoute: currentRoute,
      onTabChange: onTabChange,
      child: getCurrentPage(),
    );
  }
}