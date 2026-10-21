import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/auth/data/auth_service.dart';

void setupAuthModuleDependencies() {
  getIt.registerLazySingleton<AuthService>(() => AppAuthService());
}
