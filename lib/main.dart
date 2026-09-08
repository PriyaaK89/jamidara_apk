import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geo;
import './services/status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:screen_protector/screen_protector.dart';
import 'services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './services/db_helper.dart';

// ─── Top-level cached credentials (safe in background isolate) ───────────────
int? _cachedEmployeeId;
String? _cachedToken;
String _currentLocationStatus = "OFF";

// ─── Track active stream subscription so we can cancel & restart it ──────────
StreamSubscription<geo.Position>? _locationSubscription;
StreamSubscription<geo.ServiceStatus>? _serviceStatusSubscription;

// ─── How many consecutive stream errors before we give up & restart ───────────
int _streamErrorCount = 0;
const int _maxStreamErrors = 3;

Timer? _credentialTimer;
Timer? _visitCheckTimer;
Timer? _statusCheckTimer;
Timer? _watchdogTimer;

Future<void> _loadCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  _cachedEmployeeId = prefs.getInt('employee_id');
  _cachedToken = prefs.getString('token');

  print("BACKGROUND LOAD → ID: $_cachedEmployeeId");
  print("BACKGROUND LOAD → TOKEN: $_cachedToken");

  if (_cachedEmployeeId == null || _cachedToken == null) {
    print("Retrying credential load in 2s...");
    await Future.delayed(const Duration(seconds: 2));

    await prefs.reload();
    _cachedEmployeeId = prefs.getInt('employee_id');
    _cachedToken = prefs.getString('token');

    print("RETRY LOAD → ID: $_cachedEmployeeId");
    print("RETRY LOAD → TOKEN: $_cachedToken");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // await ScreenProtector.preventScreenshotOn();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('FLUTTER_BASE_URL', dotenv.env['FLUTTER_BASE_URL']!);

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  if (await Permission.locationAlways.isDenied) {
    await Permission.locationAlways.request();
  }

  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }

  await initializeService();

  // FIX: On app start, check if the user was previously marked "present"
  // but the service is not running (e.g. app was killed). If so, restart
  // the service so location tracking resumes automatically.
  await _resumeServiceIfNeeded();

  runApp(const MyApp());
}

// ─── Resume service if user is still "checked in" ────────────────────────────
// This handles the case where the app/phone was restarted after marking
// "present" but before marking "day_over". Without this, location tracking
// would silently stop until the user reopens and re-submits attendance.
Future<void> _resumeServiceIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final isCheckedIn = prefs.getBool('is_checked_in') ?? false;

  if (!isCheckedIn) return;

  final service = FlutterBackgroundService();
  final running = await service.isRunning();

  if (!running) {
    print("User is checked in but service is not running — restarting...");
    await service.startService();
  }
}

// ─── Service initialisation ───────────────────────────────────────────────────
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'This channel is used for location tracking.',
    importance: Importance.low,
  );

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

  await androidPlugin?.createNotificationChannel(locationChannel);
  await androidPlugin?.createNotificationChannel(visitChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      foregroundServiceNotificationId: 1001,
      initialNotificationTitle: 'Tracking Active',
      initialNotificationContent: 'Preparing location service...',
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

// ─── GPS stream — cancels & restarts safely on error ─────────────────────────
void _startLocationStream(ServiceInstance service) {
  _locationSubscription?.cancel();
  _locationSubscription = null;
  _streamErrorCount = 0;

  print("Starting GPS location stream...");

  _locationSubscription =
      geo.Geolocator.getPositionStream(
        locationSettings: geo.AndroidSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 30),
          foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
            notificationText: "Tracking your location",
            notificationTitle: "Location Active",
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      ).listen(
        (geo.Position position) async {
          _streamErrorCount = 0;
          _currentLocationStatus = "ON";
          print("LOCATION: ${DateTime.now()}");
          await sendLocationFromStream(service, position);
        },
        onError: (error) {
          _streamErrorCount++;
          print("Stream error ($_streamErrorCount/$_maxStreamErrors): $error");

          if (_streamErrorCount >= _maxStreamErrors) {
            print("Max stream errors reached. Restarting stream in 30s...");
            _locationSubscription?.cancel();
            _locationSubscription = null;
            Future.delayed(const Duration(seconds: 30), () {
              _startLocationStream(service);
            });
          }
        },
        cancelOnError: false,
      );
}

// ─── Send location to API ─────────────────────────────────────────────────────
Future<void> sendLocationFromStream(
  ServiceInstance service,
  geo.Position position,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isCheckedIn = prefs.getBool('is_checked_in') ?? false;

    if (!isCheckedIn) {
      print("LOCATION SKIPPED: User not checked in");
      return;
    }
    final employeeId = _cachedEmployeeId;
    final token = _cachedToken;

    if (employeeId == null) {
      print("LOCATION SKIPPED: employeeId is null");
      return;
    }
    if (token == null || token.isEmpty) {
      print("LOCATION SKIPPED: token is null or empty");
      return;
    }

    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("LOCATION SKIPPED: Location service is disabled on device");
      return;
    }

    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      print("LOCATION SKIPPED: Location permission is $permission");
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
          break;
        } else {
          throw Exception("API returned failure: $response");
        }
      } catch (e) {
        retryCount++;
        print("Retry $retryCount failed: $e");

        if (retryCount > maxRetries) {
          allFailed = true;
          print("All retries failed → saving locally");
          await saveLocationLocally(position);
        } else {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }

    if (!allFailed) {
      await resendPendingIfNeeded(employeeId, token);
    }
  } catch (e) {
    print("sendLocationFromStream error: $e");
  }
}

// ─── SQLite helpers ───────────────────────────────────────────────────────────
Future<void> saveLocationLocally(geo.Position position) async {
  await DBHelper.insertLocation({
    'latitude': position.latitude,
    'longitude': position.longitude,
    'accuracy': position.accuracy,
    'speed': position.speed,
    'timestamp': DateTime.now().toIso8601String(),
  });
  print("Saved to SQLite");
}

Future<void> resendPendingLocations(int employeeId, String token) async {
  final locations = await DBHelper.getLocations();
  if (locations.isEmpty) return;

  print("Resending ${locations.length} pending locations");

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
        await DBHelper.deleteLocation(loc['id']);
      }
    } catch (e) {
      print("Pending resend failed: $e");
      break;
    }
  }
}

Future<void> resendPendingIfNeeded(int employeeId, String token) async {
  final prefs = await SharedPreferences.getInstance();
  final lastResend = prefs.getInt("last_resend_time") ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;

  if (now - lastResend < 15 * 60 * 1000) return;

  await prefs.setInt("last_resend_time", now);
  await resendPendingLocations(employeeId, token);
}

// ─── Visit notification check ─────────────────────────────────────────────────
Future<void> checkVisitsAndNotify() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final isCheckedIn = prefs.getBool('is_checked_in') ?? false;
    if (!isCheckedIn) {
      print("VISIT CHECK SKIPPED: user not checked in");
      return;
    }

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

    if (response.statusCode == 200) {
      int visits = data['totalVisits'] ?? 0;

      final lastTime = prefs.getInt("last_notify_time") ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final diff = currentTime - lastTime;

      if (visits < 4) {
        if (lastTime == 0 || diff >= 15 * 60 * 1000) {
          await prefs.setInt("last_notify_time", currentTime);

          final String message = visits == 0
              ? "You haven't started visits yet. Complete 4 visits to avoid half day."
              : "You have only $visits visits. Complete 4 visits to avoid half day.";

          await NotificationService.showNotification("Visit Reminder", message);
          print("NOTIFICATION SENT");
        }
      }
    }
  } catch (e) {
    print("Visit check error: $e");
  }
}

void _listenToLocationService(ServiceInstance service) {
  _serviceStatusSubscription?.cancel();

  _serviceStatusSubscription = geo.Geolocator.getServiceStatusStream().listen((
    status,
  ) async {
    print("GPS STATUS CHANGED: $status");

    String newStatus = status == geo.ServiceStatus.enabled ? "ON" : "OFF";

    //  Only send when actual change happens
    if (_currentLocationStatus == newStatus) {
      print("No change in location status");
      return;
    }

    _currentLocationStatus = newStatus;

    print("Sending instant status update: $newStatus");

    // await StatusService.sendStatus(
    //   locationOverride: newStatus,
    // );
    final shouldLogout = await StatusService.sendStatus(
      locationOverride: newStatus,
    );

    if (shouldLogout) {
      print("Instant logout trigger");

      service.invoke("forceLogout"); // immediate logout
    }
  });
}

// ─── Background service entry point ──────────────────────────────────────────
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final isCheckedIn = prefs.getBool('is_checked_in') ?? false;

  if (!isCheckedIn) {
    print("Service started but user not checked in — stopping");
    service.stopSelf();
    return;
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });

    await service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Tracking Active",
      content: "Location tracking is running",
    );
  }

  await _loadCredentials();

  _listenToLocationService(service);
  print("BACKGROUND SERVICE STARTED");

  if (_cachedEmployeeId == null || _cachedToken == null) {
    print("Credentials not ready — retrying in 5s...");
    await Future.delayed(const Duration(seconds: 5));
    await _loadCredentials();
  }

  await checkVisitsAndNotify();

  _credentialTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
    await _loadCredentials();
    print("Credentials refreshed");
  });

  _visitCheckTimer = Timer.periodic(const Duration(minutes: 18), (_) async {
    print("VISIT CHECK TIMER");
    await checkVisitsAndNotify();
  });

  _statusCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
    print("STATUS CHECK RUNNING");
    final shouldLogout = await StatusService.sendStatus();
    if (shouldLogout) {
      print(" Sending logout event to UI");
      service.invoke("forceLogout");
    }
    print("SERVICE STILL RUNNING");
  });

  _watchdogTimer = Timer.periodic(const Duration(minutes: 6), (_) {
    if (_locationSubscription == null) {
      print("WATCHDOG: GPS stream is dead — restarting...");
      _startLocationStream(service);
    } else {
      print("WATCHDOG: GPS stream is alive ✓");
    }
  });
  _startLocationStream(service);

  service.on('stopService').listen((event) async {
    print("STOP SERVICE CALLED");
    _locationSubscription?.cancel();
    _locationSubscription = null;

    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;

    _credentialTimer?.cancel();
    _credentialTimer = null;

    _visitCheckTimer?.cancel();
    _visitCheckTimer = null;

    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;

    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    // FIX: Clear the checked-in flag when service is stopped via day_over
    // so that _resumeServiceIfNeeded() does NOT restart it on next app launch.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_checked_in', false);
    await prefs.remove('work_type');
    await prefs.remove('last_notify_time');

    service.stopSelf();
  });

  service.on('restartTracking').listen((event) async {
  print("RESTART TRACKING CALLED (cleaning up stale session)");
  _locationSubscription?.cancel();
  _locationSubscription = null;

  _serviceStatusSubscription?.cancel();
  _serviceStatusSubscription = null;

  _credentialTimer?.cancel();
  _credentialTimer = null;

  _visitCheckTimer?.cancel();
  _visitCheckTimer = null;

  _statusCheckTimer?.cancel();
  _statusCheckTimer = null;

  _watchdogTimer?.cancel();
  _watchdogTimer = null;

  // Deliberately NOT touching is_checked_in / work_type / last_notify_time —
  // the Attendance page already wrote the fresh values for the new session.
  // This event only tears down the OLD isolate before it dies.
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
