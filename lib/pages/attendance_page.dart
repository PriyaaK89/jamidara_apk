import 'dart:io';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/option_button.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AttendancePage extends StatefulWidget {
  final int employeeId;
  final String token;

  const AttendancePage({
    super.key,
    required this.employeeId,
    required this.token,
  });
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _formKey = GlobalKey<FormState>();

  String? attendanceType;
  String? workType;
  String? workingArea;
  String? travelMode;
  String? vehicleType;
  String? visitLocation;
  String odometerReading = '';
  String? currentLocation;


  File? selfieImage;
  File? odometerImage;

  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

 Future<Position> getSafeCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception("Location services are disabled.");
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Location permission permanently denied");
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.bestForNavigation,
    timeLimit: const Duration(seconds: 15),
  );
}

Future<String> getAddressFromGoogle(double lat, double lng) async {
  final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  final url =
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey";

  final response = await http.get(Uri.parse(url));

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 &&
      data['status'] == 'OK' &&
      data['results'].isNotEmpty) {
    return data['results'][0]['formatted_address'];
  } else {
    throw Exception("Google API failed: ${data['status']}");
  }
}

Future<String> getFullLocationDetails() async {
  Position position = await getSafeCurrentLocation();

  String formattedDate =
      DateFormat('dd-MM-yyyy').format(DateTime.now());
  String formattedTime =
      DateFormat('hh:mm a').format(DateTime.now());

  String dateTimeLine = "Date: $formattedDate  Time: $formattedTime";

  String addressLine = "";

  try {
    //  Try Google API first
    addressLine = await getAddressFromGoogle(
      position.latitude,
      position.longitude,
    );
  } catch (e) {
    print("Google API Error: $e");
    //  Fallback to placemark
    List<Placemark> placemarks =
        await placemarkFromCoordinates(
            position.latitude, position.longitude);

    Placemark place = placemarks.first;

    addressLine = [
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.postalCode,
      place.country
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  String latLongLine =
      "Lat: ${position.latitude}, Long: ${position.longitude}";

  return "$dateTimeLine\n\n$addressLine\n\n$latLongLine";
}

Future<File?> addLocationStamp(File file) async {
  final details = await getFullLocationDetails();

  final bytes = await file.readAsBytes();
  img.Image? originalImage = img.decodeImage(bytes);
  if (originalImage == null) return null;

  // Load logo from assets
  final logoBytes =
      await rootBundle.load('assets/images/logo.png');
  final logoImage =
      img.decodeImage(logoBytes.buffer.asUint8List());

  // Split lines
  List<String> lines = details.split("\n");

  int padding = 20;
  int boxHeight = (lines.length * 60) + 40;
  int startY = originalImage.height - boxHeight - 40;

  img.fillRect(
    originalImage,
    x1: 0,
    y1: startY - 20,
    x2: originalImage.width,
    y2: originalImage.height,
    color: img.ColorRgba8(0, 0, 0, 200),
  );

final font = originalImage.width > 2000
    ? img.arial48
    : img.arial24;
  // Draw text
  for (int i = 0; i < lines.length; i++) {
    img.drawString(
      originalImage,
      lines[i],
      font: font,
      x: padding,
    y: startY + (i * 50),
      color: img.ColorRgb8(255, 255, 255),
    );
  }

if (logoImage != null) {
  // Resize logo properly
  final resizedLogo = img.copyResize(
    logoImage,
    width: originalImage.width ~/ 3, // dynamic width
  );

  img.compositeImage(
    originalImage,
    resizedLogo,
    dstX: originalImage.width - resizedLogo.width - 20,
    dstY: 20,
  );
}

    final dir = await getApplicationDocumentsDirectory();
final newPath =
    '${dir.path}/stamped_${DateTime.now().millisecondsSinceEpoch}.jpg';

final newFile = File(newPath)
  ..writeAsBytesSync(img.encodeJpg(originalImage, quality: 90));

  return newFile;
}

  bool isFormValid() {
    if (attendanceType == null) return false;

    if (attendanceType == 'present' || attendanceType == 'day_over') {
      if (workType == null) return false;

      if (attendanceType == 'present' && workType == 'field') {
        if (workingArea == null ||
            travelMode == null ||
            selfieImage == null ||
            visitLocation == null)
          return false;

        if (travelMode == 'private') {
          if (vehicleType == null ||
              odometerReading.isEmpty ||
              odometerImage == null)
            return false;
        }
      }

      if ((workType == 'office' && selfieImage == null)) return false;

      if (attendanceType == 'day_over') {
  if (selfieImage == null) return false;
}
    }
    return true;
  }

  Future<File?> compressImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
      minWidth: 1080,
      minHeight: 1080,
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }

Future<void> pickImage(String type) async {
  final XFile? pickedFile = await _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 50,
  );

  if (pickedFile != null) {
    File imageFile = File(pickedFile.path);
    setState(() {
      if (type == 'selfie') {
        selfieImage = imageFile;
      } else {
        odometerImage = imageFile;
      }
    });
  }
}
 Future<void> handleSubmit() async {
  if (!isFormValid()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  final submittedAttendanceType = attendanceType;   // <-- save first
  final submittedWorkType = workType;
  final submittedWorkingArea = workingArea;
  final submittedTravelMode = travelMode;
  final submittedVehicleType = vehicleType;
  final submittedVisitLocation = visitLocation;
  final submittedOdometerReading =
      odometerReading.isNotEmpty ? odometerReading : null;

  try {
    File? stampedSelfie;
    File? stampedOdometer;


    if (submittedAttendanceType == "day_over") {
  try {
    currentLocation = await getFullLocationDetails();
  } catch (e) {
    Flushbar(
      message: "Unable to fetch location. Please enable GPS.",
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.BOTTOM, //  bottom position
      backgroundColor: Colors.red,
      margin: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(8),
      icon: const Icon(Icons.location_off, color: Colors.white),
    ).show(context);

    setState(() => isLoading = false);
    return;
  }
}

    if (selfieImage != null) {
      stampedSelfie = await addLocationStamp(selfieImage!);
    }

    if (odometerImage != null) {
      stampedOdometer = await addLocationStamp(odometerImage!);
    }

    final compressedSelfie =
        stampedSelfie != null ? await compressImage(stampedSelfie) : null;
    final compressedOdometer =
        stampedOdometer != null ? await compressImage(stampedOdometer) : null;

    final response = await ApiService.markAttendance(
      employeeId: widget.employeeId,
      token: widget.token,
      status: submittedAttendanceType!,
      workType: submittedWorkType,
      fieldWorkType: submittedWorkingArea,
      travelMode: submittedTravelMode,
      vehicleType: submittedVehicleType,
      visitLocation: submittedAttendanceType == "day_over"
          ? currentLocation
          : submittedVisitLocation,
      odometerReading: submittedOdometerReading,
      selfie: compressedSelfie ?? stampedSelfie ?? selfieImage,
      odometerImage: compressedOdometer ?? stampedOdometer ?? odometerImage,
    );

  Flushbar(
  message: response['message'] ?? 'Attendance submitted',
  duration: const Duration(seconds: 2),
  flushbarPosition: FlushbarPosition.BOTTOM,
  backgroundColor: Colors.green,
  margin: const EdgeInsets.all(20),
  borderRadius: BorderRadius.circular(8),
  icon: const Icon(Icons.check_circle, color: Colors.white),
).show(context);

    final service = FlutterBackgroundService();

      if (submittedAttendanceType == "present") {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    await Flushbar(
      message: "Please enable GPS",
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.BOTTOM,
      backgroundColor: Colors.orange,
      margin: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(8),
      icon: const Icon(Icons.location_on, color: Colors.white),
    ).show(context);

    await Geolocator.openLocationSettings();
    return;
  }


      PermissionStatus foreground = await Permission.locationWhenInUse.status;
      if (!foreground.isGranted) {
        foreground = await Permission.locationWhenInUse.request();
      }

      if (!foreground.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foreground location permission is required"),
          ),
        );
        return;
      }

      PermissionStatus background = await Permission.locationAlways.status;
      if (!background.isGranted) {
        background = await Permission.locationAlways.request();
      }

      if (!background.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please allow background location from settings"),
            action: SnackBarAction(
              label: "Settings",
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      final running = await service.isRunning();
      if (!running) {
        await service.startService();
      }
    }

    if (submittedAttendanceType == "day_over") {
      final running = await service.isRunning();
      if (running) {
        service.invoke("stopService");
      }
    }

    resetForm();   // <-- move here, at the end
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  void resetForm() {
    setState(() {
      attendanceType = null;
      workType = null;
      workingArea = null;
      travelMode = null;
      vehicleType = null;
      visitLocation = null;
      odometerReading = '';
      selfieImage = null;
      odometerImage = null;
    });

    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
  return SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              const Text(
                'Attendance Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  OptionButton(
                    text: 'Present',
                    value: 'present',
                    selectedValue: attendanceType,
                    onTap: (val) {
                      setState(() {
                        attendanceType = val;
                        workType = null;
                      });
                    },
                  ),
                  OptionButton(
                    text: 'Day Over',
                    value: 'day_over',
                    selectedValue: attendanceType,
                    onTap: (val) {
                      setState(() {
                        attendanceType = val;
                        workType = null;
                      });
                    },
                  ),
                  OptionButton(
                    text: 'Leave',
                    value: 'leave',
                    selectedValue: attendanceType,
                    onTap: (val) {
                      setState(() {
                        attendanceType = val;
                        workType = null;
                      });
                    },
                  ),
                ],
              ),
              if (attendanceType == 'present' ||
                  attendanceType == 'day_over') ...[
                const SizedBox(height: 12),
                const Text(
                  'Work Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    OptionButton(
                      text: 'Field Work',
                      value: 'field',
                      selectedValue: workType,
                      onTap: (val) {
                        setState(() {
                          workType = val;
                        });
                      },
                    ),
                    OptionButton(
                      text: 'Office Sitting',
                      value: 'office',
                      selectedValue: workType,
                      onTap: (val) {
                        setState(() {
                          workType = val;
                        });
                      },
                    ),
                    OptionButton(
                      text: 'WFH',
                      value: 'work_from_home',
                      selectedValue: workType,
                      onTap: (val) {
                        setState(() {
                          workType = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
              if (attendanceType == 'present' && workType == 'field') ...[
                const SizedBox(height: 12),
                const Text(
                  'Working Area',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    OptionButton(
                      text: 'City',
                      value: 'city',
                      selectedValue: workingArea,
                      onTap: (val) {
                        setState(() {
                          workingArea = val;
                        });
                      },
                    ),
                    OptionButton(
                      text: 'Ex City',
                      value: 'ex_city',
                      selectedValue: workingArea,
                      onTap: (val) {
                        setState(() {
                          workingArea = val;
                        });
                      },
                    ),
                    OptionButton(
                      text: 'Tour',
                      value: 'tour',
                      selectedValue: workingArea,
                      onTap: (val) {
                        setState(() {
                          workingArea = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Travel Mode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    OptionButton(
                      text: 'Public',
                      value: 'public',
                      selectedValue: travelMode,
                      onTap: (val) {
                        setState(() {
                          travelMode = val;
                        });
                      },
                    ),
                    OptionButton(
                      text: 'Private',
                      value: 'private',
                      selectedValue: travelMode,
                      onTap: (val) {
                        setState(() {
                          travelMode = val;
                        });
                      },
                    ),
                  ],
                ),
                if (travelMode == 'private') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Vehicle Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      OptionButton(
                        text: 'Two Wheeler',
                        value: 'two_wheeler',
                        selectedValue: vehicleType,
                        onTap: (val) {
                          setState(() {
                            vehicleType = val;
                          });
                        },
                      ),
                      OptionButton(
                        text: 'Four Wheeler',
                        value: 'four_wheeler',
                        selectedValue: vehicleType,
                        onTap: (val) {
                          setState(() {
                            vehicleType = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Odometer Reading',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => odometerReading = val,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Visit Location',
                  ),
                  onChanged: (val) => visitLocation = val,
                ),

                 const SizedBox(height: 12),
              if (travelMode == 'private')
                Center(
                  child: ElevatedButton(
                    onPressed: () => pickImage('odometer'),
                    child: const Text('Take Odometer Image'),
                  ),
                ),
              if (odometerImage != null)
                Image.file(odometerImage!, height: 150),
              ],

        
              if (attendanceType == 'day_over' && workType == 'field') ...[
  const SizedBox(height: 12),

  const Text(
    'Odometer Reading',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),

  const SizedBox(height: 8),

  TextFormField(
    decoration: const InputDecoration(
      labelText: 'Day Over Odometer Reading',
    ),
    keyboardType: TextInputType.number,
    onChanged: (val) => odometerReading = val,
  ),

  const SizedBox(height: 12),

  Center(
    child: ElevatedButton(
      onPressed: () => pickImage('odometer'),
      child: const Text('Take Odometer Image'),
    ),
  ),

  if (odometerImage != null)
    Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Image.file(odometerImage!, height: 150),
    ),
],

              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () => pickImage('selfie'),
                  child: const Text('Take Selfie'),
                ),
              ),
              if (selfieImage != null && selfieImage!.existsSync())
  Image.file(selfieImage!, height: 150),
             
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: (isFormValid() && !isLoading) ? handleSubmit : null,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: isFormValid()
                          ? const LinearGradient(
                              colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
                            )
                          : const LinearGradient(
                              colors: [Colors.grey, Colors.grey],
                            ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        if (isFormValid())
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                      ],
                    ),
                   child: Center(
  child: isLoading
      ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
      : const Text(
          'SUBMIT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
),
                  ),
                ),
              ),
           ],
      ),
    ),
  );

  }
}
