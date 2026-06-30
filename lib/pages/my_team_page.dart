import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({super.key});

  @override
  State<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  bool isLoading = true;

  Map<String, dynamic>? currentUser;

  List managers = [];

  List team = [];

  // ── theme palette ──
  static const Color _kPrimaryGreen = Color(0xFF2E7D32);
  static const Color _kDarkGreen = Color(0xFF1B5E20);
  static const Color _kBg = Color(0xFFF4F6F5);
  static const Color _kCard = Colors.white;
  static const Color _kInk = Color(0xFF1A1A1A);
  static const Color _kBorder = Color(0xFFE6E8EA);

  @override
  void initState() {
    super.initState();
    fetchTeam();
  }

  int _levelOf(dynamic user) =>
      int.tryParse(user["level"].toString()) ?? 999;

  void _sortByLevel(List list) {
    list.sort((a, b) => _levelOf(a).compareTo(_levelOf(b)));
  }

  Future<void> fetchTeam() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";

      final response = await ApiService.getMyTeam(token);

      if (response["success"] == true) {
        final data = response["data"];

        final fetchedManagers = List.from(data["managers"] ?? []);
        final fetchedTeam = List.from(data["team"] ?? []);

        // Higher levels (lower level number) shown first
        _sortByLevel(fetchedManagers);
        _sortByLevel(fetchedTeam);

        setState(() {
          currentUser = data["current_user"];
          managers = fetchedManagers;
          team = fetchedTeam;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  Color getRoleColor(int? level) {
    switch (level) {
      case 1:
        return Colors.deepPurple;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.teal;
      case 5:
        return Colors.redAccent;
      default:
        return const Color(0xFF1B5E20);
    }
  }

 Widget buildUserCard(dynamic user, {bool isManager = false}) {

  final String name = (user["name"] ?? "").toString();

  final String role = (user["job_role"] ?? "").toString();

  final String contact = (user["contact_no"] ?? "").toString();

  final int level = int.tryParse(user["level"].toString()) ?? 0;

  final Color roleColor = getRoleColor(level);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),

    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),

    child: Padding(
      padding: const EdgeInsets.all(14),

      child: Row(
        children: [

          // Avatar
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.25)),
            ),

            alignment: Alignment.center,

            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",

              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  name.isNotEmpty ? name : "Unknown User",

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kInk,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Text(
                    role.isNotEmpty ? role : "No Role",

                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [

                    Icon(
                      Icons.call,
                      size: 14,
                      color: Colors.grey[500],
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        contact.isNotEmpty ? contact : "No Contact",

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              "L$level",

              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kPrimaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _kDarkGreen,
            size: 18,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kInk,
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimaryGreen),
            )
          : RefreshIndicator(
              color: _kPrimaryGreen,
              onRefresh: fetchTeam,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==============================
                    // CURRENT USER CARD
                    // ==============================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF388E3C),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimaryGreen.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(.4),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Text(
                           (currentUser?["name"] ?? "").toString().isNotEmpty
    ? currentUser!["name"].toString()[0].toUpperCase()
    : "U",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            currentUser?["name"] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            currentUser?["job_role"] ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.16),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentUser?["contact_no"] ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ==============================
                    // MANAGERS
                    // ==============================

                    buildSectionTitle(
                      "Reporting Managers",
                      Icons.account_tree,
                    ),

                    const SizedBox(height: 14),

                    managers.isEmpty
                        ? buildEmptyState("No Reporting Managers")
                        : Column(
                            children: managers
                                .map(
                                  (e) => buildUserCard(
                                    e,
                                    isManager: true,
                                  ),
                                )
                                .toList(),
                          ),

                    const SizedBox(height: 26),

                    // ==============================
                    // TEAM MEMBERS
                    // ==============================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildSectionTitle(
                          "My Team",
                          Icons.groups_rounded,
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _kDarkGreen,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "${team.length} Members",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    team.isEmpty
                        ? buildEmptyState("No Team Members")
                        : Column(
                            children: team
                                .map(
                                  (e) => buildUserCard(e),
                                )
                                .toList(),
                          ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}