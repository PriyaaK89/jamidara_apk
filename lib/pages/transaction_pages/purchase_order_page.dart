import 'package:flutter/material.dart';

class PurchaseOrderPage extends StatelessWidget {
  const PurchaseOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Purchase Order")),
      body: const Center(
        child: Text("Purchase Order Screen"),
      ),
    );
  }
}