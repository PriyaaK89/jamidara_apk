import 'package:flutter/material.dart';

class CreditNotePage extends StatelessWidget {
  const CreditNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Credit Note")),
      body: const Center(
        child: Text("Credit Note Screen"),
      ),
    );
  }
}