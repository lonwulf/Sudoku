import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// A centred message for loading problems, with an optional action.
class StatusMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool busy;
  final bool error;

  const StatusMessage(
    this.message, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.busy = false,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: error ? GameColors.errorText : GameColors.muted,
                fontSize: 16,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              PlatformTextButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
