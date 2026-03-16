import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'routes/app_routes.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'This channel is used for location tracking.',
    importance: Importance.high,
    playSound: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      foregroundServiceNotificationId: 1001,
      initialNotificationTitle: 'Tracking Active',
      initialNotificationContent: 'Preparing location service...',
    ),
    iosConfiguration: IosConfiguration(),
  );
}

Future<void> sendLocation(ServiceInstance service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getInt('employee_id');
    final token = prefs.getString('token');

    print("Stored employeeId: $employeeId");
    print("Stored token: $token");

    if (employeeId == null || token == null || token.isEmpty) {
      print("No employee session found. Location not sent.");
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS / Location service is disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      print("Location permission denied");
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission denied forever");
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    print("Location fetched:");
    print("Latitude: ${position.latitude}");
    print("Longitude: ${position.longitude}");
    print("Accuracy: ${position.accuracy}");
    print("Speed: ${position.speed}");

    await ApiService.sendLocation(
      employeeId: employeeId,
      token: token,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
    );

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Tracking Active",
        content: "Lat: ${position.latitude}, Lng: ${position.longitude}",
      );
    }

    print("Location sent successfully");
  } catch (e, stack) {
    print("Location error: $e");
    print("Stack trace: $stack");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  Timer? timer;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: "Tracking Active",
      content: "Initializing location service...",
    );
  }

  service.on('stopService').listen((event) {
    print("Stop service event received");
    timer?.cancel();
    service.stopSelf();
  });

  // First call immediately
  await sendLocation(service);

  // Then every 1 minute
  timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
    print("Running background location task...");
    await sendLocation(service);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jamidara CRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}