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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:screen_protector/screen_protector.dart';
import 'services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './services/db_helper.dart';
import './services/status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await ScreenProtector.preventScreenshotOn();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('FLUTTER_BASE_URL', dotenv.env['FLUTTER_BASE_URL']!);

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  await initializeService();
  runApp(const MyApp());
}
// bool isServiceRunning = false;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();


  //  CHANNEL 1 (Foreground service)
  const AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'This channel is used for location tracking.',
    importance: Importance.low,
  );

  //  CHANNEL 2 (Visit reminder)
  const AndroidNotificationChannel visitChannel = AndroidNotificationChannel(
    'visit_channel_v2',
    'Visit Reminder',
    description: 'Reminder notifications for visits',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert'),
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  //  REGISTER BOTH CHANNELS (THIS WAS YOUR MISTAKE)
  await androidPlugin?.createNotificationChannel(locationChannel);
  await androidPlugin?.createNotificationChannel(visitChannel);

  //  SERVICE CONFIG
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_channel', //  foreground uses this
      foregroundServiceNotificationId: 1001,
      initialNotificationTitle: 'Tracking Active',
      initialNotificationContent: 'Preparing location service...',
    ),
    iosConfiguration: IosConfiguration(),
  );
}

Future<void> sendLocationFromStream(
  ServiceInstance service,
  Position position,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final employeeId = prefs.getInt('employee_id');
    final token = prefs.getString('token');

    if (employeeId == null || token == null || token.isEmpty) return;

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

    int retryCount = 0;
    const maxRetries = 2;
    bool allFailed = false;

    while (retryCount <= maxRetries) {
      try {
        final response = await ApiService.sendLocation(
          employeeId: employeeId,
          token: token,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
        );

        print("LOCATION API RESPONSE: $response");

        if (response != null && response['success'] == true) {
          break; //  IMPORTANT: don't return, break loop
        } else {
          throw Exception("API failed");
        }
      } catch (e) {
        retryCount++;
        print("Retry $retryCount failed: $e");

        if (retryCount > maxRetries) {
          allFailed = true;
          print(" All retries failed → saving locally");
          await saveLocationLocally(position);
        } else {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }

    //  ADD HERE (THIS IS THE CORRECT PLACE)
    if (!allFailed) {
      await resendPendingIfNeeded(employeeId, token);
    }
  } catch (e) {
    print("Stream Location error: $e");
  }
}

Future<void> saveLocationLocally(Position position) async {
  await DBHelper.insertLocation({
    'latitude': position.latitude,
    'longitude': position.longitude,
    'accuracy': position.accuracy,
    'speed': position.speed,
    'timestamp': DateTime.now().toIso8601String(),
  });
  print(" Saved to SQLite");
}

Future<void> resendPendingLocations(int employeeId, String token) async {
  final locations = await DBHelper.getLocations();

  if (locations.isEmpty) return;

  print("Resending ${locations.length} locations");

  for (var loc in locations) {
    try {
      final response = await ApiService.sendLocation(
        employeeId: employeeId,
        token: token,
        latitude: loc['latitude'],
        longitude: loc['longitude'],
        accuracy: loc['accuracy'],
        speed: loc['speed'],
      );

      if (response != null && response['success'] == true) {
        await DBHelper.deleteLocation(loc['id']); //  delete after success
      }
    } catch (e) {
      print("Retry failed: $e");
    }
  }
}

Future<void> resendPendingIfNeeded(int employeeId, String token) async {
  final prefs = await SharedPreferences.getInstance();

  final lastResend = prefs.getInt("last_resend_time") ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;

  //  Only allow resend every 15 minutes
  if (now - lastResend < 15 * 60 * 1000) {
    return;
  }

  await prefs.setInt("last_resend_time", now);

  await resendPendingLocations(employeeId, token);
}

Future<void> checkVisitsAndNotify() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final token = prefs.getString('token') ?? '';
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final workType = prefs.getString('work_type') ?? '';

    if (workType.toLowerCase() != "field") return;

    final response = await http.get(
      Uri.parse('$baseUrl/get-my-todayVisitCount'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    print("VISIT API RESPONSE: $data");
    print("CHECK VISITS CALLED");

    if (response.statusCode == 200) {
      // int visits = data['visits'] ?? 0;
      int visits = data['totalVisits'] ?? 0;

      final lastTime = prefs.getInt("last_notify_time") ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      final diff = currentTime - lastTime;

      print("LAST TIME: $lastTime");
      print("CURRENT: $currentTime");
      print("DIFF MS: $diff");

      if (visits < 4) {
        // if (lastTime == 0 || diff >= 10 * 1000) {
        if (lastTime == 0 || diff >= 15 * 60 * 1000) {
          await prefs.setInt("last_notify_time", currentTime);

          String message = visits == 0
              ? "You haven't started visits yet. Complete 4 visits to avoid half day."
              : "You have only $visits visits. Complete 4 visits to avoid half day.";

          await NotificationService.showNotification("Visit Reminder", message);

          print(" NOTIFICATION SENT");
        }
      }
    }
  } catch (e) {
    print("Visit check error: $e");
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await NotificationService.init();
  await checkVisitsAndNotify();
  Timer? timer;

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Tracking Active",
      content: "Location tracking is running",
    );
  }
  print(" BACKGROUND SERVICE STARTED");
  timer = Timer.periodic(const Duration(minutes: 12), (timer) async {
    print("⏱ VISIT CHECK TIMER");

    await checkVisitsAndNotify();
  });

  Timer.periodic(const Duration(minutes: 2), (timer) async {
    print(" STATUS CHECK RUNNING");

    await StatusService.sendStatus();
  });

  Geolocator.getPositionStream(
  locationSettings: AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0, // important
    intervalDuration: Duration(minutes: 1), //  every 1 min
  ),
).listen((Position position) async {
  print("LOCATION EVERY 1 MIN: ${DateTime.now()}");

  await sendLocationFromStream(service, position);
});

//   service.on('stopService').listen((event) {
//   service.stopSelf();
// });

service.on('stopService').listen((event) {
    print("STOP SERVICE CALLED");
    service.stopSelf();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jamidara CRM',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
