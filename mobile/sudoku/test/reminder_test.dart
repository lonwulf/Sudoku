import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/modules/reminder/domain/model/reminder_settings.dart';
import 'package:sudoku/src/modules/reminder/presentation/bloc/reminder_cubit.dart';

import 'fixtures.dart';

void main() {
  group('ReminderSettings.formatTime', () {
    test('formats 12- and 24-hour times', () {
      const evening = ReminderSettings(enabled: true, hour: 19, minute: 5);
      const midnight = ReminderSettings(enabled: true, hour: 0, minute: 0);
      const noon = ReminderSettings(enabled: true, hour: 12, minute: 30);

      expect(evening.formatTime(use24HourFormat: false), '7:05 PM');
      expect(evening.formatTime(use24HourFormat: true), '19:05');
      expect(midnight.formatTime(use24HourFormat: false), '12:00 AM');
      expect(noon.formatTime(use24HourFormat: false), '12:30 PM');
    });
  });

  group('ReminderCubit', () {
    test('loads saved settings', () async {
      final cubit = ReminderCubit(
        FakeReminderService(
          saved: const ReminderSettings(enabled: true, hour: 8, minute: 15),
        ),
      );

      await cubit.load();

      expect(
        cubit.state,
        const ReminderSettings(enabled: true, hour: 8, minute: 15),
      );
    });

    test('enables and disables, keeping the chosen time', () async {
      final cubit = ReminderCubit(FakeReminderService());

      expect(await cubit.enable(7, 30), isTrue);
      expect(
        cubit.state,
        const ReminderSettings(enabled: true, hour: 7, minute: 30),
      );

      await cubit.disable();
      expect(
        cubit.state,
        const ReminderSettings(enabled: false, hour: 7, minute: 30),
      );
    });

    test('stays off when permission is denied', () async {
      final cubit = ReminderCubit(
        FakeReminderService(permissionGranted: false),
      );

      expect(await cubit.enable(7, 30), isFalse);
      expect(cubit.state.enabled, isFalse);
    });
  });

  group('bell button', () {
    testWidgets('sets, shows and turns off the daily reminder', (tester) async {
      final reminders = FakeReminderService();
      await tester.pumpWidget(testApp(reminders: reminders));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Set daily reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Remind me every day at'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(reminders.saved.enabled, isTrue);
      expect(find.text('Daily reminder set for 7:00 PM'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Daily reminder on at 7:00 PM'),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('Daily reminder on at 7:00 PM'));
      await tester.pumpAndSettle();
      expect(find.text('Every day at 7:00 PM'), findsOneWidget);
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();

      expect(reminders.saved.enabled, isFalse);
      expect(find.bySemanticsLabel('Set daily reminder'), findsOneWidget);
    });

    testWidgets('explains when notification permission is denied', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(reminders: FakeReminderService(permissionGranted: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Set daily reminder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications are off'), findsOneWidget);
      expect(find.bySemanticsLabel('Set daily reminder'), findsOneWidget);
    });
  });
}
