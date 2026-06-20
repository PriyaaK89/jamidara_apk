import 'package:flutter/material.dart';

class DebitNotePage extends StatelessWidget {
  const DebitNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debit Note")),
      body: const Center(
        child: Text("Debit Note Screen"),
      ),
    );
  }
}