import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'package:another_flushbar/flushbar.dart';

class ExpensePage extends StatefulWidget {
  final String expenseType;
  final String title;
  final String remarks;
 

  const ExpensePage({
    super.key,
    required this.expenseType,
    required this.title,
    required this.remarks,
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

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

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

 Future<void> _submit() async {
  if (isLoading) return;

  if (selectedDate == null ||
      amountController.text.isEmpty ||
      selectedImage == null) {
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

  setState(() {
    isLoading = true;
  });

  try {
    String formattedDate =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

    final result = await ApiService.uploadExpense(
      expenseType: widget.expenseType,
      expenseDate: formattedDate,
      amount: amountController.text,
      remarks: widget.remarks,
      billFile: selectedImage!,
    );

    bool success = result["success"];
    String message = (result["message"] != null &&
        result["message"].toString().isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 27, 94, 47), Color.fromARGB(255, 94, 154, 97)],
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
  onTap: isLoading ? null : _submit, //  disable when loading
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color.fromARGB(255, 27, 94, 47),
          Color.fromARGB(255, 94, 154, 97)
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
)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
