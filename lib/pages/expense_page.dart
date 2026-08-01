import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ExpensePage extends StatefulWidget {
  final String expenseType;
  final String title;
  final String remarks;
  final VoidCallback onBackToQuickActions;

  const ExpensePage({
    super.key,
    required this.expenseType,
    required this.title,
    required this.remarks,
    required this.onBackToQuickActions,
  });

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final TextEditingController amountController = TextEditingController();

  DateTime? selectedDate;
  File? selectedImage;
  bool isLoading = false;

  final picker = ImagePicker();

  // Future<void> _pickImageFromCamera() async {
  //   final pickedFile = await picker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 70,
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       selectedImage = File(pickedFile.path);
  //     });
  //   }
  // }

  Future<Position> _getLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception("Location disabled");
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Location permanently denied");
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<String> _getAddress(double lat, double lng) async {
  try {
    final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception("Google API key missing in .env");
    }

    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (res.statusCode == 200 &&
        data['status'] == 'OK' &&
        data['results'] != null &&
        data['results'].isNotEmpty) {
      return data['results'][0]['formatted_address'];
    } else {
      throw Exception("Google API failed: ${data['status']}");
    }
  } catch (e) {
    print("Google API failed: $e");
  }

  //  fallback (offline-safe)
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng);

    final place = placemarks.first;

    return [
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.postalCode,
      place.country
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  } catch (e) {
    return "Location unavailable";
  }
}

Future<File?> _stampImage(File file) async {
  try {
    //  Get location
    final position = await _getLocation();

    //  Get address
    final address = await _getAddress(
      position.latitude,
      position.longitude,
    );

    //  Date & Time
    String date =
        DateFormat('dd-MM-yyyy').format(DateTime.now());
    String time =
        DateFormat('hh:mm a').format(DateTime.now());

    //  Text lines
    List<String> lines = [
      "Date: $date  Time: $time",
      address,
      "Lat: ${position.latitude}, Lng: ${position.longitude}"
    ];

    //  Load image
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    

         final logoBytes =
      await rootBundle.load('assets/images/logo.png');
  final logo =
      img.decodeImage(logoBytes.buffer.asUint8List());

    //  Draw background box
    int padding = 20;
    int boxHeight = (lines.length * 50) + 40;
    int startY = image.height - boxHeight - 20;

    img.fillRect(
      image,
      x1: 0,
      y1: startY,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgba8(0, 0, 0, 180),
    );

    //  Draw text
    final font = img.arial24;

    for (int i = 0; i < lines.length; i++) {
      img.drawString(
        image,
        lines[i],
        font: font,
        x: padding,
        y: startY + 10 + (i * 40),
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    //  Add logo (top-right)
    if (logo != null) {
      final resizedLogo =
          img.copyResize(logo, width: image.width ~/ 4);

      img.compositeImage(
        image,
        resizedLogo,
        dstX: image.width - resizedLogo.width - 10,
        dstY: 10,
      );
    }

    //  Save image
    final dir = await getApplicationDocumentsDirectory();
    final newPath =
        '${dir.path}/visit_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final newFile = File(newPath)
      ..writeAsBytesSync(img.encodeJpg(image, quality: 90));

    return newFile;
  } catch (e) {
    print("Stamp error: $e");
    return null;
  }
}

  Future<void> _pickImageFromCamera() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    Flushbar(
      message: "Camera permission denied",
      duration: const Duration(seconds: 2),
    ).show(context);
    return;
  }

  try {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      File original = File(pickedFile.path);

      setState(() => isLoading = true); //  START LOADER

      File? stampedImage = await _stampImage(original);

      setState(() {
        selectedImage = stampedImage ?? original;
        isLoading = false; //  STOP LOADER
      });
    }
  } catch (e) {
    setState(() => isLoading = false);

    Flushbar(
      message: "Failed to capture image",
      duration: const Duration(seconds: 2),
    ).show(context);
  }
}


Future<void> _pickDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2023),
    lastDate: DateTime(2100),
  );

  if (picked == null) return; // user cancelled

  final now = DateTime.now();
  final bool isSameMonth = picked.year == now.year && picked.month == now.month;

  print("DEBUG picked=$picked isSameMonth=$isSameMonth currentSelectedDate=$selectedDate");

  if (!isSameMonth) {
    Flushbar(
      message: "Only current month date is allowed",
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.BOTTOM,
      backgroundColor: Colors.orange,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
    return; // IMPORTANT: no setState here at all
  }

  setState(() {
    selectedDate = picked;
  });
}
  Future<void> _submit() async {
    if (isLoading) return;

    if (selectedDate == null || amountController.text.isEmpty || selectedImage == null) {
      Flushbar(
        message: "Please fill all fields",
        duration: const Duration(seconds: 2),
        flushbarPosition: FlushbarPosition.BOTTOM,
        backgroundColor: Colors.orange,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
      return;
    }

 final now = DateTime.now();
  final isSameMonth = selectedDate!.year == now.year && selectedDate!.month == now.month;
  if (!isSameMonth) {
    Flushbar(
      message: "Only current month date is allowed",
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.BOTTOM,
      backgroundColor: Colors.orange,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
    return;
  }

    setState(() {
      isLoading = true;
    });

    try {
      // String formattedDate = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      String formattedDate = DateTime.now().toIso8601String();
      print("formatted date in bills $formattedDate");
      final result = await ApiService.uploadExpense(
        expenseType: widget.expenseType,
        expenseDate: formattedDate,
        amount: amountController.text,
        remarks: widget.remarks,
        billFile: selectedImage!,
      );

      bool success = result["success"];
      String message =
          (result["message"] != null && result["message"].toString().isNotEmpty)
          ? result["message"]
          : "Expense uploaded successfully";

      if (!mounted) return;

      Flushbar(
        message: message,
        duration: const Duration(seconds: 2),
        backgroundColor: success
            ? const Color.fromARGB(255, 62, 141, 65)
            : const Color.fromARGB(255, 201, 53, 43),
        margin: const EdgeInsets.all(16),
        flushbarPosition: FlushbarPosition.BOTTOM,
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          success ? Icons.check_circle : Icons.error,
          color: Colors.white,
        ),
      ).show(context);

      // THEN reset
      if (success) {
        setState(() {
          selectedDate = null;
          selectedImage = null;
          amountController.clear();
        });
      }
    } catch (e) {
      Flushbar(
        message: "Something went wrong",
        duration: const Duration(seconds: 2),
        backgroundColor: const Color.fromARGB(255, 203, 53, 42),
      ).show(context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

Widget buildHeader() {
  return Row(
    children: [
      InkWell(
        onTap: widget.onBackToQuickActions, 
        child: const Icon(
          Icons.arrow_back,
          color: Color(0xFF1B5E20),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        widget.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      widget.onBackToQuickActions();// go back to QuickActionsPage
      return false; // prevent app close
    },
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,

     


      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 27, 94, 47),
                      Color.fromARGB(255, 94, 154, 97),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              //  EVERYTHING BELOW REMAINS SAME (NO CHANGE)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Expense Date"),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate == null
                                  ? "Select Date"
                                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _label("Amount"),
                    const SizedBox(height: 8),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.currency_rupee,
                          color: Color(0xFF1B5E20),
                        ),
                        hintText: "Enter amount",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _label("Upload Bill"),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: _pickImageFromCamera,
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 40,
                                    color: Color(0xFF1B5E20),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Tap to capture bill",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: isLoading ? null : _submit,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 27, 94, 47),
                                Color.fromARGB(255, 94, 154, 97),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
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
                                    "SUBMIT",
                                    style: TextStyle(
                                      color: Colors.white,
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
            ],
          ),
        ),
      ),
    ),
  );
}}