import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // ================= PERMISSION FUNCTION =================
  Future<bool> _requestPermissions(BuildContext context) async {
  bool allGranted = true;

  Map<Permission, String> permissions = {
    Permission.camera: 'Camera',
    Permission.phone: 'Phone',
    Permission.notification: 'Notification',
    Permission.contacts: 'Contacts',
  };

  // Battery optimization
  if (!await Permission.ignoreBatteryOptimizations.isGranted) {
    await Permission.ignoreBatteryOptimizations.request();
  }

  for (var entry in permissions.entries) {
    PermissionStatus status = await entry.key.status;

    if (!status.isGranted) {
      status = await entry.key.request();
    }

    if (!status.isGranted) {
      allGranted = false;

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${entry.value} permission is permanently denied. Please enable it from settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.value} permission is required')),
        );
      }
    }
  }

  // Check GPS service first
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enable GPS to continue")),
    );
    await Geolocator.openLocationSettings();
    return false;
  }

  // Request foreground location first
  PermissionStatus locationWhenInUse = await Permission.locationWhenInUse.status;
  if (!locationWhenInUse.isGranted) {
    locationWhenInUse = await Permission.locationWhenInUse.request();
  }

  if (!locationWhenInUse.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location permission is required")),
    );
    return false;
  }

  // Then request background location
  PermissionStatus locationAlways = await Permission.locationAlways.status;
  if (!locationAlways.isGranted) {
    locationAlways = await Permission.locationAlways.request();
  }

  if (!locationAlways.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Please allow background location ('Allow all the time') in app settings",
        ),
        action: SnackBarAction(
          label: "Settings",
          onPressed: openAppSettings,
        ),
      ),
    );
    return false;
  }

  return allGranted;
}

  // ================= UI =================
 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [

        // ===== BACKGROUND GRADIENT =====
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF163E2F),
                Color(0xFF1E4D3B),
                Color(0xFF2F614D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // ===== SOFT CIRCLE GLOW =====
        Positioned(
          top: -100,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),

        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ===== LOGO =====
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/jsc_logo.png',
                      height: 120,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Empowering Agriculture with Innovation",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ===== PREMIUM BUTTON =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        bool granted =
                            await _requestPermissions(context);

                        if (granted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(40),
                        ),
                        elevation: 10,
                        shadowColor: Colors.black45,
                      ),
                      child: const Text(
                        "Get Started",
                        style: TextStyle(
                          color: Color(0xFF1E4D3B),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Let’s grow together 🌱",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}