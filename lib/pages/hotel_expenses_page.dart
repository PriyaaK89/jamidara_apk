import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:another_flushbar/flushbar.dart';

class HotelExpensePage extends StatefulWidget {
  const HotelExpensePage({super.key});

  @override
  State<HotelExpensePage> createState() => _HotelExpensePageState();
}

class _HotelExpensePageState extends State<HotelExpensePage> {
  final TextEditingController amountController = TextEditingController();

  DateTime? selectedDate;
  File? selectedImage;

  final picker = ImagePicker();

  ///  CAMERA PICK
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // compress image
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  ///  DATE PICKER
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  ///  SUBMIT
Future<void> _submit() async {
  if (selectedDate == null ||
      amountController.text.isEmpty ||
      selectedImage == null) {

    Flushbar(
      message: "Please fill all fields",
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.orange,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
      icon: const Icon(Icons.warning, color: Colors.white),
    ).show(context);

    return;
  }

  String formattedDate =
      "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

  final result = await ApiService.uploadExpense(
      expenseType: "HOTEL",
      expenseDate: formattedDate,
      amount: amountController.text,
      remarks: "hotel stay",
      billFile: selectedImage!,
    );

    bool success = result["success"];
    String message = result["message"];

  ///  SUCCESS / FAILURE FLUSHBAR
  Flushbar(
    message: success
        ? "Expense uploaded successfully"
        : "Upload Failed",
    duration: const Duration(seconds: 2),
    flushbarPosition: FlushbarPosition.BOTTOM,
    backgroundColor: success ? const Color.fromARGB(255, 54, 134, 57) : const Color.fromARGB(255, 217, 46, 33),
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(8),
    icon: Icon(
      success ? Icons.check_circle : Icons.error,
      color: Colors.white,
    ),
  ).show(context);
}
  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hotel Expense",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// DATE
                _buildInputLabel("Expense Date"),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
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

                /// AMOUNT
                _buildInputLabel("Amount"),
                const SizedBox(height: 8),

                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_rupee),
                    hintText: "Enter amount",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 14, 
    ),
                    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// UPLOAD IMAGE
                _buildInputLabel("Upload Bill"),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: _pickImageFromCamera,
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
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
                              Icon(Icons.camera_alt, size: 40),
                              SizedBox(height: 8),
                              Text("Tap to capture image"),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 26),

                /// SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "SUBMIT",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}