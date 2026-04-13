import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  final int employeeId;
  const DashboardPage({super.key, required this.employeeId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
Map<String, dynamic>? profile;
bool isLoadingProfile = true;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisitReminder();
       _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final res = await ApiService.getMyProfile(token);

    if (res["success"] == true) {
      setState(() {
        profile = res["data"];
        isLoadingProfile = false;
      });
    } else {
      setState(() => isLoadingProfile = false);
    }
  } catch (e) {
    debugPrint("Profile error: $e");
    setState(() => isLoadingProfile = false);
  }
}

  ///  API Call to check today's visits
  Future<void> _checkVisitReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final visitRes = await ApiService.getTodayVisitCount(token);

      if (visitRes["success"] == true) {
        int visits = visitRes["totalVisits"] ?? visitRes["visits"] ?? 0;
        if (visits < 4) {
          await _showVisitReminderDialog(visits);
        }
      }
    } catch (e) {
      debugPrint("Dashboard visit check error: $e");
    }
  }

  ///  Dialog with Image
 Future<void> _showVisitReminderDialog(int visits) async {
  int remaining = 4 - visits;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
       backgroundColor: const Color.fromARGB(255, 249, 249, 249),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset( 'assets/images/visit_remaining.png', height: 120,),
                const SizedBox(height: 12),

                /// Title
                const Text(
                  "Visit Reminder",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// Message
                Text(
                  visits == 0
                      ? "You haven't started visits yet.\nComplete 4 visits to avoid half day."
                      : "You have completed $visits visit(s).\nComplete $remaining more to avoid half day.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 16),

                /// Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),

          /// Close Icon (Top Right)
          Positioned(
            right: 8,
            top: 8,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.close,
                size: 22,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          /// Greeting Card
         Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: isLoadingProfile
      ? const Text(
          "Loading...",
          style: TextStyle(color: Colors.white),
        )
      : Text(
          "Welcome Back ${profile?['name'] ?? ''} 👋\nHave a productive day",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
),

          const SizedBox(height: 20),

          /// Stats Cards Row 1
          Row(
            children: const [
              Expanded(child: _StatCard(title: "Visits", value: "12")),
              SizedBox(width: 10),
              Expanded(child: _StatCard(title: "Orders", value: "5")),
            ],
          ),

          const SizedBox(height: 10),

          /// Stats Cards Row 2
          Row(
            children: const [
              Expanded(child: _StatCard(title: "Sales", value: "₹25K")),
              SizedBox(width: 10),
              Expanded(child: _StatCard(title: "Expenses", value: "₹3K")),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

///  Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text( value, style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold, ), ),
          const SizedBox(height: 4),
          Text( title, style: const TextStyle(color: Colors.grey), ),
        ],
      ),
    );
  }
}