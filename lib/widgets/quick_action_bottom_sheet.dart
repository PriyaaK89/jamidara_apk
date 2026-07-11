import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../pages/hotel_expenses_page.dart';
import '../pages/expense_page.dart';

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

void showQuickActionBottomSheet(
  BuildContext context,
  Function(int) onTabChange, {
  Function(String, String, String)? onExpenseSelect,  
}) {
  final List<QuickActionItem> actions = [

QuickActionItem(
  title: "Hotel Expense",
  icon: Icons.hotel,
  onTap: () {
    Navigator.pop(context);

    onExpenseSelect?.call(
      "HOTEL",
      "Hotel Expense",
      "hotel stay",
    );

    onTabChange(4);
  },
),

QuickActionItem(
  title: "Bus/Train/Toll",
  icon: Icons.directions_bus,
  onTap: () {
    Navigator.pop(context);

    onExpenseSelect?.call(
      "BUS_TRAIN_TOLL",
      "Bus / Train / Toll Expense",
      "travel expense",
    );

    onTabChange(4);
  },
),

QuickActionItem(
  title: "Petrol/Diesel",
  icon: Icons.local_gas_station,
  onTap: () {
    Navigator.pop(context);

    onExpenseSelect?.call(
      "PETROL_DIESEL",
      "Petrol / Diesel Expense",
      "fuel expense",
    );

    onTabChange(4);
  },
),

QuickActionItem(
  title: "Others Expense",
  icon: Icons.receipt_long,
  onTap: () {
    Navigator.pop(context);

    onExpenseSelect?.call(
      "OTHER",
      "Other Expense",
      "other expense",
    );

    onTabChange(4);
  },
),
    QuickActionItem(
      title: "Sale",
      icon: Icons.show_chart,
      onTap: () {
        Navigator.pop(context);
      },
    ),
    QuickActionItem(
      title: "Receipt",
      icon: Icons.receipt,
      onTap: () {
        Navigator.pop(context);
      },
    ),
    QuickActionItem(
      title: "Credit Note",
      icon: Icons.note_alt_outlined,
      onTap: () {
        Navigator.pop(context);
      },
    ),
   
    QuickActionItem(
      title: "Price List",
      icon: Icons.list_alt,
      onTap: () {
        Navigator.pop(context);
      },
    ),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.55,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.sheetBg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 55,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    itemCount: actions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final item = actions[index];
                      return _QuickActionCard(item: item);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
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