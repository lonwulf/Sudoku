import 'package:flutter/material.dart';
import 'package:sudoku/src/theme/app_theme.dart';

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
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(9, (index) {
          final number = index + 1;
          // The tap target spans the key's whole slot, including the gaps.
          return Expanded(
            child: Semantics(
              button: true,
              label: 'Enter $number',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onNumber(number),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: number == selectedValue
                          ? GameColors.accent
                          : GameColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: number == selectedValue
                              ? GameColors.onAccent
                              : GameColors.onBackground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
