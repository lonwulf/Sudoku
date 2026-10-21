import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/modules/reminder/data/reminder_service.dart';
import 'package:sudoku/src/modules/reminder/domain/model/reminder_settings.dart';

/// Daily reminder settings; starts off until the saved settings load.
class ReminderCubit extends Cubit<ReminderSettings> {
  final ReminderService service;

  ReminderCubit(this.service) : super(const ReminderSettings.off());

  Future<void> load() async {
    try {
      final settings = await service.load();
      if (!isClosed) emit(settings);
    } catch (e, stackTrace) {
      LoggerService.logError(e, stackTrace: stackTrace);
    }
  }

  /// Turns the reminder on at [hour]:[minute]. Returns false when
  /// notification permission was denied.
  Future<bool> enable(int hour, int minute) async {
    final granted = await service.enable(hour, minute);
    if (granted && !isClosed) {
      emit(ReminderSettings(enabled: true, hour: hour, minute: minute));
    }
    return granted;
  }

  Future<void> disable() async {
    await service.disable();
    if (!isClosed) {
      emit(
        ReminderSettings(
          enabled: false,
          hour: state.hour,
          minute: state.minute,
        ),
      );
    }
  }
}
