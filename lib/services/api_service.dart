import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/env.dart';
import '../utils/endpoints.dart';

class ApiService {
  // Login API
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${Env.baseUrl}${Endpoints.login}');

    print('=== Login API Request ===');
    print('URL: $url');
    print('Headers: {"Content-Type": "application/json"}');
    print('Body: ${jsonEncode({"email": email, "password": password})}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('=== Login API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
      "success": false,
      "message": responseData['message'] ?? 'Login failed',
          "body": response.body
        };
      }
    } catch (e, stackTrace) {
      print('Login API Exception: $e');
      print('Stack Trace: $stackTrace');
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  // Mark Attendance API
 static Future<Map<String, dynamic>> markAttendance({
  required String status,
  required String token,
  String? workType,
  String? fieldWorkType,
  String? travelMode,
  String? vehicleType,
  String? odometerReading,
  String? visitLocation,
  File? selfie,
  File? odometerImage,
  required int employeeId,
}) async {
  final url = Uri.parse('${Env.baseUrl}${Endpoints.markAttendance}');
  final request = http.MultipartRequest('POST', url);

  request.headers['Authorization'] = 'Bearer $token';

  request.fields['employee_id'] = employeeId.toString();
  request.fields['status'] = status;

  if (workType != null) request.fields['work_type'] = workType;
  if (fieldWorkType != null) request.fields['field_work_type'] = fieldWorkType;
  if (travelMode != null) request.fields['travel_mode'] = travelMode;
  if (vehicleType != null) request.fields['vehicle_type'] = vehicleType;
 if (visitLocation != null && visitLocation.isNotEmpty) {
  if (status == "day_over") {
    request.fields['day_over_location'] = visitLocation;
  } else {
    request.fields['visit_location'] = visitLocation;
  }
}

  //  DO NOT SEND EMPTY ODOMETER
 if (odometerReading != null && odometerReading.isNotEmpty) {
  if (status == "day_over") {
    request.fields['day_over_odometer_reading'] = odometerReading;
  } else {
    request.fields['odometer_reading'] = odometerReading;
  }
}


  if (selfie != null) {
    final extension = selfie.path.split('.').last.toLowerCase();

    String fieldName;

    if (status == "present") {
      fieldName =
          workType == 'office' ? 'office_selfie' : 'field_selfie';
    } else if (status == "day_over") {
      fieldName = 'day_over_selfie';
    } else {
      fieldName = 'office_selfie';
    }

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      selfie.path,
      contentType:
          MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
    ));
  }

  if (odometerImage != null) {
    final extension = odometerImage.path.split('.').last.toLowerCase();

    String fieldName =
        status == "day_over" ? 'day_over_odometer' : 'odometer';

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      odometerImage.path,
      contentType:
          MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
    ));
  }

  print('Fields: ${request.fields}');
  print('Files: ${request.files.map((f) => f.field).toList()}');

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  print('Status Code: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {
      "success": false,
      "message": response.body,
    };
  }
}

static Future<void> sendLocation({
  required int employeeId,
  required String token,
  required double latitude,
  required double longitude,
  required double accuracy,
  required double speed,
}) async {
  final url = Uri.parse('${Env.baseUrl}${Endpoints.saveLocation}');

  try {
    final payload = {
      'employee_id': employeeId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print("=== SEND LOCATION API REQUEST ===");
    print("URL: $url");
    print("Headers: {Content-Type: application/json, Authorization: Bearer $token}");
    print("Payload: ${jsonEncode(payload)}");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    print("=== SEND LOCATION API RESPONSE ===");
    print("Status Code: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Location save failed: ${response.body}");
    }
  } catch (e, stack) {
    print("Send Location Error: $e");
    print("StackTrace: $stack");
  }
}
}