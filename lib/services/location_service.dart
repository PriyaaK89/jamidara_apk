import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> checkLocation(BuildContext context) async {
    // Check GPS ON/OFF
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable GPS to continue")),
      );

      await Geolocator.openLocationSettings();
      return false;
    }

    // Check permission
    PermissionStatus permission = await Permission.locationWhenInUse.status;

    if (!permission.isGranted) {
      permission = await Permission.locationWhenInUse.request();
    }

    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required")),
      );
      return false;
    }

    return true;
  }
}