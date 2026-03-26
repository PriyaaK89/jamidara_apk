import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/api_service.dart';
import 'package:another_flushbar/flushbar.dart';

class VisitPage extends StatefulWidget {
  const VisitPage({super.key});

  @override
  State<VisitPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> {
  bool isSubmitting = false;
  int customerDropdownKey = 0;
  String? attendanceType; // Retailer / Distributor / Farmer
  String? customerType; // Old Customer / New Customer
  String? visitPurpose;

  final TextEditingController firmNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  final TextEditingController reminderDateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController firmAddressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  List<String> areaList = [];
  String? selectedArea;
  bool isLoadingArea = false;

  List<Map<String, dynamic>> customerList = [];
  int? selectedCustomerId;
  bool isLoadingCustomers = false;

  @override
  void dispose() {
    firmNameController.dispose();
    nameController.dispose();
    contactNumberController.dispose();
    addressController.dispose();
    commentController.dispose();
    reminderDateController.dispose();
    pincodeController.dispose();
    districtController.dispose();
    firmAddressController.dispose();
    super.dispose();
  }


  void _showFlushbar(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    Flushbar(
      message: message,
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.BOTTOM,
      backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
      margin: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(12),
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error_outline,
        color: Colors.white,
      ),
    ).show(context);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearCustomerSelection() {
    selectedCustomerId = null;
    customerList = [];
  }

  void _clearCustomerFields() {
    firmNameController.clear();
    nameController.clear();
    contactNumberController.clear();
    addressController.clear();
    districtController.clear();
    pincodeController.clear();
    firmAddressController.clear();
    selectedArea = null;
    areaList = [];
  }

  void _resetForm() {
    setState(() {
      attendanceType = null;
      customerType = null;
      visitPurpose = null;

      _selectedImage = null;

      selectedCustomerId = null;
      selectedArea = null;

      customerList = [];
      areaList = [];

      firmNameController.clear();
      nameController.clear();
      contactNumberController.clear();
      addressController.clear();
      commentController.clear();
      reminderDateController.clear();
      pincodeController.clear();
      districtController.clear();
      firmAddressController.clear();

      customerDropdownKey++; // force DropdownSearch rebuild
    });
  }


  Future<void> _selectReminderDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        reminderDateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }


  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;

    _showFlushbar("Camera permission denied");
    return false;
  }

  Future<bool> _requestGalleryPermission() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = await Permission.photos.request();

      if (!status.isGranted && !status.isLimited) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) return true;

    _showFlushbar("Gallery permission denied");
    return false;
  }

  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: Text(
                    "Select Option",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3047B0),
                    ),
                  ),
                ),
                // ListTile(
                //   leading: const Icon(Icons.photo_library_outlined),
                //   title: const Text("Choose from Gallery"),
                //   onTap: () {
                //     Navigator.pop(context);
                //     _pickImageFromGallery();
                //   },
                // ),
                ListTile(
                  leading: const Icon(Icons.camera_front_outlined),
                  title: const Text("Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera(CameraDevice.front);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text("Cancel"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showFlushbar("Failed to pick image from gallery");
    }
  }

  Future<void> _pickImageFromCamera(CameraDevice cameraDevice) async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: cameraDevice,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showFlushbar("Failed to capture image");
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }


  Future<void> _handlePincodeChange(String pincode) async {
    if (pincode.length != 6) {
      setState(() {
        districtController.clear();
        areaList = [];
        selectedArea = null;
      });
      return;
    }

    setState(() {
      isLoadingArea = true;
    });

    try {
      final districtRes = await ApiService.getDistrictByPincode(pincode);

      if (districtRes != null && districtRes['success'] == true) {
        districtController.text = districtRes['data']['district'] ?? '';
      } else {
        districtController.clear();
      }

      final areas = await ApiService.getAreasByPincode(pincode);

      setState(() {
        areaList = List<String>.from(areas);
        if (selectedArea != null && !areaList.contains(selectedArea)) {
          selectedArea = null;
        }
      });
    } catch (e) {
      _showFlushbar("Failed to load district/area");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingArea = false;
        });
      }
    }
  }



  Future<void> _fetchCustomers() async {
    if (attendanceType == null || customerType != "Old Customer") return;

    setState(() {
      isLoadingCustomers = true;
      customerList = [];
      selectedCustomerId = null;
    });

    try {
      final type = attendanceType!.toLowerCase().trim();
      final data = await ApiService.getCustomers(type);

      final customers = List<Map<String, dynamic>>.from(data);

      if (!mounted) return;

      setState(() {
        customerList = customers;
      });
    } catch (e) {
      _showFlushbar("Failed to load customers");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCustomers = false;
        });
      }
    }
  }

  Future<void> _fetchCustomerDetails(int id) async {
    try {
      final data = await ApiService.getCustomerById(id);

      if (data == null) {
        _showFlushbar("Customer details not found");
        return;
      }

      final pincode = (data['pincode'] ?? '').toString();

      // First fill basic details
      setState(() {
        firmNameController.text = (data['firm_name'] ?? '').toString();
        nameController.text = (data['name'] ?? '').toString();
        firmAddressController.text = (data['firm_address'] ?? '').toString();
        contactNumberController.text = (data['contact_number'] ?? '')
            .toString();
        addressController.text = (data['address'] ?? '').toString();
        districtController.text = (data['district'] ?? '').toString();
        pincodeController.text = pincode;
      });

      // Then fetch areas by pincode so area dropdown is correct
      if (pincode.length == 6) {
        await _handlePincodeChange(pincode);
      }

      final apiArea = (data['area'] ?? '').toString().trim();
      if (apiArea.isNotEmpty) {
        setState(() {
          selectedArea = apiArea;
          if (!areaList.contains(apiArea)) {
            areaList.add(apiArea);
          }
        });
      }
    } catch (e) {
      _showFlushbar("Failed to load customer details");
    }
  }


Future<void> _submitForm() async {
  if (attendanceType == null) {
    _showFlushbar("Please select attendance type");
    return;
  }

  if (customerType == null) {
    _showFlushbar("Please select customer type");
    return;
  }

  if (visitPurpose == null) {
    _showFlushbar("Please select visit purpose");
    return;
  }

  if (customerType == "Old Customer" && selectedCustomerId == null) {
    _showFlushbar("Please select old customer");
    return;
  }

  //  OPTIONAL (better UX)
  if (_selectedImage == null) {
    _showFlushbar("Please upload image");
    return;
  }

  setState(() {
    isSubmitting = true;
  });

  try {
    final response = await ApiService.uploadVisit(
      visitType: attendanceType!,
      customerType: customerType!,
      name: nameController.text.trim(),
      firm_name: firmNameController.text.trim(),
      firm_address: firmAddressController.text.trim(),
      contactNumber: contactNumberController.text.trim(),
      address: addressController.text.trim(),
      district: districtController.text.trim(),
      visitPurpose: visitPurpose!,
      comment: commentController.text.trim(),
      reminderDate: reminderDateController.text.trim(),
      pincode: pincodeController.text.trim(),
      area: selectedArea ?? '',
      image: _selectedImage,
    );

    bool success = response["success"];
    String message = response["message"];

    if (success) {
      _resetForm();
    }

    _showFlushbar(
      message,
      isSuccess: success,
    );

  } catch (e) {
    _showFlushbar("Submission failed: $e");
  } finally {
    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }
}
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: const Color(0xFF81C784).withOpacity(0.4), // light green border
  ),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF1B5E20).withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ],
),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 61, 104, 110),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _customTextField({
    required String hint,
    TextEditingController? controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color.fromARGB(255, 244, 244, 244),
          // fillColor: const Color(0xFFF1F8E9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: const BorderSide(
    color: Color(0xFF1B5E20), // green focus
    width: 1.5,
  ),
),
        ),
      ),
    );
  }

 Widget _radioOption({
  required String value,
  required String groupValue,
  required String title,
  required Function(String?) onChanged,
}) {
  return Expanded(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.9, // reduce radio size (less space)
          child: Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, //  remove extra padding
            visualDensity: VisualDensity.compact, // compact spacing
            activeColor: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(width: 2), //  very small gap
        Expanded(
          child: Text(
            title,
            maxLines: 1, //  force single line
            overflow: TextOverflow.visible, //  show full text
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(255, 255, 255, 255),
      // fillColor: const Color(0xFFF1F8E9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: const BorderSide(
    color: Color(0xFF1B5E20),
    width: 1.5,
  ),
),
    );
  }

  Widget _buildUploadSection() {
    return _sectionCard(
      title: "Upload Image",
      child: Column(
        children: [
          InkWell(
            onTap: _showImagePickerOptions,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
          Image.asset(
            "assets/images/mirrorless.png",
            height: 80,
            width: 80,
          ),
                        SizedBox(height: 10),
                        Text(
                          "Tap to Upload Image",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
       
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: const Text("Employee Visit",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 253, 254, 255),
        
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(vertical: 24),
              //   margin: const EdgeInsets.only(bottom: 18),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(22),
              //   ),
              //   child: const Center(
              //     child: Text(
              //       "Employee Visit",
              //       style: TextStyle(
              //         fontSize: 28,
              //         fontWeight: FontWeight.bold,
              //         color: Color(0xFF3047B0),
              //       ),
              //     ),
              //   ),
              // ),

              // Attendance Type
              _sectionCard(
                title: "Attendance Type",
                child: Row(
                  children: [
                    _radioOption(
                      value: "Retailer",
                      groupValue: attendanceType ?? "",
                      title: "Retailer",
                      onChanged: (val) async {
                        setState(() {
                          attendanceType = val;
                          _clearCustomerSelection();
                          _clearCustomerFields();
                        });

                        if (customerType == "Old Customer") {
                          await _fetchCustomers();
                        }
                      },
                    ),
                    _radioOption(
                      value: "Distributor",
                      groupValue: attendanceType ?? "",
                      title: "Distributor",
                      onChanged: (val) async {
                        setState(() {
                          attendanceType = val;
                          _clearCustomerSelection();
                          _clearCustomerFields();
                        });

                        if (customerType == "Old Customer") {
                          await _fetchCustomers();
                        }
                      },
                    ),
                    _radioOption(
                      value: "Farmer",
                      groupValue: attendanceType ?? "",
                      title: "Farmer",
                      onChanged: (val) async {
                        setState(() {
                          attendanceType = val;
                          _clearCustomerSelection();
                          _clearCustomerFields();
                        });

                        if (customerType == "Old Customer") {
                          await _fetchCustomers();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Customer Type
              _sectionCard(
                title: "Customer Type",
                child: Row(
                  children: [
                    _radioOption(
                      value: "Old Customer",
                      groupValue: customerType ?? "",
                      title: "Old Customer",
                      onChanged: (val) async {
                        setState(() {
                          customerType = val;
                          _clearCustomerSelection();
                          _clearCustomerFields();
                        });

                        await _fetchCustomers();
                      },
                    ),
                    _radioOption(
                      value: "New Customer",
                      groupValue: customerType ?? "",
                      title: "New Customer",
                      onChanged: (val) {
                        setState(() {
                          customerType = val;
                          _clearCustomerSelection();
                          _clearCustomerFields();
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Customer Information
              _sectionCard(
                title: "${attendanceType ?? 'Customer'} Information",
                child: Column(
                  children: [
                    if (customerType == "Old Customer") ...[
                      if (attendanceType == null)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Please select Attendance Type first",
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      else if (isLoadingCustomers)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: DropdownSearch<Map<String, dynamic>>(
                            key: ValueKey(customerDropdownKey),
                            items: customerList,
                            itemAsString: (item) =>
                                item['name']?.toString() ?? '',
                            selectedItem: customerList
                                .cast<Map<String, dynamic>?>()
                                .firstWhere(
                                  (item) => item?['id'] == selectedCustomerId,
                                  orElse: () => null,
                                ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: _dropdownDecoration()
                                  .copyWith(hintText: "Select Customer"),
                            ),
                            popupProps: PopupProps.bottomSheet(
                              showSearchBox: true,
                              bottomSheetProps: const BottomSheetProps(
                                elevation: 8,
                                backgroundColor: Colors.white,
                              ),
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search Customer",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            compareFn: (item, selectedItem) =>
                                item['id'] == selectedItem['id'],
                            onChanged: (value) async {
                              if (value == null) return;

                              setState(() {
                                selectedCustomerId = value['id'] as int;
                              });

                              await _fetchCustomerDetails(value['id'] as int);
                            },
                          ),
                        ),

                      _customTextField(
                        hint: "Firm Address",
                        controller: firmAddressController,
                        readOnly: true,
                      ),
                    ] else ...[
                      _customTextField(
                        hint: "Enter ${attendanceType ?? ''} Name",
                        controller: firmNameController,
                      ),
                      _customTextField(
                        hint: "Enter Firm Address",
                        controller: firmAddressController,
                      ),
                    ],
                  ],
                ),
              ),

              // Contact Information
              _sectionCard(
                title: "Contact Information",
                child: Column(
                  children: [
                    _customTextField(
                      hint: "Enter Contact Person Name",
                      controller: nameController,
                    ),
                    _customTextField(
                      hint: "Enter Contact Number",
                      controller: contactNumberController,
                      keyboardType: TextInputType.phone,
                      suffixIcon: IconButton(
                        onPressed: () {
                          _showSnackBar("Call action pending");
                        },
                        icon: const Icon(Icons.call, color: Colors.teal),
                      ),
                    ),
                    _customTextField(
                      hint: "Enter Pincode",
                      controller: pincodeController,
                      keyboardType: TextInputType.number,
                      onChanged: _handlePincodeChange,
                    ),
                    _customTextField(
                      hint: "District",
                      controller: districtController,
                      readOnly: true,
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: isLoadingArea
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: selectedArea,
                              isExpanded: true,
                              decoration: _dropdownDecoration(),
                              hint: const Text("Select Area"),
                              items: areaList.map((area) {
                                return DropdownMenuItem<String>(
                                  value: area,
                                  child: Text(
                                    area,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedArea = value;
                                });
                              },
                            ),
                    ),
                    _customTextField(
                      hint: "Enter Address",
                      controller: addressController,
                    ),
                  ],
                ),
              ),

              // Visit Details
              _sectionCard(
                title: "Visit Details",
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: visitPurpose,
                      isExpanded: true,
                      decoration: _dropdownDecoration(),
                      hint: const Text("Select Visit Purpose"),
                      items: const [
                        DropdownMenuItem(value: "Order", child: Text("Order")),
                        DropdownMenuItem(
                          value: "new_dist_planning",
                          child: Text("New Distributor Planning"),
                        ),
                        DropdownMenuItem(
                          value: "sales_order",
                          child: Text("Sales Order"),
                        ),
                        DropdownMenuItem(
                          value: "sales_return",
                          child: Text("Sales Return"),
                        ),
                        DropdownMenuItem(
                          value: "collection",
                          child: Text("Collection"),
                        ),
                        DropdownMenuItem(
                          value: "others",
                          child: Text("Others"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          visitPurpose = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _customTextField(
                      hint: "Enter Comment If Any",
                      controller: commentController,
                      maxLines: 4,
                    ),
                    _customTextField(
                      hint: "Reminder Date",
                      controller: reminderDateController,
                      readOnly: true,
                      onTap: _selectReminderDate,
                    ),
                  ],
                ),
              ),

              _buildUploadSection(),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _resetForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 217, 54, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "SUBMIT",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
