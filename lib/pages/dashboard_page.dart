import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final int employeeId;

  const DashboardPage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// Greeting Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Welcome Back 👋\nHave a productive day!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Stats Cards
          Row(
            children: const [
              Expanded(child: _StatCard(title: "Visits", value: "12")),
              SizedBox(width: 10),
              Expanded(child: _StatCard(title: "Orders", value: "5")),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: const [
              Expanded(child: _StatCard(title: "Sales", value: "₹25K")),
              SizedBox(width: 10),
              Expanded(child: _StatCard(title: "Expenses", value: "₹3K")),
            ],
          ),

          const SizedBox(height: 20),

          /// Quick Actions
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _QuickAction(icon: Icons.add_location, title: "Visit"),
              _QuickAction(icon: Icons.shopping_cart, title: "Order"),
              _QuickAction(icon: Icons.receipt, title: "Expense"),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;

  const _QuickAction({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}