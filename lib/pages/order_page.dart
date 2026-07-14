import 'package:flutter/material.dart';
import '../pages/transaction_pages/sales_order_page.dart';
import '../pages/transaction_pages/purchase_order_page.dart';
import '../pages/transaction_pages/credit_note_page.dart';
import '../pages/transaction_pages/debit_note_page.dart';
import '../pages/transaction_pages/payment_page.dart';
import '../pages/transaction_pages/receipt_page.dart';

class OrderPage extends StatelessWidget {
  // const OrderPage({super.key});
  final Function(Widget) onOpenPage;

  const OrderPage({super.key, required this.onOpenPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            const Text(
              "Transactions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 3),

            const Text(
              "Manage all transaction entries",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 0),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.15,
                children: [
                  _buildMenuCard(
                    context,
                    title: "Sales Order",
                    icon: Icons.shopping_cart,
                    color: Colors.green,
                    onTap: () { onOpenPage(const SalesOrderPage()); },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Purchase Order",
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PurchaseOrderPage(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Credit Note",
                    icon: Icons.assignment_return,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreditNotePage(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Debit Note",
                    icon: Icons.receipt_long,
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DebitNotePage(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Payment",
                    icon: Icons.payments,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaymentPage()),
                      );
                    },
                  ),

                  _buildMenuCard(
                    context,
                    title: "Receipt",
                    icon: Icons.account_balance_wallet,
                    color: Colors.teal,
                     onTap: () { onOpenPage(const ReceiptApprovalRequestPage()); },
                 
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 30),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
