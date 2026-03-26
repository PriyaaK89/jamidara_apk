import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'quick_action_bottom_sheet.dart';

class GlobalAddButton extends StatelessWidget {
  final Function(int) onTabChange; //  ADD THIS
  final Function(String, String, String)? onExpenseSelect;

  const GlobalAddButton({
    super.key,
    required this.onTabChange, //  REQUIRED
     this.onExpenseSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: AppColors.fabBg,
        elevation: 0,
        onPressed: () {
          showQuickActionBottomSheet(
            context,
            onTabChange,
            onExpenseSelect: onExpenseSelect,
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
