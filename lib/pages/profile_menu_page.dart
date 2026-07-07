import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import '../layout/app_router.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../pages/my_team_page.dart';
import "../pages/EmpProfile/team_visit_report_page.dart";
import "../pages/EmpProfile/track_team_employees.dart";
import "../pages/EmpProfile/team_menu_page.dart";

class ProfileMenuPage extends StatefulWidget {
  final bool clearSavedCredentialsOnLogout;
  final Function(int)? onTabChange;

  const ProfileMenuPage({
    super.key,
    this.clearSavedCredentialsOnLogout = false,
    this.onTabChange,
  });

  @override
  State<ProfileMenuPage> createState() => _ProfileMenuPageState();
}

class _ProfileMenuPageState extends State<ProfileMenuPage> {
  File? selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      selectedImage = File(picked.path);
      _showConfirmDialog();
    }
  }

  Future<void> _showConfirmDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Profile"),
        content: const Text("Are you sure you want to update profile image?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true && selectedImage != null) {
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await ApiService.updateMyProfile(token, selectedImage!);

      if (res["success"] == true) {
        ///  IMPORTANT FIX HERE
        final currentUser = UserService.user;

        if (currentUser != null) {
          UserService.setUser({
            ...currentUser,
            "profile_image_url": res["profile_image"], // update image only
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Upload failed")),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    // only login session remove
    await prefs.remove('token');
    await prefs.remove('employee_id');

    UserService.clearUser();

    // if you want to clear email/password too, set this true
    if (widget.clearSavedCredentialsOnLogout) {
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

  Widget _buildInitialAvatar(String name) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '',
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
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

  void _showFullImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(child: InteractiveViewer(child: Image.network(imageUrl))),
    );
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
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: UserService.currentUser,
                builder: (context, user, _) {
                  final name = user?['name'] ?? 'User';
                  final jobRole = user?['job_role_name'] ?? '';
                  final imageUrl = user?['profile_image_url'];

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        ///  Profile Avatar
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showFullImage(imageUrl);
                              },
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child:
                                      (imageUrl != null && imageUrl.isNotEmpty)
                                      ? Image.network(
                                          imageUrl,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return _buildInitialAvatar(
                                                  name,
                                                );
                                              },
                                        )
                                      : _buildInitialAvatar(name),
                                ),
                              ),
                            ),

                            ///  Camera Icon
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1B5E20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        ///  Name + Role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                jobRole,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  children: [
                    // Replace the 'My Profile' and 'Team' onTap callbacks inside
                    // ProfileMenuPage's build() with these. Same pattern: pushReplacement,
                    // no pop-before-navigate, null-checked, mounted-checked.
                    _buildTile(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      subtitle: 'View employee profile details',
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
                              initialRoute: "profile_page",
                            ),
                          ),
                        );
                      },
                    ),

                    _buildTile(
                      context: context,
                      icon: Icons.groups_rounded,
                      title: 'Team',
                      subtitle: 'Team, attendance, visits & tracking',
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
                              initialRoute: "team_menu",
                            ),
                          ),
                        );
                      },
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.fingerprint,
                      title: 'My Attendance',
                      subtitle: 'Check attendance status and records',
                      onTap: () async {
                        Navigator.pop(context);

                        final token = await StorageService.getToken();
                        final employeeId = await StorageService.getEmployeeId();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppRouter(
                              employeeId: employeeId!,
                              token: token!,
                              initialRoute: "attendance_report",
                            ),
                          ),
                        );
                      },
                    ),

                    _buildTile(
                      context: context,
                      icon: Icons.location_on_outlined,
                      title: 'My Visits',
                      subtitle: 'Check market visit activities',
                      onTap: () async {
                        Navigator.pop(context);

                        final token = await StorageService.getToken();
                        final employeeId = await StorageService.getEmployeeId();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppRouter(
                              employeeId: employeeId!,
                              token: token!,
                              initialRoute: "visit_report",
                            ),
                          ),
                        );
                      },
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
                      icon: Icons.shopping_cart_outlined,
                      title: 'My Orders',
                      subtitle: 'View order records',
                      onTap: () {},
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.monetization_on,
                      title: 'My Salary Report',
                      subtitle: 'View you daily salary',
                      onTap: () async {
                        Navigator.pop(context);

                        final token = await StorageService.getToken();
                        final employeeId = await StorageService.getEmployeeId();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppRouter(
                              employeeId: employeeId!,
                              token: token!,
                              initialRoute: "salary_report", //  IMPORTANT
                            ),
                          ),
                        );
                      },
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
