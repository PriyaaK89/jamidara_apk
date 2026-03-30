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
    importance: Importance.low, // foreground service ke liye low ya higher theek hai
    playSound: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
    await prefs.reload();

    final employeeId = prefs.getInt('employee_id');
    final token = prefs.getString('token');

    if (employeeId == null || token == null || token.isEmpty) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );


    final response = await ApiService.sendLocation(
  employeeId: employeeId,
  token: token,
  latitude: position.latitude,
  longitude: position.longitude,
  accuracy: position.accuracy,
  speed: position.speed,
);

    if (response != null && response['success'] == false) {
  print("Stopping service: ${response['message']}");
  service.invoke("stopService");
}
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
    await service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Tracking Active",
      content: "Location tracking is running",
    );
  }

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  await sendLocation(service);

  timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
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