import 'package:flutter/material.dart';

/// Keys 1-9. The key matching [selectedValue] is highlighted.
class NumberPad extends StatelessWidget {
  final int selectedValue;
  final ValueChanged<int> onNumber;

  const NumberPad({
    super.key,
    required this.selectedValue,
    required this.onNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(9, (index) {
          final number = index + 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onNumber(number),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: number == selectedValue
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFF2C3E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
