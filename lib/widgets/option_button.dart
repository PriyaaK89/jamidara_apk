import 'package:flutter/material.dart';

class OptionButton extends StatelessWidget {
  final String text;
  final String value;
  final String? selectedValue;
  final Function(String) onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: selectedValue == value ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text.toUpperCase(),

              maxLines: 1,                       
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,     
  style: TextStyle(
    fontSize: 13,                   
    fontWeight: FontWeight.w600,
    color: selectedValue == value
        ? Colors.white
        : Colors.black,
  ),
            ),
          ),
        ),
      ),
    );
  }
}