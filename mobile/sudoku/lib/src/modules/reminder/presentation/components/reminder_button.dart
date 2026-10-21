import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/modules/reminder/domain/model/reminder_settings.dart';
import 'package:sudoku/src/modules/reminder/presentation/bloc/reminder_cubit.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// App bar bell: sets up, changes or turns off the daily reminder.
class ReminderButton extends StatelessWidget {
  const ReminderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReminderCubit>().state;
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    return Semantics(
      button: true,
      label: settings.enabled
          ? 'Daily reminder on at ${settings.formatTime(use24HourFormat: use24h)}'
          : 'Set daily reminder',
      excludeSemantics: true,
      child: PlatformIconButton(
        icon: Icon(
          settings.enabled
              ? context.platformIcon(
                  material: Icons.notifications_active,
                  cupertino: CupertinoIcons.bell_fill,
                )
              : context.platformIcon(
                  material: Icons.notifications_outlined,
                  cupertino: CupertinoIcons.bell,
                ),
          color: settings.enabled ? GameColors.accent : GameColors.onBackground,
        ),
        onPressed: () => settings.enabled
            ? _showReminderOptions(context, settings)
            : _setReminder(context, settings),
      ),
    );
  }

  Future<void> _setReminder(
    BuildContext context,
    ReminderSettings current,
  ) async {
    final time = await _pickTime(context, current.hour, current.minute);
    if (time == null || !context.mounted) return;

    final cubit = context.read<ReminderCubit>();
    final granted = await cubit.enable(time.hour, time.minute);
    if (!context.mounted) return;
    if (granted) {
      final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
      _showMessage(
        context,
        'Daily reminder set for '
        '${cubit.state.formatTime(use24HourFormat: use24h)}',
      );
    } else {
      await showPlatformDialog<void>(
        context: context,
        builder: (dialogContext) => PlatformAlertDialog(
          title: const Text('Notifications are off'),
          content: const Text(
            'Allow notifications for Sudoku in your device settings to get '
            'a daily reminder.',
          ),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showReminderOptions(
    BuildContext context,
    ReminderSettings current,
  ) async {
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final action = await showPlatformDialog<_ReminderAction>(
      context: context,
      builder: (dialogContext) => PlatformAlertDialog(
        title: const Text('Daily reminder'),
        content: Text(
          'Every day at ${current.formatTime(use24HourFormat: use24h)}',
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ReminderAction.turnOff),
            cupertino: (_, __) =>
                CupertinoDialogActionData(isDestructiveAction: true),
            child: const Text('Turn off'),
          ),
          PlatformDialogAction(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ReminderAction.changeTime),
            child: const Text('Change time'),
          ),
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _ReminderAction.turnOff:
        await context.read<ReminderCubit>().disable();
        if (context.mounted) _showMessage(context, 'Daily reminder off');
      case _ReminderAction.changeTime:
        await _setReminder(context, current);
      case null:
        break;
    }
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, int hour, int minute) {
    final initial = TimeOfDay(hour: hour, minute: minute);
    if (isMaterial(context)) {
      return showTimePicker(
        context: context,
        initialTime: initial,
        helpText: 'Remind me every day at',
      );
    }
    var picked = initial;
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (popupContext) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(popupContext),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.of(popupContext).pop(picked),
                child: const Text('Done'),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2000, 1, 1, hour, minute),
                onDateTimeChanged: (value) =>
                    picked = TimeOfDay(hour: value.hour, minute: value.minute),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    // Cupertino has no snack bar; the bell's state shows the change there.
    if (isMaterial(context)) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

enum _ReminderAction { turnOff, changeTime }
