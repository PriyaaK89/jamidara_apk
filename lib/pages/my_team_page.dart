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

  @override
  void initState() {
    super.initState();
    fetchTeam();
  }

  Future<void> fetchTeam() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";

      final response = await ApiService.getMyTeam(token);

      if (response["success"] == true) {
        final data = response["data"];

        setState(() {
          currentUser = data["current_user"];
          managers = data["managers"] ?? [];
          team = data["team"] ?? [];
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
    margin: const EdgeInsets.only(bottom: 14),

    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),

      gradient: LinearGradient(
        colors: isManager
            ? [
                Colors.blue.shade50,
                Colors.white,
              ]
            : [
                Colors.green.shade50,
                Colors.white,
              ],
      ),

      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: Padding(
      padding: const EdgeInsets.all(14),

      child: Row(
        children: [

          // Avatar
          Container(
            width: 60,
            height: 60,

            decoration: BoxDecoration(
              color: roleColor,
              shape: BoxShape.circle,
            ),

            alignment: Alignment.center,

            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",

              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Text(
                    role.isNotEmpty ? role : "No Role",

                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    const Icon(
                      Icons.call,
                      size: 16,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        contact.isNotEmpty ? contact : "No Contact",

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
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
        Icon(
          icon,
          color: const Color(0xFF1B5E20),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
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
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF43A047),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                              child: Text(
                           (currentUser?["name"] ?? "").toString().isNotEmpty
    ? currentUser!["name"].toString()[0].toUpperCase()
    : "U",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            currentUser?["name"] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            currentUser?["job_role"] ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.18),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              currentUser?["contact_no"] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==============================
                    // MANAGERS
                    // ==============================

                    buildSectionTitle(
                      "Reporting Managers",
                      Icons.account_tree,
                    ),

                    const SizedBox(height: 14),

                    managers.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                "No Reporting Managers",
                              ),
                            ),
                          )
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

                    const SizedBox(height: 28),

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
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            "${team.length} Members",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    team.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                "No Team Members",
                              ),
                            ),
                          )
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