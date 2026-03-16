import 'package:flutter/material.dart';
import '../pages/welcome_page.dart';
import '../pages/attendance_page.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String attendance = '/attendance';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => WelcomePage());

      case attendance:
  final args = settings.arguments as Map<String, dynamic>;

  final int employeeId = args['employeeId'];
  final String token = args['token'];

  return MaterialPageRoute(
    builder: (_) => AttendancePage(
      employeeId: employeeId,
      token: token,
    ),
  );
        

        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
