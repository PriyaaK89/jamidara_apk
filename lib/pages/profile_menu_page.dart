import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';

class ProfileMenuPage extends StatelessWidget {
  final bool clearSavedCredentialsOnLogout;

  const ProfileMenuPage({
    super.key,
    this.clearSavedCredentialsOnLogout = false,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    // only login session remove
    await prefs.remove('token');
    await prefs.remove('employee_id');

    // if you want to clear email/password too, set this true
    if (clearSavedCredentialsOnLogout) {
      await prefs.remove('saved_email');
      await secureStorage.delete(key: 'saved_password');
    }

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginPage(
        message: "Logout Successful", //  pass message
      ),
    ),
    (route) => false,
  );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = const Color(0xFF1B5E20),
    Color textColor = Colors.black87,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 203, 40, 28),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // top employee card
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
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marketing Employee',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Jamidara Seeds Corporation',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  children: [
                    _buildTile(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      subtitle: 'View employee profile details',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.fingerprint,
                      title: 'My Attendance',
                      subtitle: 'Check attendance status and records',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.flag_outlined,
                      title: 'My Targets',
                      subtitle: 'View assigned targets and progress',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.location_on_outlined,
                      title: 'My Visits',
                      subtitle: 'Check market visit activities',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      title: 'My Orders',
                      subtitle: 'View order records',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update account password',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.support_agent,
                      title: 'Help & Support',
                      subtitle: 'Contact office/admin support',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'App Info',
                      subtitle: 'Version and company details',
                      onTap: () {},
                    ),

                    const SizedBox(height: 14),

                    Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.12),
                          child: const Icon(Icons.logout, color: Colors.red),
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: const Text('Sign out from this device'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.red,
                        ),
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}