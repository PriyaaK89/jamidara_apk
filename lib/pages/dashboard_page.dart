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

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? profile;
  bool isLoadingProfile = true;

  // --- Visit target progress state ---
  Map<String, dynamic>? targetProgress; // { assignment: {...}, breakdown: [...] }
  bool isLoadingTarget = true;

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  // ================= ENTRANCE ANIMATION (UI ONLY) =================
  late final AnimationController _entranceController;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _targetFade;
  late final Animation<Offset> _targetSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _greetingFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _greetingSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _targetFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _targetSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _checkVisitReminder();
      _loadProfile();
      _loadTargetProgress();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
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
    debugPrint('DashboardPage employeeId = ${widget.employeeId}');
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
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 12,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryGreen.withOpacity(0.08),
                          primaryGreen.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Image.asset(
                        'assets/images/visit_remaining.png',
                        height: 120),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Visit Reminder",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    visits == 0
                        ? "You haven't started visits yet.\nComplete 4 visits to avoid half day."
                        : "You have completed $visits visit(s).\nComplete $remaining more to avoid half day.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        elevation: 4,
                        shadowColor: primaryGreen.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: Colors.black54),
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
          SlideTransition(
            position: _greetingSlide,
            child: FadeTransition(
              opacity: _greetingFade,
              child: _buildGreetingCard(),
            ),
          ),

          const SizedBox(height: 20),

          /// My Visit Target Card
          SlideTransition(
            position: _targetSlide,
            child: FadeTransition(
              opacity: _targetFade,
              child: _buildTargetCard(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGreetingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryGreen, Color.fromARGB(255, 95, 168, 98)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative soft glow circle for a bit of depth
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isLoadingProfile
                      ? _buildGreetingPlaceholder()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back ${profile?['name'] ?? ''} 👋",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Have a productive day",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Lightweight shimmer-style placeholder shown while the profile loads.
  Widget _buildGreetingPlaceholder() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      onEnd: () {}, // visual only; underlying load state is unaffected
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
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
        child: const Center(
          child: SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(
              color: primaryGreen,
              strokeWidth: 3,
            ),
          ),
        ),
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
                child: const Icon(Icons.track_changes,
                    color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Visit Target",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${formatDate(assignment["period_start"])} - ${formatDate(assignment["period_end"])}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (overallPct >= 100)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 13, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "Done",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
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
              final done = target > 0 && achieved >= target;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: done
                        ? accentGreen.withOpacity(0.12)
                        : const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(12),
                    border: done
                        ? Border.all(
                            color: accentGreen.withOpacity(0.4), width: 1)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(typeIcons[type], size: 18, color: primaryGreen),
                      const SizedBox(height: 6),
                      Text(
                        "$achieved/$target",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type[0].toUpperCase() + type.substring(1),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Progress bar animates smoothly to the current value instead of
          // snapping in place.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: overallPct / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: overallPct >= 100 ? Colors.green : primaryGreen,
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          /// Percent complete + history icon, same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: overallPct),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    "$value% complete",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyTargetHistoryPage(employeeId: widget.employeeId),
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