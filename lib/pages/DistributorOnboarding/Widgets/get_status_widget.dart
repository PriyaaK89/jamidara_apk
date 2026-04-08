import 'package:flutter/material.dart';

class GstStatusWidget extends StatelessWidget {
  final String gstStatus;

  const GstStatusWidget({
    super.key,
    required this.gstStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (gstStatus.isEmpty) return const SizedBox();

    Color color;
    String text;
    IconData icon;

    switch (gstStatus) {
      case "verified":
        color = Colors.green;
        text = "Verified";
        icon = Icons.check_circle;
        break;

      case "suspended":
        color = Colors.red;
        text = "Suspended";
        icon = Icons.block;
        break;

      default:
        color = Colors.orange;
        text = "Not Verified";
        icon = Icons.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}