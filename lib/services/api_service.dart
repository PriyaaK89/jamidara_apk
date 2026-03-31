import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/endpoints.dart';
import "../services/storage_service.dart";
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // Login API
 static Future<Map<String, dynamic>> login(String email, String password) async {
  // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;

  final prefs = await SharedPreferences.getInstance();
final baseUrl = prefs.getString('FLUTTER_BASE_URL') ?? '';
  final url = Uri.parse('$baseUrl${Endpoints.login}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          "success": false,
          "message": responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Exception occurred: $e",
      };
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
    // final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
  final url = Uri.parse('$baseUrl${Endpoints.saveLocation}');
  // final url = Uri.parse('${Env.baseUrl}${Endpoints.saveLocation}');

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

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload), //  FIXED
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    //  Handle response safely
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": "Server error: ${response.statusCode}"
      };
    }

  } catch (e, stack) {
    print("Send Location Error: $e");
    print("StackTrace: $stack");

    return {
      "success": false,
      "message": "Exception occurred"
    };
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
static Future<Map<String, dynamic>?> getDistrictByPincode(String pincode) async {

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

    print("GET CUSTOMER DETAILS URL: $url");
    print("GET CUSTOMER DETAILS STATUS: ${response.statusCode}");
    print("GET CUSTOMER DETAILS BODY: ${response.body}");

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
      "data": decoded["data"]
    };

  } catch (e) {
    return {
      "success": false,
      "message": "Exception: $e",
    };
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
// final baseUrl = dotenv.env['FLUTTER_BASE_URL']!;
    final url = Uri.parse('$baseUrl${Endpoints.uploadExpenses}');
      final request = http.MultipartRequest('POST', url);

    // var request = http.MultipartRequest(
    //   'POST',
    //   Uri.parse('${Env.baseUrl}/upload-my-expense'),
      
    // );

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

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    print("Response: $responseData");
    print("Status Code: ${response.statusCode}");

    final decoded = jsonDecode(responseData);

    return {
      "success": response.statusCode == 200 || response.statusCode == 201,
      "message": decoded["message"] ?? "Something went wrong",
      "data": decoded["data"]
    };
  } catch (e) {
    return {
      "success": false,
      "message": "Exception: $e"
    };
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
    final uri = Uri.parse('$baseUrl${Endpoints.getVisitReport}')
    .replace(queryParameters: queryParams);

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
    final uri = Uri.parse('$baseUrl${Endpoints.getAttendanceReport}')
    .replace(queryParameters: queryParams);
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
    return {
      "success": false,
      "message": e.toString(),
    };
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
    final uri = Uri.parse('$baseUrl${Endpoints.getSalaryReport}')
    .replace(queryParameters: queryParams);
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
      return {
        "success": false,
        "message": data["message"] ?? "Failed",
      };
    }
  } catch (e) {
    return {
      "success": false,
      "message": "Error: $e",
    };
  }
}

}