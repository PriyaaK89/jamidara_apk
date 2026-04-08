import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import './db_helper.dart';

class StatusService {

  //  MAIN FUNCTION (CALLED EVERY 2 MIN)
  static Future<void> sendStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final userId = prefs.getInt('employee_id');

    if (token == null || userId == null) return;

    //  STEP 1: SEND OLD FAILED STATUS FIRST (VERY IMPORTANT)
    await _resendPendingStatus(token);

    //  STEP 2: GET CURRENT STATUS
    final internetStatus = await _checkInternet();
    final locationStatus = await _checkLocation();

    try {
      final response = await ApiService.updateUserStatus(
        token: token,
        internetStatus: internetStatus,
        locationStatus: locationStatus,
      );

      //  IF API FAILS → SAVE LOCALLY
      if (response == null || response['success'] != true) {
        throw Exception("API failed");
      }

    } catch (e) {
      print("Status API failed → saving locally");

      await DBHelper.insertStatus({
        'internet_status': internetStatus,
        'location_status': locationStatus,
        'timestamp': DateTime.now().toIso8601String(),
      });
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

  //  LOCATION CHECK
  static Future<String> _checkLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    return serviceEnabled ? "ON" : "OFF";
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