import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/reminder/data/reminder_service.dart';

void setupReminderModuleDependencies() {
  getIt.registerLazySingleton<ReminderService>(() => LocalReminderService());
}
