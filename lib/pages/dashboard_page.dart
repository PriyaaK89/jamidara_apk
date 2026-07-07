import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import "../pages/targets/my_target_history_page.dart";

class DashboardPage extends StatefulWidget {
  final int employeeId;
  const DashboardPage({super.key, required this.employeeId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? profile;
  bool isLoadingProfile = true;

  // --- Visit target progress state ---
  Map<String, dynamic>? targetProgress; // { assignment: {...}, breakdown: [...] }
  bool isLoadingTarget = true;

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisitReminder();
      _loadProfile();
      _loadTargetProgress();
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

  /// Fetch the employee's current active target + progress
  Future<void> _loadTargetProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await ApiService.getEmployeeVisitProgress(
        token,
        widget.employeeId,
      );

      if (res["success"] == true) {
        setState(() {
          targetProgress = res["data"]; // null if no active target
          isLoadingTarget = false;
        });
      } else {
        setState(() => isLoadingTarget = false);
      }
    } catch (e) {
      debugPrint("Target progress error: $e");
      setState(() => isLoadingTarget = false);
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
                  Image.asset('assets/images/visit_remaining.png', height: 120),
                  const SizedBox(height: 12),
                  const Text(
                    "Visit Reminder",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    visits == 0
                        ? "You haven't started visits yet.\nComplete 4 visits to avoid half day."
                        : "You have completed $visits visit(s).\nComplete $remaining more to avoid half day.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 22, color: Colors.black54),
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
                colors: [primaryGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isLoadingProfile
                ? const Text("Loading...", style: TextStyle(color: Colors.white))
                : Text(
                    "Welcome Back ${profile?['name'] ?? ''} 👋\nHave a productive day",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          /// My Visit Target Card
          _buildTargetCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTargetCard() {
    if (isLoadingTarget) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: const Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (targetProgress == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flag_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "No active visit target assigned right now.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final assignment = targetProgress!["assignment"];
    final breakdown = (targetProgress!["breakdown"] as List?) ?? [];

    final byType = {for (var b in breakdown) b["visit_type"]: b};

    int totalTarget = 0;
    int totalAchieved = 0;
    for (final b in breakdown) {
      totalTarget += (b["target_value"] as num?)?.toInt() ?? 0;
      totalAchieved += (b["achieved"] as num?)?.toInt() ?? 0;
    }
    final overallPct = totalTarget == 0
        ? 0
        : ((totalAchieved / totalTarget) * 100).clamp(0, 100).round();

    // Parses a plain "YYYY-MM-DD" string manually — avoids DateTime.parse's
    // UTC interpretation shifting the day depending on device timezone.
    String formatDate(String? date) {
      if (date == null) return "-";
      final parts = date.split("-");
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
      return date;
    }

    final Map<String, IconData> typeIcons = {
      "farmer": Icons.grass,
      "retailer": Icons.storefront_outlined,
      "distributor": Icons.local_shipping_outlined,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.track_changes, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Visit Target",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${formatDate(assignment["period_start"])} - ${formatDate(assignment["period_end"])}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: ["farmer", "retailer", "distributor"].map((type) {
              final data = byType[type];
              final achieved = data?["achieved"] ?? 0;
              final target = data?["target_value"] ?? 0;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(typeIcons[type], size: 18, color: primaryGreen),
                      const SizedBox(height: 6),
                      Text(
                        "$achieved/$target",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type[0].toUpperCase() + type.substring(1),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallPct / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: overallPct >= 100 ? Colors.green : primaryGreen,
            ),
          ),

          const SizedBox(height: 10),

          /// Percent complete + history icon, same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$overallPct% complete",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyTargetHistoryPage(employeeId: widget.employeeId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}