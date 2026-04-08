import 'package:flutter/material.dart';

class AgreementPreviewModal extends StatelessWidget {
  final String customerName;
  final String firmName;
  final String address;

  const AgreementPreviewModal({
    super.key,
    required this.customerName,
    required this.firmName,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            const Text(
              "Agreement Letter Preview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  """
AGREEMENT LETTER

This agreement is made between:

Customer Name: $customerName  
Firm Name: $firmName  
Address: $address  

Terms & Conditions:
1. Distributor will follow company policies.
2. Payment terms must be followed strictly.
3. Any violation may result in termination.

Signature:
____________________
                  """,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}