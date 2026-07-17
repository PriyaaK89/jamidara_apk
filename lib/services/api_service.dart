import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/endpoints.dart';
import "../services/storage_service.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/sales_item.dart';
import '../utils/purchase_item.dart';
import '../utils/credit_note_item.dart';

class ApiService {
  // Login API
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.login}');
    debugPrint("LOGIN BASE URL: $baseUrl");
    debugPrint("LOGIN FULL URL: $url");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);
      debugPrint("response: $responseData");

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
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
    String? leaveReason,

    File? selfie,
    File? odometerImage,
    required int employeeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final url = Uri.parse('$baseUrl${Endpoints.markAttendance}');
    // final url = Uri.parse('${Env.baseUrl}${Endpoints.markAttendance}');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['employee_id'] = employeeId.toString();
    request.fields['status'] = status;

    if (workType != null) request.fields['work_type'] = workType;
    if (fieldWorkType != null)
      request.fields['field_work_type'] = fieldWorkType;
    if (travelMode != null) request.fields['travel_mode'] = travelMode;
    if (vehicleType != null) request.fields['vehicle_type'] = vehicleType;
    if (visitLocation != null && visitLocation.isNotEmpty) {
      if (status == "day_over") {
        request.fields['day_over_location'] = visitLocation;
      } else {
        request.fields['visit_location'] = visitLocation;
      }
    }
    if (leaveReason != null) {
      request.fields['leave_reason'] = leaveReason;
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
        fieldName = workType == 'office' ? 'office_selfie' : 'field_selfie';
      } else if (status == "day_over") {
        fieldName = 'day_over_selfie';
      } else {
        fieldName = 'office_selfie';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          selfie.path,
          contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
        ),
      );
    }

    if (odometerImage != null) {
      final extension = odometerImage.path.split('.').last.toLowerCase();

      String fieldName = status == "day_over"
          ? 'day_over_odometer'
          : 'odometer';

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          odometerImage.path,
          contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
        ),
      );
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
      return {"success": false, "message": response.body};
    }
  }

  static Future<Map<String, dynamic>> getTodayVisitCount(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.getTodayVisitCount}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {"success": false, "message": data['message']};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> sendLocation({
    required int employeeId,
    required String token,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.saveLocation}');

    try {
      final payload = {
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print("==== SEND LOCATION API ====");
      print("URL: $url");
      print("Payload: ${jsonEncode(payload)}");

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload), //  FIXED
          )
          .timeout(const Duration(seconds: 15));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      //  Handle response safely
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e, stack) {
      print("Send Location Error: $e");
      print("StackTrace: $stack");

      return {"success": false, "message": "Exception occurred"};
    }
  }

  // static Future<void> sendLocation({
  //   required int employeeId,
  //   required String token,
  //   required double latitude,
  //   required double longitude,
  //   required double accuracy,
  //   required double speed,
  // }) async {
  //   final url = Uri.parse('${Env.baseUrl}${Endpoints.saveLocation}');

  //   try {
  //     final payload = {
  //       'employee_id': employeeId,
  //       'latitude': latitude,
  //       'longitude': longitude,
  //       'accuracy': accuracy,
  //       'speed': speed,
  //       'timestamp': DateTime.now().toIso8601String(),
  //     };

  //     print("==== SEND LOCATION API ====");
  //     print("URL: $url");
  //     print("Payload: ${jsonEncode(payload)}");
  //     print("Token: $token");

  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode(payload),
  //     );

  //     print("Response status: ${response.statusCode}");
  //     print("Response body: ${response.body}");
  //   } catch (e, stack) {
  //     print("Send Location Error: $e");
  //     print("StackTrace: $stack");
  //   }
  // }

  // Get District by Pincode
  static Future<Map<String, dynamic>?> getDistrictByPincode(
    String pincode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final url = Uri.parse('$baseUrl${Endpoints.getDistrict}/$pincode');
    // final url = Uri.parse('${Env.baseUrl}${Endpoints.getDistrict}/$pincode');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("District API Error: $e");
    }
    return null;
  }

  // Get Areas by Pincode
  static Future<List<String>> getAreasByPincode(String pincode) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final url = Uri.parse('$baseUrl${Endpoints.getArea}?pincode=$pincode');
    // final url = Uri.parse('${Env.baseUrl}${Endpoints.getArea}?pincode=$pincode');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return List<String>.from(
          data['data'].map((item) => item['officename']),
        );
      }
    } catch (e) {
      print("Area API Error: $e");
    }
    return [];
  }

  // get emp details by id api

  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await StorageService.getToken();

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

    final url = Uri.parse(
      '$baseUrl${Endpoints.getProfile}/${await StorageService.getEmployeeId()}',
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    print("📡 STATUS CODE: ${response.statusCode}");
    print("📦 BODY: ${response.body}");

    return null;
  }

  // Get Customers
  static Future<List<Map<String, dynamic>>> getCustomers(String type) async {
    final token = await StorageService.getToken();

    // final url = Uri.parse('${Env.baseUrl}${Endpoints.getCustomers}?type=$type');

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    //  final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final url = Uri.parse('$baseUrl${Endpoints.getCustomers}?type=$type');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GET CUSTOMERS URL: $url");
      print("GET CUSTOMERS STATUS: ${response.statusCode}");
      print("GET CUSTOMERS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print("Get Customers Error: $e");
    }

    return [];
  }

  // Get Customer Details
  static Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final token = await StorageService.getToken();
    // final url = Uri.parse('${Env.baseUrl}${Endpoints.getCustomerById}/$id');

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    //  final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final url = Uri.parse('$baseUrl${Endpoints.getCustomerById}/$id');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Customer Details Error: $e");
    }

    return null;
  }

  static Future<Map<String, dynamic>> uploadVisit({
    required String visitType,
    required String customerType,
    int? customerId,
    required String name,
    required String firm_name,
    required String firm_address,
    required String contactNumber,
    required String address,
    required String district,
    required String visitPurpose,
    required String comment,
    String? reminderDate,
    required String pincode,
    required String area,
    File? image,
  }) async {
    try {
      final token = await StorageService.getToken();
      final employeeId = await StorageService.getEmployeeId();

      // final url = Uri.parse('${Env.baseUrl}${Endpoints.uploadEmpVisit}');

      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

      // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
      final url = Uri.parse('$baseUrl${Endpoints.uploadEmpVisit}');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['user_id'] = employeeId.toString();
      request.fields['visit_type'] = visitType.toLowerCase();

      final isExisting = customerType == "Old Customer";

      //  Set customer type ONLY ONCE
      request.fields['customer_type'] = isExisting ? "old" : "new";

      //  Send customer_id only for old customer
      if (isExisting) {
        if (customerId == null) {
          throw Exception("Customer ID missing for old customer");
        }

        request.fields['customer_id'] = customerId.toString();
      }
      request.fields['name'] = name;
      request.fields['firm_name'] = firm_name;
      request.fields['firm_address'] = firm_address;
      request.fields['contact_number'] = contactNumber;
      request.fields['address'] = address;
      request.fields['district'] = district;
      request.fields['visit_purpose'] = visitPurpose;
      request.fields['comment'] = comment;
      // request.fields['reminder_date'] = reminderDate;
      if (reminderDate != null && reminderDate.trim().isNotEmpty) {
        request.fields['reminder_date'] = reminderDate;
      }
      request.fields['pincode'] = pincode;
      request.fields['area'] = area;

      // Image
      if (image != null) {
        final extension = image.path.split('.').last.toLowerCase();

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: MediaType(
              'image',
              extension == 'png' ? 'png' : 'jpeg',
            ),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final decoded = jsonDecode(response.body);

      return {
        "success": response.statusCode == 200 || response.statusCode == 201,
        "message": decoded["message"] ?? "Something went wrong",
        "data": decoded["data"],
      };
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

  static Future<Map<String, dynamic>> uploadExpense({
    required String expenseType,
    required String expenseDate,
    required String amount,
    required String remarks,
    required File billFile,
  }) async {
    try {
      final token = await StorageService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

      final url = Uri.parse('$baseUrl${Endpoints.uploadExpenses}');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['expense_type'] = expenseType;
      request.fields['expense_date'] = expenseDate;
      request.fields['amount'] = amount;
      request.fields['remarks'] = remarks;

      request.files.add(
        await http.MultipartFile.fromPath(
          'bill',
          billFile.path,
          contentType: MediaType('image', 'png'),
        ),
      );

      //  ADD TIMEOUT HERE
      var response = await request.send().timeout(const Duration(seconds: 15));

      var responseData = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $responseData");

      Map<String, dynamic> decoded;

      try {
        decoded = jsonDecode(responseData);
      } catch (e) {
        //  HANDLE NON-JSON RESPONSE
        return {"success": false, "message": "Server error (Invalid response)"};
      }

      return {
        "success": response.statusCode == 200 || response.statusCode == 201,
        "message": decoded["message"] ?? "Something went wrong",
        "data": decoded["data"],
      };
    } catch (e) {
      print("API ERROR: $e");

      return {"success": false, "message": "Network/Server error"};
    }
  }

  static Future<Map<String, dynamic>> getMyVisits({
    int page = 1,
    int limit = 10,
    String? visitType,
    String? district,
    String? fromDate,
    String? toDate,
    String? search,
  }) async {
    final token = await StorageService.getToken();

    final queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      if (visitType != null && visitType.isNotEmpty) "visit_type": visitType,
      if (district != null && district.isNotEmpty) "district": district,
      if (fromDate != null && fromDate.isNotEmpty) "from_date": fromDate,
      if (toDate != null && toDate.isNotEmpty) "to_date": toDate,
      if (search != null && search.isNotEmpty) "search": search,
    };

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final uri = Uri.parse(
      '$baseUrl${Endpoints.getVisitReport}',
    ).replace(queryParameters: queryParams);

    // final uri = Uri.parse('${Env.baseUrl}${Endpoints.getVisitReport}')
    //     .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {"success": false, "message": data["error"]};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAttendanceReport({
    required int page,
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    final token = await StorageService.getToken();

    final queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      "start_date": startDate ?? "",
      "end_date": endDate ?? "",
    };

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final uri = Uri.parse(
      '$baseUrl${Endpoints.getAttendanceReport}',
    ).replace(queryParameters: queryParams);
    // final uri = Uri.parse('${Env.baseUrl}${Endpoints.getAttendanceReport}')
    //     .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to fetch attendance",
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSalaryReport({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    final token = await StorageService.getToken();

    final queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      if (startDate != null && startDate.isNotEmpty) "startDate": startDate,
      if (endDate != null && endDate.isNotEmpty) "endDate": endDate,
    };

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final uri = Uri.parse(
      '$baseUrl${Endpoints.getSalaryReport}',
    ).replace(queryParameters: queryParams);
    // final uri = Uri.parse('${Env.baseUrl}${Endpoints.getSalaryReport}')
    //     .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {"success": false, "message": data["message"] ?? "Failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();

    final targetPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
      format: CompressFormat.jpeg,
    );

    ///  FIX: convert XFile → File
    if (compressed != null) {
      return File(compressed.path);
    }

    return file; // fallback
  }

  static Future<Map<String, dynamic>> createDistributor({
    required String token,
    required Map<String, dynamic> data,
    // List<Map<String, dynamic>> partners = const [],
    List<Map<String, dynamic>>? partners,
    List<Map<String, dynamic>> companies = const [],
    // Map<String, File?> files = const {},
    Map<String, dynamic> files = const {},
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

    final url = Uri.parse('$baseUrl${Endpoints.createOnBoardingOfDistributor}');

    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';

    ///  1. ADD NORMAL FIELDS
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    ///  2. ADD JSON FIELDS

    if (partners != null && partners.isNotEmpty) {
      request.fields['partners'] = jsonEncode(partners);
    }

    if (companies.isNotEmpty) {
      request.fields['other_companies'] = jsonEncode(companies);
    }

    ///  3. ADD FILES
    bool isImage(String path) {
      final ext = path.split('.').last.toLowerCase();
      return ['jpg', 'jpeg', 'png'].contains(ext);
    }

    for (var entry in files.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) continue;

      /// 🔹 SINGLE FILE
      if (value is File) {
        File finalFile = value;

        if (isImage(value.path)) {
          finalFile = await compressImage(value); //  compress only images
        }

        request.files.add(
          await http.MultipartFile.fromPath(key, finalFile.path),
        );
      }
      /// 🔹 MULTIPLE FILES
      else if (value is List<File>) {
        for (var file in value) {
          File finalFile = file;

          if (isImage(file.path)) {
            finalFile = await compressImage(file); //  compress only images
          }

          request.files.add(
            await http.MultipartFile.fromPath(key, finalFile.path),
          );
        }
      }
    }

    print("FIELDS: ${request.fields}");
    print("FILES: ${request.files.map((e) => e.field).toList()}");

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return {"success": false, "message": response.body};
    }
  }

  static Future<Map<String, dynamic>> verifyGST(String gstNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

    final url = Uri.parse('$baseUrl${Endpoints.verifyGST}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"gst_number": gstNumber}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "GST verification failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<dynamic> updateUserStatus({
    required String token,
    required String internetStatus,
    required String locationStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL');

    final response = await http.post(
      Uri.parse('$baseUrl${Endpoints.updateUserStatus}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "internet_status": internetStatus,
        "location_status": locationStatus,
      }),
    );

    //  HANDLE 403 HERE
    if (response.statusCode == 403) {
      return {
        "forceLogout": true,
        "message": jsonDecode(response.body)['message'],
      };
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("API failed with status ${response.statusCode}");
  }

  // Initiate Aadhaar KYC
  static Future<Map<String, dynamic>> sendForAadharKYC({
    required String mobile,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.sendForAadharKYC}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'mobile': mobile}),
      );
      final responseData = jsonDecode(response.body);
      debugPrint("KYC INITIATE RESPONSE: $responseData");

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'KYC initiation failed',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  // Poll KYC status and get details
  static Future<Map<String, dynamic>> getDetailsFromAadhar({
    required String kid,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse(
      '$baseUrl${Endpoints.getDetailsFromAadhar}/$kid/response',
    );

    try {
      final response = await http.post(
        // ← was http.get, must be POST
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}), // ← empty body required
      );
      final responseData = jsonDecode(response.body);
      debugPrint("KYC STATUS RESPONSE: $responseData");

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Failed to get KYC details',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  static Future<Map<String, dynamic>> getMyProfile(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.getMe}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateMyProfile(
    String token,
    File imageFile,
  ) async {
    final pref = await SharedPreferences.getInstance();
    final baseUrl = pref.getString("FLUTTER_BASE_URL") ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.updateProfileImage}');

    try {
      var request = http.MultipartRequest('PUT', url);

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image', //  key name
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {
          "success": false,
          "message": data['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

  // CREATE TARGET
  static Future<Map<String, dynamic>> createTarget(Map body) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final token = await StorageService.getToken();
    final url = Uri.parse('$baseUrl${Endpoints.createTarget}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  // GET MY TARGETS
  static Future<List<dynamic>> getMyTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final token = await StorageService.getToken();
    final url = Uri.parse('$baseUrl${Endpoints.myTargets}');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getMyTeam(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

      final url = Uri.parse('$baseUrl${Endpoints.getMyTeam}');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      }

      return {"success": false, "message": data["message"] ?? "Failed"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTodayAttendance(
    int employeeId,
    String token,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

      final url = Uri.parse('$baseUrl/today-attendance/$employeeId');

      debugPrint("TODAY ATTENDANCE URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      debugPrint("TODAY ATTENDANCE RESPONSE: $responseData");

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Failed to fetch attendance',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  static Future<Map<String, dynamic>> createSalesApprovalRequest({
    required int ledgerId,
    required bool isConsignee,
    required bool isSupercash,
    required String narration,

    String? dealerName,
    String? proprietorName,
    String? consigneeContactNo,
    String? consigneeAddress,
    String? consigneeGstnNo,

    required double subtotal,
    required double taxTotal,
    required double totalAmount,

    required List<SalesItem> items,

    required File orderBillImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
      final token = await StorageService.getToken();

      var request = http.MultipartRequest( "POST", Uri.parse("$baseUrl${Endpoints.createSalesApprovalRequest}"),);

      request.headers.addAll({"Authorization": "Bearer $token"});

      final payload = {
        "customer_ledger_id": ledgerId,
        "is_consignee": isConsignee ? 1 : 0,
        "dealer_name": dealerName ?? "",
        "proprietor_name": proprietorName ?? "",
        "consignee_contact_no": consigneeContactNo ?? "",
        "consignee_address": consigneeAddress ?? "",
        "consignee_gstn_no": consigneeGstnNo ?? "",

        "is_supercash_sale": isSupercash ? 1 : 0,

        "subtotal": subtotal,
        "tax_total": taxTotal,
        "total_amount": totalAmount,

        "narration": narration,

        "items": items.map((e) => e.toJson()).toList(),
      };

      payload.forEach((key, value) {
        request.fields[key] = jsonEncode(value);
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          "orderBillImage",
          orderBillImage.path,
        ),
      );

      final response = await request.send();

      final body = await response.stream.bytesToString();

      return jsonDecode(body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStockItemById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";

      final token = await StorageService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl${Endpoints.getStockItemDetailsById}/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<List<dynamic>> getStockItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";

      final token = await StorageService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl${Endpoints.getStockItemsList}"),
        headers: {"Authorization": "Bearer $token"},
      );

      final json = jsonDecode(response.body);

      return json["data"] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMyAssignedLedgers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
    final token = await StorageService.getToken();
    final response = await http.get( Uri.parse( "$baseUrl${Endpoints.getMyAssignedLedgers}", ),
      headers: { "Authorization": "Bearer $token", },
    );

    final json = jsonDecode(response.body);

    if (json["success"] == true) {
      return json["data"] ?? [];
    }

    return [];
  } catch (e) {
    debugPrint(e.toString());
    return [];
  }
}

/// Current active target + progress breakdown for one employee
static Future<Map<String, dynamic>> getEmployeeVisitProgress(
  String token,
  int employeeId,
) async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
  final url = Uri.parse(
    '$baseUrl${Endpoints.getEmployeeVisitProgress}/$employeeId',
  );

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseData;
    } else {
      return {
        "success": false,
        "message": responseData['message'] ?? 'Failed to fetch progress',
      };
    }
  } catch (e) {
    return {"success": false, "message": "Exception occurred: $e"};
  }
}

/// Past (COMPLETED/EXPIRED) periods for one employee
static Future<Map<String, dynamic>> getEmployeeVisitTargetHistory(
  String token,
  int employeeId, {
  String? status,
  int page = 1,
  int limit = 10,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

  final queryParams = {
    'employee_id': employeeId.toString(),
    'page': page.toString(),
    'limit': limit.toString(),
    if (status != null) 'status': status,
  };

  final url = Uri.parse(
    '$baseUrl${Endpoints.getVisitTargetHistory}',
  ).replace(queryParameters: queryParams);

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseData;
    } else {
      return {
        "success": false,
        "message": responseData['message'] ?? 'Failed to fetch history',
      };
    }
  } catch (e) {
    return {"success": false, "message": "Exception occurred: $e"};
  }
}

// Get Notifications
  static Future<Map<String, dynamic>> getNotifications(
    String token, {
    String? moduleType,
    String? notificationCategory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';

    final queryParams = <String, String>{};
    if (moduleType != null && moduleType.isNotEmpty) {
      queryParams['module_type'] = moduleType;
    }
    if (notificationCategory != null && notificationCategory.isNotEmpty) {
      queryParams['notification_category'] = notificationCategory;
    }

    final url = Uri.parse('$baseUrl${Endpoints.getNotification}')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // adjust if your other calls use a different scheme
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Failed to fetch notifications',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  // Get Notification Counts
  static Future<Map<String, dynamic>> getNotificationCounts(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.getNotificationsCount}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Failed to fetch notification counts',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  // Mark Notifications Read
  // Mark Notifications Read (pass ids for specific ones, omit to mark all)
  static Future<Map<String, dynamic>> markNotificationsRead(
    String token, {
    List<int>? notificationIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
    final url = Uri.parse('$baseUrl${Endpoints.markNotificationsRead}');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (notificationIds != null && notificationIds.isNotEmpty)
            'notification_ids': notificationIds,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Failed to mark notification read',
        };
      }
    } catch (e) {
      return {"success": false, "message": "Exception occurred: $e"};
    }
  }

  // ── Receipt Approval Request: dropdowns ──────────────────────────────

static Future<Map<String, dynamic>> getBankAccountLedgerDropdown() async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
  final token = await StorageService.getToken();
  final url = Uri.parse('$baseUrl${Endpoints.getBankAccountLedgerDropdown}');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {"success": false, "message": "Exception occurred: $e"};
  }
}

static Future<Map<String, dynamic>> getLedgerDetailsById(String ledgerId) async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
  final token = await StorageService.getToken();
  final url = Uri.parse('$baseUrl${Endpoints.getLedgerDetailsByID}/$ledgerId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {"success": false, "message": "Exception occurred: $e"};
  }
}

// ── Receipt Approval Request: submit ─────────────────────────────────

static Future<Map<String, dynamic>> createReceiptApprovalRequest({
  required String accountLedgerId,
  required String receiptDate,
  String? employeeUnderId,
  required String narration,
  required double totalAmount,
  required List<Map<String, dynamic>> entries,
  required File attachment,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
  final token = await StorageService.getToken();
  final url = Uri.parse('$baseUrl${Endpoints.createReceiptRequest}');

  try {
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['account_ledger_id'] = accountLedgerId;
    request.fields['receipt_date'] = receiptDate;
    request.fields['narration'] = narration;
    request.fields['total_amount'] = totalAmount.toString();
    if (employeeUnderId != null && employeeUnderId.isNotEmpty) {
      request.fields['employee_under_id'] = employeeUnderId;
    }
    request.fields['entries'] = jsonEncode(entries);

    request.files.add(
      await http.MultipartFile.fromPath(
        'attachment',
        attachment.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body);
  } catch (e) {
    return {"success": false, "message": "Exception occurred: $e"};
  }
}

static Future<Map<String, dynamic>> createPurchaseApprovalRequest({
    required int supplierLedgerId,
    required int purchaseLedgerId,
    required String supplierInvoiceNo,
    required String narration,

    required double subtotal,
    required double igstTotal,
    required double cgstTotal,
    required double sgstTotal,
    required double totalAmount,
    required String taxMode,

    required List<PurchaseItem> items,

    required File orderBillImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
      final token = await StorageService.getToken();

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl${Endpoints.createPurchaseApprovalRequest}"),
      );

      request.headers.addAll({"Authorization": "Bearer $token"});

      final payload = {
        "supplier_ledger_id": supplierLedgerId,
        "purchase_ledger_id": purchaseLedgerId,
        "supplier_invoice_no": supplierInvoiceNo,

        "subtotal": subtotal,
        "igst_total": igstTotal,
        "cgst_total": cgstTotal,
        "sgst_total": sgstTotal,
        "total_amount": totalAmount,
        "tax_mode": taxMode,

        "narration": narration,

        "items": items.map((e) => e.toJson()).toList(),
      };

      payload.forEach((key, value) {
        request.fields[key] = jsonEncode(value);
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          "orderBillImage",
          orderBillImage.path,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      return jsonDecode(body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ── Credit Note: Party sales history (Option A) ─────────────────────────
static Future<List<dynamic>> getSalesByCustomer(int customerLedgerId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
    final token = await StorageService.getToken();

    final url = Uri.parse(
      "$baseUrl${Endpoints.getSalesByCustomer}?customer_ledger_id=$customerLedgerId",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);
    if (data["success"] == true) {
      return data["data"] ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getSalesByCustomer error: $e");
    return [];
  }
}

static Future<List<dynamic>> getSaleItemsById(int saleId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
    final token = await StorageService.getToken();

    final url = Uri.parse(
      "$baseUrl${Endpoints.getSaleItemsById}/$saleId/items",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);
    if (data["success"] == true) {
      return data["data"] ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getSaleItemsById error: $e");
    return [];
  }
}

static Future<List<dynamic>> getSalesBillReferences(int saleId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
    final token = await StorageService.getToken();

    final url = Uri.parse(
      "$baseUrl${Endpoints.getSalesBillReferences}?sale_id=$saleId",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);
    if (data["success"] == true) {
      return data["data"] ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getSalesBillReferences error: $e");
    return [];
  }
}

// ── Sales Return ledger dropdown ─────────────────────────────────────────
static Future<List<dynamic>> getSalesReturnLedgers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
    final token = await StorageService.getToken();

    final url = Uri.parse("$baseUrl${Endpoints.getSalesReturnLedgers}");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);
    if (data["success"] == true) {
      return data["data"] ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getSalesReturnLedgers error: $e");
    return [];
  }
}

// ── Submit Credit Note Approval Request ──────────────────────────────────
static Future<Map<String, dynamic>> createCreditNoteApprovalRequest({
  required int customerLedgerId,
  required String creditNoteDate,
  int? originalSaleId, // null in manual mode
  required int salesReturnLedgerId,
  required bool isConsignee,
  String? dealerName,
  String? proprietorName,
  String? consigneeContactNo,
  String? consigneeAddress,
  String? consigneeGstnNo,

  required double subtotal,
  required double igstTotal,
  required double cgstTotal,
  required double sgstTotal,
  required double taxTotal,
  required double totalAmount,

  required String narration,
  required List<CreditNoteItem> items,
  required List<Map<String, dynamic>> billReferences,

  File? billTImage,
  File? dispatchDocImage,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString("FLUTTER_BASE_URL") ?? "";
    final token = await StorageService.getToken();

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl${Endpoints.createCreditNoteApprovalRequest}"),
    );

    request.headers.addAll({"Authorization": "Bearer $token"});

    final payload = {
      "customer_ledger_id": customerLedgerId,
      "credit_note_date": creditNoteDate,
      "original_sale_id": originalSaleId,
      "sales_return_ledger_id": salesReturnLedgerId,
      "is_consignee": isConsignee,
      "dealer_name": dealerName ?? "",
      "proprietor_name": proprietorName ?? "",
      "consignee_contact_no": consigneeContactNo ?? "",
      "consignee_address": consigneeAddress ?? "",
      "consignee_gstn_no": consigneeGstnNo ?? "",

      "subtotal": subtotal,
      "igst_total": igstTotal,
      "cgst_total": cgstTotal,
      "sgst_total": sgstTotal,
      "tax_total": taxTotal,
      "total_amount": totalAmount,
      "narration": narration,

      "items": items.map((e) => e.toJson()).toList(),
      "bill_references": billReferences,
    };

    payload.forEach((key, value) {
      request.fields[key] = jsonEncode(value);
    });

    if (billTImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("bill_t_image", billTImage.path),
      );
    }

    if (dispatchDocImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "dispatch_doc_image",
          dispatchDocImage.path,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body);
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }
}
}
