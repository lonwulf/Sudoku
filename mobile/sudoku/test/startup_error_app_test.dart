import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/app/startup_error_app.dart';

void main() {
  testWidgets('shows the startup error instead of a blank screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      StartupErrorApp(error: StateError('API_BASE_URL is not set.')),
    );

    expect(find.text('API_BASE_URL is not set.'), findsOneWidget);
  });
}
