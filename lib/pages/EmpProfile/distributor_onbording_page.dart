import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../layout/main_layout.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:another_flushbar/flushbar.dart';
import "../DistributorOnboarding/AgreementPreview.dart";
import "../DistributorOnboarding/DistributorAgreementModal.dart";
import '../DistributorOnboarding/Widgets/input_decoration.dart';
import '../DistributorOnboarding/Widgets/get_status_widget.dart';
import "../DistributorOnboarding/Widgets/multi_image_picker_widget.dart";
import '../DistributorOnboarding/Widgets/document_picker_wiget.dart';

class DistributorOnboardingPage extends StatefulWidget {
  const DistributorOnboardingPage({super.key});
  @override
  State<DistributorOnboardingPage> createState() =>
      _DistributorOnboardingPageState();
}

class _DistributorOnboardingPageState extends State<DistributorOnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  /// Controllers (Basic)
  final customerName = TextEditingController();
  final gstController = TextEditingController();
  final firmName = TextEditingController();
  final customerDOB = TextEditingController();
  // bussiness add ress
  final businessAddress = TextEditingController();
  final bussinessterritory = TextEditingController();
  final bussinesstehsil = TextEditingController();
  final bussinesstate = TextEditingController();
  final bussinessdistrict = TextEditingController();
  final bussinesspincode = TextEditingController();
  final bussinesslandmark = TextEditingController();
  final bussinesscontact = TextEditingController();
  final bussinessaltcontact = TextEditingController();
  // firm details
  final firmPan = TextEditingController();
  final firmEmail = TextEditingController();
  final firmsince = TextEditingController();
  final branch = TextEditingController();

  final approverName = TextEditingController();
  final approvingDate = TextEditingController();

  // responsible person details
  final responsiblePersonName = TextEditingController();
  final responsiblePersonAddress = TextEditingController();
  final responsiblePersonMobile = TextEditingController();
  final responsiblePersonAltMobile = TextEditingController();
  final responsiblePersonEmail = TextEditingController();
  // license details
  final seedLicenseNumber = TextEditingController();
  final seedLicenseExpiry = TextEditingController();
  final fertilizerLicenseNumber = TextEditingController();
  final pesticideLicenseNumber = TextEditingController();
  // transport details
  final transportAgency1Name = TextEditingController();
  final transportAgency2Name = TextEditingController();
  // bank details
  final firmbankName = TextEditingController();
  final firmbankBranch = TextEditingController();
  final firmbankAccountNumber = TextEditingController();
  final firmbankIfsc = TextEditingController();
  final firmlandmark = TextEditingController();

  // cheque details
  final cheque1Number = TextEditingController();
  final cheque2Number = TextEditingController();
  // other details

  final annualTurnover = TextEditingController();
  final creditdurationperiod = TextEditingController();
  final securityamount = TextEditingController();
  final creditAmount = TextEditingController();
  final expectedsaleperyear = TextEditingController();
  final sourceDetailsController = TextEditingController();
  // final juridictionArea = TextEditingController();

  /// Dropdowns
  String firmType = "";
  String gstType = "";
  String jurisdiction = "";
  String sourceOfFunds = "";
  String firmgsttype = "";
  bool isGstLoading = false;
  bool isGstSuspended = false;
  String gstStatus = "";
  bool isSubmitted = false;
  String? _kycKid;
  String _kycStatus = ""; // "", "sending", "pending", "completed", "failed"
  Timer? _kycPollingTimer;
  Timer? _kycTimeoutTimer;
  bool isGstVerified = false;

  String? requiredValidator(String? value, {String field = "Field"}) {
    if (!isSubmitted) return null;

    if (value == null || value.trim().isEmpty) {
      return "$field is required";
    }
    return null;
  }

  /// Dynamic Fields
  List<Map<String, TextEditingController>> partners = [];
  List<Map<String, TextEditingController>> companies = [
    {"name": TextEditingController(), "turnover": TextEditingController()},
  ];

  // MULTIPLE IMAGES
  List<File> shopImages = [];
  List<File> chequeImages = [];

  // SINGLE IMAGES
  File? aadharFront;
  File? aadharBack;
  File? panPhoto;
  File? gstPhoto;
  File? bankDiary;
  File? letterHead;
  File? authorityLetter;
  File? partnershipDeed;

  // PDF FILES
  File? seedLicenseFile;
  File? fertilizerLicenseFile;
  File? pesticideLicenseFile;
  File? ownerPhoto;
  File? partnerPhoto0;
  File? partnerPhoto1;
  File? partnerPhoto2;
  File? partnerPhoto3;
  File? partnerPhoto4;
  File? approverImg;

  final ownerName = TextEditingController();
  final ownerFather = TextEditingController();
  final ownerPan = TextEditingController();
  final ownerAadhar = TextEditingController();
  final ownerAddress = TextEditingController();
  final ownerState = TextEditingController();
  final ownerDistrict = TextEditingController();
  final ownerTehsil = TextEditingController();
  final ownerPincode = TextEditingController();
  final ownerMobile = TextEditingController();
  final ownerAltMobile = TextEditingController();

  Future<void> _sendForKyc() async {
    final mobile = responsiblePersonMobile.text.trim();
    if (mobile.isEmpty) {
      Flushbar(
        message: "Enter Responsible Person Mobile first",
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        flushbarPosition: FlushbarPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    setState(() => _kycStatus = "sending");

    final response = await ApiService.sendForAadharKYC(
      mobile: mobile,
      token: token,
    );

    if (response["success"] == true) {
      _kycKid = response["data"]["id"]; // ← was response["kid"]
      setState(() => _kycStatus = "pending");
      _startKycPolling(token);
      _startKycTimeout();
    } else {
      setState(() => _kycStatus = "failed");
      Flushbar(
        message: response["message"] ?? "KYC initiation failed",
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
    }
  }

  void _startKycPolling(String token) {
    _kycPollingTimer?.cancel();
    _kycPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkKycStatus(token);
    });
  }

  void _startKycTimeout() {
    _kycTimeoutTimer?.cancel();
    _kycTimeoutTimer = Timer(const Duration(minutes: 10), () {
      if (_kycStatus == "pending") {
        _kycPollingTimer?.cancel();
        setState(() => _kycStatus = "failed");
        Flushbar(
          message: "KYC timed out. Please try again.",
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(8),
        ).show(context);
      }
    });
  }

  Future<void> _checkKycStatus(String token) async {
    if (_kycKid == null) {
      _kycPollingTimer?.cancel();
      return;
    }

    final response = await ApiService.getDetailsFromAadhar(
      kid: _kycKid!,
      token: token,
    );

    if (response["success"] != true) {
      debugPrint("KYC poll failed — will retry: ${response["error"]}");
      return;
    }

    final data = response["data"] as Map<String, dynamic>? ?? {};
    final isCompleted = data["is_completed"] == true;
    final topStatus = (data["status"] ?? "").toString().toLowerCase();

    //  ALSO check if aadhaar data is populated as fallback
    final aadhaar = data["aadhaar"] as Map<String, dynamic>? ?? {};
    final hasAadhaarData =
        (aadhaar["name"] ?? "").toString().isNotEmpty &&
        (aadhaar["dob"] ?? "").toString().isNotEmpty;

    debugPrint(
      "KYC POLL → status: $topStatus | is_completed: $isCompleted | hasData: $hasAadhaarData",
    );

    if (isCompleted || hasAadhaarData) {
      //  treat populated data as completed
      _kycPollingTimer?.cancel();
      _kycTimeoutTimer?.cancel();
      setState(() => _kycStatus = "completed");
      _autoFillFromKyc(data);

      Flushbar(
        message: "KYC completed! Fields auto-filled.",
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
        icon: const Icon(Icons.verified_user, color: Colors.white),
      ).show(context);
    } else if (topStatus == "failed" ||
        topStatus == "rejected" ||
        topStatus == "expired") {
      _kycPollingTimer?.cancel();
      _kycTimeoutTimer?.cancel();
      setState(() => _kycStatus = "failed");

      Flushbar(
        message: "KYC verification failed. Please try again.",
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
    }
  }

  void _autoFillFromKyc(Map<String, dynamic> data) {
    // Backend now sends a clean "aadhaar" object directly
    final aadhaar = data["aadhaar"] as Map<String, dynamic>? ?? {};

    debugPrint("AADHAAR AUTOFILL DATA: $aadhaar");

    setState(() {
      final mobile = data["customer_identifier"]?.toString() ?? "";
      if (mobile.isNotEmpty) responsiblePersonMobile.text = mobile;

      final name = aadhaar["name"]?.toString() ?? "";
      if (name.isNotEmpty) responsiblePersonName.text = name;

      final address = aadhaar["address"]?.toString() ?? "";
      if (address.isNotEmpty) responsiblePersonAddress.text = address;

      final dob = aadhaar["dob"]?.toString() ?? "";

      if (dob.isNotEmpty && customerDOB.text.isEmpty) customerDOB.text = dob;

        if (firmType.toLowerCase() == "proprietorship") {
      if (name.isNotEmpty) ownerName.text = name;
      if (address.isNotEmpty) ownerAddress.text = address;
      if (mobile.isNotEmpty) ownerMobile.text = mobile;

      // Optional fields (if available in API)
      final fatherName = aadhaar["father_name"]?.toString() ?? "";
      if (fatherName.isNotEmpty) ownerFather.text = fatherName;

      final pincode = aadhaar["pincode"]?.toString() ?? "";
      if (pincode.isNotEmpty) ownerPincode.text = pincode;
    }
    });
  }

  @override
  void dispose() {
    _kycPollingTimer?.cancel();
    _kycTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> verifyAndFillGST() async {
    final gst = gstController.text.trim();

    if (gst.isEmpty) {
      Flushbar(
        message: "Enter GST Number",
        duration: const Duration(seconds: 2),
        flushbarPosition: FlushbarPosition.BOTTOM,
        backgroundColor: Colors.orange,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
      return;
    }

    String mapBusinessType(String type) {
      switch (type.toLowerCase()) {
        case "proprietorship":
          return "proprietorship";
        case "partnership":
          return "partnership";
        case "private limited":
        case "private_limited":
          return "private_limited";
        default:
          return ""; // fallback
      }
    }

    setState(() => isGstLoading = true);

    final response = await ApiService.verifyGST(gst);

    setState(() => isGstLoading = false);
    final status = (response["status"] ?? "").toLowerCase();

    setState(() {
      if (response["success"] == true) {
        if (status == "active") {
          gstStatus = "verified";
        } else if (status == "suspended") {
          gstStatus = "suspended";
        } else {
          gstStatus = "not_verified";
        }
      } else {
        gstStatus = "not_verified";
      }
    });
    

    if (response["success"] == true) {
      setState(() {
  if (response["success"] == true && status == "active") {
    gstStatus = "verified";
    isGstVerified = true;   //  lock fields
  } else {
    gstStatus = "not_verified";
    isGstVerified = false;  //  allow editing
  }
});
      setState(() {
        final address = response["address"] ?? {};

        // Auto-fill
        firmName.text = response["business_name"] ?? "";
        customerName.text = response["legal_name"] ?? "";

        businessAddress.text =
            "${address["building"] ?? ""}, ${address["street"] ?? ""}";

        bussinessdistrict.text = address["district"] ?? "";
        bussinesstate.text = address["state"] ?? "";
        bussinesspincode.text = address["pincode"] ?? "";
        bussinesstehsil.text = address["location"] ?? "";
        firmsince.text = response["reg_date"] ?? "";

        //  NEW: Check GST status
        String status = (response["status"] ?? "").toLowerCase();

        if (status == "suspended") {
          isGstSuspended = true;
        } else {
          isGstSuspended = false;
        }

        // Firm type logic
        final apiBusinessType = response["business_type"] ?? "";
        firmType = mapBusinessType(apiBusinessType);
      });

      //  Show message
      if (isGstSuspended) {
        Flushbar(
          message: "GST is Suspended. You cannot submit this form.",
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ).show(context);
      } else {
        Flushbar(
          message: "GST Verified and Data Auto-filled",
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ).show(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Invalid GST")),
      );
    }
  }

  Future<void> submitDistributor() async {
    // if (!_formKey.currentState!.validate()) return;

    if (!_formKey.currentState!.validate()) {
      setState(() {
        isSubmitted = true;
      });

      Flushbar(
        message: "Please fill all required fields",
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        flushbarPosition: FlushbarPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
        icon: const Icon(Icons.warning, color: Colors.white),
      ).show(context);

      return;
    }

    if (isGstSuspended) {
      Flushbar(
        message: "Cannot submit. GST status is Suspended.",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        icon: Icon(Icons.block, color: Colors.white),
      ).show(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    List<Map<String, dynamic>> partnerList = [];

    if (firmType == "partnership") {
      for (var p in partners) {
        partnerList.add({
          "name": p["name"]!.text,
          "mobile_no": p["mobile"]!.text,

          "father_name": p["father_name"]?.text ?? "",
          "pan_no": p["pan_no"]?.text ?? "",
          "aadhar_no": p["aadhar_no"]?.text ?? "",

          "address": p["address"]?.text ?? "",
          "state": p["state"]?.text ?? "",
          "district": p["district"]?.text ?? "",
          "tehsil": p["tehsil"]?.text ?? "",
          "pincode": p["pincode"]?.text ?? "",

          "alt_mobile_no": p["alt_mobile"]?.text ?? "",
        });
      }
    }

    if (firmType == "partnership" && partnerList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one partner")));
      return;
    }
    if (firmType == "partnership" || firmType == "private_limited") {
      if (partners.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("At least 2 partners are required")),
        );
        return;
      }
    }

    for (int i = 0; i < partners.length; i++) {
      var p = partners[i];

      if (p["name"]!.text.isEmpty ||
          p["mobile"]!.text.isEmpty ||
          p["pan_no"]!.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fill all required fields for Partner ${i + 1}"),
          ),
        );
        return;
      }
    }

    List<Map<String, dynamic>> companyList = [];
    for (var c in companies) {
      companyList.add({
        "company_name": c["name"]!.text,
        "turnover": c["turnover"]!.text,
      });
    }

    final data = {
      "customer_name": customerName.text,
      "customer_dob": customerDOB.text,
      "firm_name": firmName.text,
      "gst_number": gstController.text,
      "gst_type": gstType.toLowerCase(),
      "firm_type": firmType.toLowerCase(),

      "business_address": businessAddress.text,
      "business_territory": bussinessterritory.text,
      "state": bussinesstate.text,
      "district": bussinessdistrict.text,
      "tehsil": bussinesstehsil.text,
      "landmark": bussinesslandmark.text,
      "firm_landmark": bussinesslandmark.text,
      "pincode": bussinesspincode.text,

      "contact_number": bussinesscontact.text,
      "alt_contact_number": bussinessaltcontact.text,

      "responsible_person_name": responsiblePersonName.text,
      "responsible_person_contact": responsiblePersonMobile.text,
      "responsible_person_address": responsiblePersonAddress.text,
      "responsible_person_alt_contact": responsiblePersonAltMobile.text,

      "firm_email": firmEmail.text,
      "firm_pan": firmPan.text,
     
      "firm_since": firmsince.text,
      "branch": branch.text,

      "seed_license_no": seedLicenseNumber.text,
      "seed_license_expiry": seedLicenseExpiry.text,
      "fertilizer_license_no": fertilizerLicenseNumber.text,
      "pesticide_license_no": pesticideLicenseNumber.text,

      "transport_name_a": transportAgency1Name.text,
      "transport_name_b": transportAgency2Name.text,

      "bank_name": firmbankName.text,
      "bank_account_no": firmbankAccountNumber.text,
      "ifsc_code": firmbankIfsc.text,
      "bank_branch": firmbankBranch.text,

      "security_cheque_no": cheque1Number.text,
      "security_cheque_no_2": cheque2Number.text,
      "security_amount": securityamount.text,
      "credit_amount": creditAmount.text,

      "source_of_funds": sourceOfFunds,
      "own_funds_details": sourceDetailsController.text,

      "annual_turnover": annualTurnover.text,
      "credit_duration": creditdurationperiod.text,
      "expected_sale": expectedsaleperyear.text,
      "approver_name": approverName.text,
      "approving_date": approvingDate.text,

      // "jurisdiction_area": juridictionArea.text,
    };
    if (firmType == "proprietorship") {
      if (ownerName.text.isEmpty ||
          ownerPan.text.isEmpty ||
          ownerMobile.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Fill all owner details")));
        return;
      }
    }

    if (firmType == "proprietorship") {
      data.addAll({
        "owner_name": ownerName.text,
        "owner_father_name": ownerFather.text,
        "owner_pan": ownerPan.text,
        "owner_aadhar": ownerAadhar.text,
        "owner_address": ownerAddress.text,
        "owner_state": ownerState.text,
        "owner_district": ownerDistrict.text,
        "owner_tehsil": ownerTehsil.text,
        "owner_pincode": ownerPincode.text,
        "owner_mobile": ownerMobile.text,
        "owner_alt_mobile": ownerAltMobile.text,
      });
    }

    Map<String, dynamic> files = {
      "shop_image": shopImages,
      "cheque_photo": chequeImages,

      if (aadharFront != null) "aadhar_front": aadharFront,
      if (aadharBack != null) "aadhar_back": aadharBack,
      if (panPhoto != null) "pan_photo": panPhoto,
      if (gstPhoto != null) "gst_file": gstPhoto,

      if (bankDiary != null) "bank_diary": bankDiary,
      if (letterHead != null) "letter_head": letterHead,
      if (authorityLetter != null) "authority_letter": authorityLetter,
      if (partnershipDeed != null) "partnership_deed": partnershipDeed,

      if (seedLicenseFile != null) "seed_license": seedLicenseFile,
      if (fertilizerLicenseFile != null)
        "fertilizer_license": fertilizerLicenseFile,
      if (pesticideLicenseFile != null)
        "pesticide_license": pesticideLicenseFile,

      if (ownerPhoto != null) "owner_photo": ownerPhoto,

      ///  SEND PARTNER PHOTOS ONLY IF EXISTS
      if (partnerPhoto0 != null) "partner_photo_0": partnerPhoto0,
      if (partnerPhoto1 != null) "partner_photo_1": partnerPhoto1,
      if (partnerPhoto2 != null) "partner_photo_2": partnerPhoto2,
      if (partnerPhoto3 != null) "partner_photo_3": partnerPhoto3,
      if (partnerPhoto4 != null) "partner_photo_4": partnerPhoto4,

      if (approverImg != null) "approver_image": approverImg,
    };

    print("FIRM TYPE: $firmType");
    print("PARTNER LIST: $partnerList");

    final response = await ApiService.createDistributor(
      token: token,
      data: data,
      // partners: firmType == "partnership" ? partnerList : null,
      partners: (firmType == "partnership" && partnerList.isNotEmpty) ? partnerList : null,
      companies: companyList,
      files: files,
    );
    print("FULL RESPONSE: $response");
    final bool isSuccess = response["success"] == true;

    if (!mounted) return;

    Flushbar(
      message: isSuccess
          ? "Distributor Created Successfully"
          : response["message"]?.toString() ?? "Something went wrong",
      duration: const Duration(seconds: 3),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    ).show(context);
    if (isSuccess) {
      Future.delayed(Duration(seconds: 1), () {
        resetForm();
      });
    }
  }

  void removePartner(int index) {
    setState(() {
      partners.removeAt(index);
    });
  }

  /// ADD COMPANY
  void addCompany() {
    setState(() {
      companies.add({
        "name": TextEditingController(),
        "turnover": TextEditingController(),
      });
    });
  }

  void addPartner() {
    setState(() {
      partners.add({
        "name": TextEditingController(),
        "father_name": TextEditingController(),
        "pan_no": TextEditingController(),
        "aadhar_no": TextEditingController(),
        "address": TextEditingController(),
        "state": TextEditingController(),
        "district": TextEditingController(),
        "tehsil": TextEditingController(),
        "pincode": TextEditingController(),
        "mobile": TextEditingController(),
        "alt_mobile": TextEditingController(),
      });
    });
  }

  void resetForm() {
    _formKey.currentState?.reset();

    // Clear all controllers
    for (var controller in [
      customerName,
      gstController,
      firmName,
      customerDOB,
      businessAddress,
      bussinessterritory,
      bussinesstehsil,
      bussinesstate,
      bussinessdistrict,
      bussinesspincode,
      bussinesslandmark,
      bussinesscontact,
      bussinessaltcontact,
      firmPan,
   
      firmEmail,
      firmsince,
      branch,
      approverName,
      approvingDate,
      responsiblePersonName,
      responsiblePersonAddress,
      responsiblePersonMobile,
      responsiblePersonAltMobile,
      responsiblePersonEmail,
      seedLicenseNumber,
      seedLicenseExpiry,
      fertilizerLicenseNumber,
      pesticideLicenseNumber,
      transportAgency1Name,
      transportAgency2Name,
      firmbankName,
      firmbankBranch,
      firmbankAccountNumber,
      firmbankIfsc,
      firmlandmark,
      cheque1Number,
      cheque2Number,
      annualTurnover,
      creditdurationperiod,
      creditAmount,
      securityamount,
      expectedsaleperyear,
      sourceDetailsController,
    
      ownerName,
      ownerFather,
      ownerPan,
      ownerAadhar,
      ownerAddress,
      ownerState,
      ownerDistrict,
      ownerTehsil,
      ownerPincode,
      ownerMobile,
      ownerAltMobile,
    ]) {
      controller.clear();
    }

    // Reset dropdowns
    setState(() {
      firmType = "";
      gstType = "";
      jurisdiction = "";
      sourceOfFunds = "";

      partners.clear();
      companies = [
        {"name": TextEditingController(), "turnover": TextEditingController()},
      ];

      // Clear images
      shopImages.clear();
      chequeImages.clear();

      aadharFront = null;
      aadharBack = null;
      panPhoto = null;
      gstPhoto = null;
      bankDiary = null;
      letterHead = null;
      authorityLetter = null;
      partnershipDeed = null;

      seedLicenseFile = null;
      fertilizerLicenseFile = null;
      pesticideLicenseFile = null;

      ownerPhoto = null;

      partnerPhoto0 = null;
      partnerPhoto1 = null;
      partnerPhoto2 = null;
      partnerPhoto3 = null;
      partnerPhoto4 = null;

      approverImg = null;
    });
  }

  // remove comapny
  void removeCompany(int index) {
    setState(() {
      companies.removeAt(index);
    });
  }


  Future<void> _pickDate() async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1950),
    lastDate: DateTime.now(),
  );

  if (picked != null) {
    setState(() {
      customerDOB.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }
}

  Future<void> _pickDateApprovingDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2090),
    );
    if (picked != null) {
      setState(() {
        approvingDate.text = picked.toString().split(" ")[0];
      });
    }
  }

  Future<void> _pickSeedExpiryDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        seedLicenseExpiry.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      currentRoute: "distributor_onboarding",
      onTabChange: (i) => Navigator.pop(context),

      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///  TOP TITLE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 37, 82, 40),
                    Color.fromARGB(255, 48, 110, 51),
                    Color.fromARGB(255, 115, 167, 117),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.person_add, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Distributor Onboarding",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /// FORM CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                     const SizedBox(height: 20),
                      const Text(
                      "Responsible Person Details",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 20),

                     // Mobile + KYC button row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: responsiblePersonMobile,
                            decoration: AppInputDecoration.input(
                              "Responsible Person Mobile",
                            ),
                            validator: (v) => requiredValidator(
                              v,
                              field: "Responsible Person Mobile",
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (_) {
                              // reset KYC if mobile changes after it was completed
                              if (_kycStatus.isNotEmpty) {
                                setState(() {
                                  _kycStatus = "";
                                  _kycKid = null;
                                  _kycPollingTimer?.cancel();
                                  _kycTimeoutTimer?.cancel();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: ElevatedButton(
                            onPressed:
                                (_kycStatus == "sending" ||
                                    _kycStatus == "pending" ||
                                    _kycStatus == "requested")
                                ? null
                                : _sendForKyc,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kycStatus == "requested"
                                  ? Colors.green
                                  : const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child: (_kycStatus == "sending")
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _kycStatus == "completed"
                                        ? "Verified ✓"
                                        : (_kycStatus == "pending" ||
                                              _kycStatus == "requested")
                                        ? "Pending..."
                                        : "Send KYC",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Status indicator below the row
                    if (_kycStatus == "pending") ...[
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Waiting for user to complete KYC...",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                    if (_kycStatus == "failed") ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "KYC failed. Tap 'Send KYC' to retry.",
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: responsiblePersonName,
                      decoration: AppInputDecoration.input(
                        "Responsible Person Name",
                      ),
                      validator: (v) => requiredValidator(
                        v,
                        field: "Responsible Person Name",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: responsiblePersonAddress,
                      decoration: AppInputDecoration.input(
                        "Responsible Person Address",
                      ),
                      validator: (v) => requiredValidator(
                        v,
                        field: "Responsible Person Address",
                      ),
                    ),
                    const SizedBox(height: 12),

                   
                    TextFormField(
                      controller: responsiblePersonAltMobile,
                      decoration: AppInputDecoration.input(
                        "Responsible Person Alt Mobile",
                      ),
                      validator: (v) => requiredValidator(
                        v,
                        field: "Responsible Person Alt. Mobile",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    FormField<String>(
                      validator: (value) {
                        if (customerDOB.text.isEmpty) {
                          return "Customer DOB is required";
                        }
                        return null;
                      },
                      builder: (FormFieldState<String> state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () async {
                                await _pickDate();

                                state.didChange(
                                  customerDOB.text,
                                ); // notify form
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: state.hasError
                                        ? Colors
                                              .red //  show error border
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      customerDOB.text.isEmpty
                                          ? "Select Customer DOB"
                                          : customerDOB.text,
                                    ),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),

                            //  Error message
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  left: 10,
                                ),
                                child: Text(
                                  state.errorText!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: gstController,
                            decoration: AppInputDecoration.input(
                              "Firm GST Number",
                            ),
                            validator: (v) =>
                                requiredValidator(v, field: "GST Number"),
                            onChanged: (value) {
                              setState(() {
                                gstStatus = "";
                                isGstSuspended = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: isGstLoading ? null : verifyAndFillGST,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B5E20),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          child: isGstLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Verify",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    GstStatusWidget(gstStatus: gstStatus),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firmsince,
                     readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("Firm Since (Year)"),
                      validator: (v) =>
                          requiredValidator(v, field: "Firm Since"),
                      keyboardType: TextInputType.number,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: customerName,
                      readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("Customer Name"),
                      validator: (v) =>
                          requiredValidator(v, field: "Customer Name"),
                    ),
                    const SizedBox(height: 12),

                    /// FIRM NAME
                    TextFormField(
                      controller: firmName,
                      readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("Firm Name"),
                      validator: (v) =>
                          requiredValidator(v, field: "Firm Name"),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField(
                      value: gstType.isEmpty ? null : gstType,
                      items:
                          ["regular", "composition", "consumer", "unregistered"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() => gstType = val.toString());
                      },
                      decoration: AppInputDecoration.input("GST Type"),
                      validator: (v) => requiredValidator(v, field: "GST Type"),
                    ),
                    const SizedBox(height: 12),

                    /// FIRM TYPE
                    DropdownButtonFormField(
                      value: firmType.isEmpty ? null : firmType,
                      items:
                          ["proprietorship", "partnership", "private_limited"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          firmType = val.toString();
                          if (firmType == "proprietorship") {
                            partners.clear();
                          } else {
                            if (partners.length < 2) {
                              partners.clear(); // reset
                              addPartner();
                              addPartner(); //  auto add 2 partners
                            }
                          }
                        });
                        _formKey.currentState!.validate();
                      },
                      decoration: AppInputDecoration.input("Firm Type"),
                      validator: (v) =>
                          requiredValidator(v, field: "Firm Type"),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      "Bussiness Address",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// BUSINESS ADDRESS
                    TextFormField(
                      controller: businessAddress,
                     readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("Business Address"),
                      validator: (v) =>
                          requiredValidator(v, field: "Business Address"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinesslandmark,
                      decoration: AppInputDecoration.input("Business Landmark"),
                      validator: (v) =>
                          requiredValidator(v, field: "Business Landmark"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinessterritory,
                      decoration: AppInputDecoration.input(
                        "Business Territory",
                      ),
                      validator: (v) =>
                          requiredValidator(v, field: "Business Territory"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinesstehsil,
                      readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("Tehsil"),
                      validator: (v) => requiredValidator(v, field: "Tehsil"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinesstate,
                      readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("State"),
                      validator: (v) => requiredValidator(v, field: "State"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinessdistrict,
                     readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("District"),
                      validator: (v) => requiredValidator(v, field: "District"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinesspincode,
                     readOnly: isGstVerified,
                      decoration: AppInputDecoration.input("Pincode"),
                      validator: (v) => requiredValidator(v, field: "Pincode"),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: bussinesscontact,
                      decoration: AppInputDecoration.input("Contact Number"),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          requiredValidator(v, field: "Contact Number"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bussinessaltcontact,
                      decoration: AppInputDecoration.input(
                        "Alternate Contact Number",
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          requiredValidator(v, field: "Alt. Contact Number"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: firmEmail,
                      decoration: AppInputDecoration.input("Firm Email Id"),
                      validator: (v) =>
                          requiredValidator(v, field: "Firm Email Id"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: firmPan,
                      decoration: AppInputDecoration.input("Firm PAN Number"),
                      validator: (v) =>
                          requiredValidator(v, field: "Firm Pan Number"),
                    ),
                    const SizedBox(height: 12),
                  
                    TextFormField(
                      controller: branch,
                      decoration: AppInputDecoration.input("Branch"),
                      validator: (v) => requiredValidator(v, field: "Branch"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firmlandmark,
                      decoration: AppInputDecoration.input("Firm Landmark"),
                      validator: (v) =>
                          requiredValidator(v, field: "Firm Landmark"),
                    ),
                    const SizedBox(height: 12),
                    // TextFormField(
                    //   controller: juridictionArea,
                    //   decoration: AppInputDecoration.input("Juridiction Area"),
                    //   validator: (v) =>
                    //       requiredValidator(v, field: "Juridiction Area"),
                    // ),
                    // const SizedBox(height: 12),


                    if (firmType == "proprietorship") ...[
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Owner Address",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextFormField(
                        controller: ownerName,
                        decoration: AppInputDecoration.input("Name"),
                        validator: (v) =>
                            requiredValidator(v, field: "Owner Name"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerFather,
                        decoration: AppInputDecoration.input("Father Name"),
                        validator: (v) =>
                            requiredValidator(v, field: "Owner's Father Name"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerPan,
                        decoration: AppInputDecoration.input("PAN No"),
                        validator: (v) =>
                            requiredValidator(v, field: "Pan No."),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerAadhar,
                        decoration: AppInputDecoration.input("Aadhar No"),
                        validator: (v) =>
                            requiredValidator(v, field: "Aadhar No."),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerAddress,
                        decoration: AppInputDecoration.input("Address"),
                        validator: (v) =>
                            requiredValidator(v, field: "Address"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerState,
                        decoration: AppInputDecoration.input("State"),
                        validator: (v) => requiredValidator(v, field: "State"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerDistrict,
                        decoration: AppInputDecoration.input("District"),
                        validator: (v) =>
                            requiredValidator(v, field: "District"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerTehsil,
                        decoration: AppInputDecoration.input("Tehsil"),
                        validator: (v) => requiredValidator(v, field: "Tehsil"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerPincode,
                        decoration: AppInputDecoration.input("Pincode"),
                        validator: (v) =>
                            requiredValidator(v, field: "Pincode"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerMobile,
                        decoration: AppInputDecoration.input("Mobile"),
                        validator: (v) => requiredValidator(v, field: "Mobile"),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ownerAltMobile,
                        decoration: AppInputDecoration.input("Alt Mobile"),
                        validator: (v) =>
                            requiredValidator(v, field: "Alt. Mobile"),
                      ),
                      const SizedBox(height: 5),

                      DocumentPickerWidget(
                        label: "Upload Owner Image",
                        file: ownerPhoto,
                        onChanged: (val) => setState(() => ownerPhoto = val),
                      ),
                    ],

                    if (firmType == "partnership" ||
                        firmType == "private_limited") ...[
                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Partners",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      ...partners.asMap().entries.map((entry) {
                        int i = entry.key;
                        var p = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Partner ${i + 1}"),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    // onPressed: () => removePartner(i),
                                    onPressed: () {
                                      if (partners.length <= 2) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Minimum 2 partners required",
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      removePartner(i);
                                    },
                                  ),
                                ],
                              ),

                              TextFormField(
                                controller: p["name"],
                                decoration: AppInputDecoration.input("Name"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Name"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["father_name"],
                                decoration: AppInputDecoration.input(
                                  "Father Name",
                                ),
                                validator: (v) => requiredValidator(
                                  v,
                                  field: "Father's Name",
                                ),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["pan_no"],
                                decoration: AppInputDecoration.input("PAN"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Pan"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["aadhar_no"],
                                decoration: AppInputDecoration.input("Aadhar"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Aadhar"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["address"],
                                decoration: AppInputDecoration.input("Address"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Address"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["state"],
                                decoration: AppInputDecoration.input("State"),
                                validator: (v) =>
                                    requiredValidator(v, field: "State"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["district"],
                                decoration: AppInputDecoration.input(
                                  "District",
                                ),
                                validator: (v) =>
                                    requiredValidator(v, field: "District"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["tehsil"],
                                decoration: AppInputDecoration.input("Tehsil"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Tehsil"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["pincode"],
                                decoration: AppInputDecoration.input("Pincode"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Pincode"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["mobile"],
                                decoration: AppInputDecoration.input("Mobile"),
                                validator: (v) =>
                                    requiredValidator(v, field: "Mobile"),
                              ),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: p["alt_mobile"],
                                decoration: AppInputDecoration.input(
                                  "Alt Mobile",
                                ),
                                validator: (v) =>
                                    requiredValidator(v, field: "Alt. Mobile"),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        );
                      }).toList(),

                      ElevatedButton(
                        onPressed: addPartner,
                        child: const Text("Add Partner"),
                      ),
                    ],
                    const SizedBox(height: 20),

                    
              
                  

                    const Text(
                      "Other Companies",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const SizedBox(height: 10),

                    ...companies.asMap().entries.map((entry) {
                      int index = entry.key;
                      var company = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ), //  BORDER
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),

                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: company["name"],
                                    decoration: AppInputDecoration.input(
                                      "Company Name",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                ///  DELETE BUTTON
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    if (companies.length > 1) {
                                      removeCompany(index);
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// TURNOVER FIELD
                            TextFormField(
                              controller: company["turnover"],
                              decoration: AppInputDecoration.input("Turnover"),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    /// add comapny button
                    ElevatedButton(
                      onPressed: addCompany,
                      child: const Text("Add Company"),
                    ),

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: firmbankName,
                      decoration: AppInputDecoration.input("Bank Name"),
                      validator: (v) =>
                          requiredValidator(v, field: "Bank Name"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firmbankAccountNumber,
                      decoration: AppInputDecoration.input("Account Number"),
                      validator: (v) =>
                          requiredValidator(v, field: "Account Number"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firmbankIfsc,
                      decoration: AppInputDecoration.input("IFSC Code"),
                      validator: (v) =>
                          requiredValidator(v, field: "IFSC Code"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: firmbankBranch,
                      decoration: AppInputDecoration.input("Bank Branch"),
                      validator: (v) =>
                          requiredValidator(v, field: "Bank Branch"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cheque1Number,
                      decoration: AppInputDecoration.input(
                        "Security Cheque 1 No.",
                      ),
                      validator: (v) =>
                          requiredValidator(v, field: "Security Cheque 1 No."),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cheque2Number,
                      decoration: AppInputDecoration.input(
                        "Security Cheque 2 No.",
                      ),
                      validator: (v) =>
                          requiredValidator(v, field: "Security Cheque 2 No."),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: annualTurnover,
                      decoration: AppInputDecoration.input("Annual Turnover"),
                      validator: (v) =>
                          requiredValidator(v, field: "Annual Turnover"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: creditdurationperiod,
                      decoration: AppInputDecoration.input(
                        "Credit Duration Period (in days)",
                      ),
                      validator: (v) => requiredValidator(
                        v,
                        field: "Credit Duration Period (in days)",
                      ),
                    ),
                    const SizedBox(height: 12),
                      TextFormField(
                      controller: creditAmount,
                      decoration: AppInputDecoration.input("CC/OD"),
                      validator: (v) =>
                          requiredValidator(v, field: "CC/OD Amount"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: securityamount,
                      decoration: AppInputDecoration.input("Security Amount"),
                      validator: (v) =>
                          requiredValidator(v, field: "Security Amount"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expectedsaleperyear,
                      decoration: AppInputDecoration.input(
                        "Expected Sale Per Year",
                      ),
                      validator: (v) =>
                          requiredValidator(v, field: "Expected Sale Per Year"),
                    ),
                    const SizedBox(height: 12),

                    ///  SOURCE OF FUNDS
                    DropdownButtonFormField(
                      value: sourceOfFunds.isEmpty ? null : sourceOfFunds,
                      items: ["own_funds", "loan", "investment"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          sourceOfFunds = val.toString();
                          sourceDetailsController.clear(); // reset when changed
                        });
                      },
                      decoration: AppInputDecoration.input("Source of Funds"),
                    ),
                    if (sourceOfFunds.isNotEmpty) ...[
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: sourceDetailsController,
                        decoration: AppInputDecoration.input(
                          sourceOfFunds == "own_funds"
                              ? "Enter Own Funds Details"
                              : sourceOfFunds == "loan"
                              ? "Enter Loan Details"
                              : "Enter Investment Details",
                        ),
                        validator: (value) {
                          if (sourceOfFunds.isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return "This field is required";
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: seedLicenseNumber,
                      decoration: AppInputDecoration.input(
                        "Seed License Number",
                      ),
                      validator: (v) =>
                          requiredValidator(v, field: "Seed License Number"),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _pickSeedExpiryDate,
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
                              seedLicenseExpiry.text.isEmpty
                                  ? "Select Seed License Expiry Date"
                                  : seedLicenseExpiry.text,
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fertilizerLicenseNumber,
                      decoration: AppInputDecoration.input(
                        "Fertilizer License Number",
                      ),
                      validator: (v) => requiredValidator(
                        v,
                        field: "Fertilizer License Number",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pesticideLicenseNumber,
                      decoration: AppInputDecoration.input(
                        "Pesticide License Number",
                      ),
                  
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: transportAgency1Name,
                      decoration: AppInputDecoration.input(
                        "Transport Agency 1 Name",
                      ),
                      validator: (v) => requiredValidator(
                        v,
                        field: "Enter Transport Agency Name",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: transportAgency2Name,
                      decoration: AppInputDecoration.input(
                        "Transport Agency 2 Name",
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Approver Details",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: approverName,
                      decoration: AppInputDecoration.input(
                        "Enter Approver Name",
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _pickDateApprovingDate,
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
                              approvingDate.text.isEmpty
                                  ? "Select Approving Date"
                                  : approvingDate.text,
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DocumentPickerWidget(
                      label: "Upload Approver Image",
                      file: approverImg,
                      onChanged: (val) => setState(() => approverImg = val),
                    ),
                    const Text(
                      "Upload Documents",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 5),

                    MultiImagePickerWidget(
                      title: "Shop Images",
                      images: shopImages,
                      max: 4,
                      onAdd: (file) {
                        setState(() {
                          shopImages.add(file);
                        });
                      },
                      onRemove: (file) {
                        setState(() {
                          shopImages.remove(file);
                        });
                      },
                    ),

                    MultiImagePickerWidget(
                      title: "Cheque Images",
                      images: chequeImages,
                      max: 2,
                      onAdd: (file) {
                        setState(() {
                          chequeImages.add(file);
                        });
                      },
                      onRemove: (file) {
                        setState(() {
                          chequeImages.remove(file);
                        });
                      },
                    ),

                    DocumentPickerWidget(
                      label: "Aadhar Front",
                      file: aadharFront,
                      onChanged: (val) => setState(() => aadharFront = val),
                    ),

                    DocumentPickerWidget(
                      label: "Aadhar Back",
                      file: aadharBack,
                      onChanged: (val) => setState(() => aadharBack = val),
                    ),
                    DocumentPickerWidget(
                      label: "PAN Card",
                      file: panPhoto,
                      onChanged: (val) => setState(() => panPhoto = val),
                    ),
                    DocumentPickerWidget(
                      label: "GST Document",
                      file: gstPhoto,
                      onChanged: (val) => setState(() => gstPhoto = val),
                    ),
                    DocumentPickerWidget(
                      label: "Bank Diary",
                      file: bankDiary,
                      onChanged: (val) => setState(() => bankDiary = val),
                    ),
                    DocumentPickerWidget(
                      label: "Letter Head",
                      file: letterHead,
                      onChanged: (val) => setState(() => letterHead = val),
                    ),
                    DocumentPickerWidget(
                      label: "Authority Letter",
                      file: authorityLetter,
                      onChanged: (val) => setState(() => authorityLetter = val),
                    ),
                    DocumentPickerWidget(
                      label: "Partnership Deed",
                      file: partnershipDeed,
                      onChanged: (val) => setState(() => partnershipDeed = val),
                    ),
                    DocumentPickerWidget(
                      label: "Seed License",
                      file: seedLicenseFile,
                      onChanged: (val) => setState(() => seedLicenseFile = val),
                    ),
                    DocumentPickerWidget(
                      label: "Fertilizer License",
                      file: fertilizerLicenseFile,
                      onChanged: (val) =>
                          setState(() => fertilizerLicenseFile = val),
                    ),
                    DocumentPickerWidget(
                      label: "Pesticide License",
                      file: pesticideLicenseFile,
                      onChanged: (val) =>
                          setState(() => pesticideLicenseFile = val),
                    ),

                    ///  SUBMIT BUTTON
                    InkWell(
                      onTap: submitDistributor,
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 37, 82, 40),
                              Color.fromARGB(255, 48, 110, 51),
                              Color.fromARGB(255, 115, 167, 117),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "SUBMIT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => DistributorAgreementModal(
                                  customerName: customerName.text,
                                  firmName: firmName.text,
                                  businessAddress: businessAddress.text,
                                  firmType: firmType,
                                  bussinessdistrict: bussinessdistrict.text,
                                  bussinessterritory: bussinessterritory.text,
                                  securityamount: securityamount.text,
                                  creditdurationperiod:
                                      creditdurationperiod.text,
                                  
                                  partners: partners,
                                  ownerName: ownerName.text,
                                  ownerAadhar: ownerAadhar.text,
                                  ownerAddress: ownerAddress.text,
                                  ownerState: ownerState.text,
                                  ownerDistrict: ownerDistrict.text,
                                  ownerTehsil: ownerTehsil.text,
                                  ownerPincode: ownerPincode.text,
                                  ownerMobile: ownerMobile.text,
                                  seedLicenceNo: seedLicenseNumber.text,
                                  fertilizerLicenceNo:
                                      fertilizerLicenseNumber.text,
                                  gstNumber: gstController.text,
                                  pesticideLicenseNumber:
                                      pesticideLicenseNumber.text,
                                  firmbankName: firmbankName.text,
                                  firmbankAccountNumber:
                                      firmbankAccountNumber.text,
                                  firmEmail: firmEmail.text,
                                ),
                              );
                            },
                            icon: const Icon(Icons.description, size: 20),
                            label: const Text("Generate Agreement Letter"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 54, 128, 165),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
