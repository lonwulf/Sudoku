import 'package:equatable/equatable.dart';

class ReminderSettings extends Equatable {
  static const defaultHour = 19;
  static const defaultMinute = 0;

  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    this.hour = defaultHour,
    this.minute = defaultMinute,
  });

  const ReminderSettings.off() : this(enabled: false);

  /// The reminder time as text, e.g. `19:00` or `7:00 PM`.
  String formatTime({required bool use24HourFormat}) {
    final mm = minute.toString().padLeft(2, '0');
    if (use24HourFormat) return '${hour.toString().padLeft(2, '0')}:$mm';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$mm ${hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  List<Object?> get props => [enabled, hour, minute];
}
