import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'EmpProfile/distributor_onbording_page.dart';

class QuickActionItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  QuickActionItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class QuickActionsPage extends StatelessWidget {
  final Function(int) onTabChange;
  final Function(String, String, String)? onExpenseSelect;

  const QuickActionsPage({
    super.key,
    required this.onTabChange,
    this.onExpenseSelect,
  });

@override
Widget build(BuildContext context) {
  final List<QuickActionItem> actions = [
    QuickActionItem(
      title: "Hotel Expense",
      icon: Icons.hotel,
      onTap: () {
        onExpenseSelect?.call("HOTEL", "Hotel Expense", "hotel stay");
        onTabChange(-1);
      },
    ),
    QuickActionItem(
      title: "Bus/Train/Toll",
      icon: Icons.directions_bus,
      onTap: () {
        onExpenseSelect?.call(
            "BUS_TRAIN_TOLL", "Bus / Train / Toll Expense", "travel expense");
        onTabChange(-1);
      },
    ),
    QuickActionItem(
      title: "Petrol/Diesel",
      icon: Icons.local_gas_station,
      onTap: () {
        onExpenseSelect?.call(
            "PETROL_DIESEL", "Petrol / Diesel Expense", "fuel expense");
        onTabChange(-1);
      },
    ),
    QuickActionItem(
      title: "Others Expense",
      icon: Icons.receipt_long,
      onTap: () {
        onExpenseSelect?.call("OTHER", "Other Expense", "other expense");
        onTabChange(-1);
      },
    ),
    QuickActionItem(title: "Sale", icon: Icons.show_chart, onTap: () {}),
    QuickActionItem(title: "Receipt", icon: Icons.receipt, onTap: () {}),
    QuickActionItem(title: "Credit Note", icon: Icons.note_alt_outlined, onTap: () {}),
    QuickActionItem(title: "Price List", icon: Icons.list_alt, onTap: () {}),
   QuickActionItem(
  title: "Distributor Onboarding",
  icon: Icons.person_add,
 onTap: () {
   Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DistributorOnboardingPage(),
  ),
);
  },
),
  ];

  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFFF5F7FA),
    ),
    child: Column(
      children: [

        ///  HEADER SECTION
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Manage your daily activities",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    )
                  ],
                ),
                child: const Icon(Icons.flash_on, color: Color(0xFF1B5E20)),
              )
            ],
          ),
        ),

        ///  GRID CONTAINER
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: GridView.builder(
              itemCount: actions.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                return _QuickActionCard(item: actions[index]);
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _QuickActionCard extends StatelessWidget {
  final QuickActionItem item;

  const _QuickActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container( height: 52, width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withOpacity(0.10),
              ),
              child: Icon( item.icon, color: AppColors.primary, size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle( fontSize: 12, height: 1.2, fontWeight: FontWeight.w600, color: AppColors.textDark, ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}