import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      DateTime parsedDate = DateTime.parse(date);

      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String year = parsedDate.year.toString();

      return "$day-$month-$year";
    } catch (e) {
      return date ?? '';
    }
  }

  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() async {
    var res = await ApiService.getProfile();

    if (res != null && res['success'] == true) {
      setState(() {
        profile = res['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget infoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
Widget sectionTitle(String title) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B5E20),
      ),
    ),
  );
}

Widget sectionCard(List<Widget> children) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4),
      ],
    ),
    child: Column(children: children),
  );
}
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load profile")),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF255228),
                    Color(0xFF306E33),
                    Color(0xFF73A775),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                //  CHANGE HERE
                children: [
                  /// LEFT - PROFILE ICON
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      profile!['name'] != null && profile!['name'].isNotEmpty
                          ? profile!['name'].substring(0, 1).toUpperCase()
                          : '',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  /// RIGHT - NAME + ROLE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile!['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        profile!['job_role_name'] ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),

                    ],
                  ),
                ],
              ),
            ),


            /// INFO
            
         /// 👤 PERSONAL DETAILS
sectionTitle("Personal Details"),
sectionCard([
  infoTile("Date of Birth", formatDate(profile!['date_of_birth']), Icons.event),
  infoTile("Father's Name", profile!['father_name'] ?? '', Icons.person),
  infoTile("Email", profile!['email'] ?? '', Icons.email),
  infoTile("Phone", profile!['contact_no'] ?? '', Icons.phone),
  infoTile("Gender", profile!['gender'] ?? '', Icons.person),
  infoTile("Aadhar No", profile!['aadhar_no'] ?? '', Icons.credit_card),
  infoTile("PAN No", profile!['pan_number'] ?? '', Icons.credit_card),
  infoTile("Blood Group", profile!['blood_group'] ?? '', Icons.bloodtype),
  infoTile("Joining Date", formatDate(profile!['date_of_joining']), Icons.calendar_today),
]),

///  ADDRESS
sectionTitle("Address Details"),
sectionCard([
  infoTile("Address 1", profile!['address_line1'] ?? '', Icons.home),
  infoTile("Address 2", profile!['address_line2'] ?? '', Icons.home),
  infoTile("Area", profile!['area'] ?? '', Icons.map),
  infoTile("District", profile!['district'] ?? '', Icons.location_city),
  infoTile("State", profile!['state'] ?? '', Icons.map),
  infoTile("Pincode", profile!['pincode'] ?? '', Icons.local_post_office),
]),

///  JOB DETAILS
sectionTitle("Job Details"),
sectionCard([
  infoTile("Department", profile!['department_name'] ?? '', Icons.apartment),
  infoTile("Job Role", profile!['job_role_name'] ?? '', Icons.work),
  infoTile("Salary", profile!['salary'] != null ? "₹${profile!['salary']}" : '', Icons.currency_rupee),
  infoTile("Head", profile!['headquarter'] ?? '', Icons.supervisor_account),
  infoTile("Week Off", profile!['week_off'] ?? '00', Icons.calendar_view_day),
]),

///  ALLOWANCES
sectionTitle("Allowances"),
sectionCard([
  infoTile("Travelling Allowance", "₹${profile!['travelling_allowance_per_km'] ?? ''}", Icons.directions_car),
  infoTile("Avg KM/Day", "${profile!['avg_travel_km_per_day'] ?? ''}", Icons.route),
  infoTile("City Allowance", "₹${profile!['city_allowance_per_km'] ?? ''}", Icons.location_city),
  infoTile("DA (With Doc)", "₹${profile!['daily_allowance_with_doc'] ?? ''}", Icons.receipt),
  infoTile("DA (Without Doc)", "₹${profile!['daily_allowance_without_doc'] ?? ''}", Icons.receipt_long),
  infoTile("Hotel", "₹${profile!['hotel_allowance'] ?? ''}", Icons.hotel),
  infoTile("Leaves", "${profile!['total_leaves'] ?? ''} days", Icons.beach_access),
  infoTile("Auth Amount", "₹${profile!['authentication_amount'] ?? ''}", Icons.lock),
]),

/// ⏱ TIMING & BENEFITS
sectionTitle("Timing & Benefits"),
sectionCard([
  infoTile("Login Time", formatDate(profile!['login_time']), Icons.login),
  infoTile("Logout Time", formatDate(profile!['logout_time']), Icons.logout),
  infoTile("PF", "₹${profile!['pf'] ?? ''}", Icons.account_balance),
  infoTile("ESI", "₹${profile!['esi'] ?? ''}", Icons.health_and_safety),
]),
            const SizedBox(height: 20),

            /// BUTTONS
          
          ],
        ),
      ),
    );
  }
}
