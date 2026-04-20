import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import './db_helper.dart';

class StatusService {

  //  MAIN FUNCTION (CALLED EVERY 2 MIN)
 static Future<bool> sendStatus({String? locationOverride}) async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString('token');
  final userId = prefs.getInt('employee_id');

  if (token == null || userId == null) return false;

  await _resendPendingStatus(token);

  final internetStatus = await _checkInternet();
  final locationStatus = locationOverride ?? await _checkLocation();

  final lastInternet = prefs.getString("last_internet_status");
  final lastLocation = prefs.getString("last_location_status");

  if (lastInternet == internetStatus &&
      lastLocation == locationStatus &&
      locationOverride == null) {
    print("Status unchanged → skipping API");
    return false;
  }

  try {
    final response = await ApiService.updateUserStatus(
      token: token,
      internetStatus: internetStatus,
      locationStatus: locationStatus,
    );

    //  JUST RETURN TRUE (DO NOT LOGOUT HERE)
    if (response != null && response["forceLogout"] == true) {
      print(" Force logout triggered");
      return true;
    }

    if (response == null || response['success'] != true) {
      throw Exception("API failed");
    }

    await prefs.setString("last_internet_status", internetStatus);
    await prefs.setString("last_location_status", locationStatus);

    print("STATUS SENT SUCCESS");
    return false;

  } catch (e) {
    print("Status API failed → saving locally");

    await DBHelper.insertStatus({
      'internet_status': internetStatus,
      'location_status': locationStatus,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return false;
  }
}
  //  INTERNET CHECK
static Future<String> _checkInternet() async {
  final connectivity = await Connectivity().checkConnectivity();

  if (connectivity == ConnectivityResult.none) {
    return "OFFLINE";
  }

  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return "ONLINE";
    }
  } catch (_) {
    return "OFFLINE";
  }

  return "OFFLINE";
}

static Future<String> _checkLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "OFF";

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return "OFF";
    }

    //  FAST + BATTERY FRIENDLY
    final position = await Geolocator.getLastKnownPosition();

    if (position != null) return "ON";

    return "OFF";
  } catch (e) {
    return "OFF";
  }
}

  //  RESEND FAILED STATUS (CRITICAL FIX)
  static Future<void> _resendPendingStatus(String token) async {
    final statuses = await DBHelper.getStatusLogs();

    if (statuses.isEmpty) return;

    print("Resending ${statuses.length} pending status logs");

    for (var status in statuses) {
      try {
        final response = await ApiService.updateUserStatus(
          token: token,
          internetStatus: status['internet_status'],
          locationStatus: status['location_status'],
        );

        if (response != null && response['success'] == true) {
          await DBHelper.deleteStatus(status['id']); // delete after success
        }
      } catch (e) {
        print("Pending status resend failed: $e");
        break; // stop loop if internet fails again
      }
    }
  }
}