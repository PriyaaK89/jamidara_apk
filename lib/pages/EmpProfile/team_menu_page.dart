import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../layout/app_router.dart';
import '../EmpProfile/team_visit_report_page.dart';
import '../EmpProfile/track_team_employees.dart';

class TeamMenuPage extends StatelessWidget {
  const TeamMenuPage({super.key});

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspaces_rounded, // distinct from "My Team" tile icon
              color: Color(0xFF1B5E20),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Team',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Members, attendance, visits & tracking',
                  style: TextStyle(fontSize: 13.5, color: Color(0xFF8A8F98)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFFA0A5AD),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F1F3), width: 1),
              ),
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          splashColor: accentColor.withOpacity(0.06),
          highlightColor: accentColor.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF9AA0A8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFFC4C8CE),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: tiles),
    );
  }

  Widget _buildFooterNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any option above to view detailed reports for your team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(),
                  _buildSectionLabel('Overview'),
                  _buildCardGroup([
                    // Replace the 4 tile onTap callbacks inside TeamMenuPage's build() with these.
                    // Key change: no Navigator.pop() before the async work, always
                    // pushReplacement (not push+pop), null-checked, mounted-checked.
                    _buildTile(
                      context: context,
                      icon: Icons.groups_rounded,
                      title: 'My Team',
                      subtitle: 'View your team members',
                      accentColor: const Color(0xFF1B5E20),
                      onTap: () async {
                        final token = await StorageService.getToken();
                        final employeeId = await StorageService.getEmployeeId();
                        if (token == null || employeeId == null) return;
                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppRouter(
                              employeeId: employeeId,
                              token: token,
                              initialRoute: "my_team",
                            ),
                          ),
                        );
                      },
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.fingerprint_rounded,
                      title: 'My Team Attendance',
                      subtitle: 'Check attendance status of team',
                      accentColor: const Color(0xFF2E7D32),
                      onTap: () async {
                        final token = await StorageService.getToken();
                        final employeeId = await StorageService.getEmployeeId();
                        if (token == null || employeeId == null) return;
                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppRouter(
                              employeeId: employeeId,
                              token: token,
                              initialRoute: "team_attendance_report",
                            ),
                          ),
                        );
                      },
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.assignment_ind_rounded,
                      title: 'My Team Visit',
                      subtitle: 'View visits of assigned team members',
                      accentColor: const Color(0xFF00695C),
                      onTap: () async {
                        final level = await StorageService.getJobRoleLevel();
                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamVisitReportPage(myLevel: level),
                          ),
                        );
                      },
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.location_pin,
                      title: 'Track Team Members',
                      subtitle: 'View route of your team',
                      accentColor: const Color(0xFFE65100),
                      onTap: () async {
                        final level = await StorageService.getJobRoleLevel();
                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrackTeamPage(myLevel: level),
                          ),
                        );
                      },
                      isLast: true,
                    ),
                  ]),
                  _buildFooterNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
