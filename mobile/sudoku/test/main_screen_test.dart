import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/modules/game/presentation/screens/main_screen.dart';

import 'fixtures.dart';

void main() {
  testWidgets('shows the puzzle difficulty and a running timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => testBloc(),
          child: const MainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('cells and keys are labelled and entering a number works', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => testBloc(),
          child: const MainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Row 1, column 2, 2, given'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));
    await tester.tap(find.bySemanticsLabel('Enter 5'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Row 1, column 1, 5, incorrect'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Enter 1'));
    await tester.pump();
    expect(find.bySemanticsLabel('Row 1, column 1, 1'), findsOneWidget);
  });

  testWidgets('action buttons drive notes, undo, hint and erase', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => testBloc(),
          child: const MainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));
    await tester.tap(find.bySemanticsLabel('Notes'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Enter 4'));
    await tester.tap(find.bySemanticsLabel('Enter 6'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Row 1, column 1, empty, notes 4 6'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Undo'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Row 1, column 1, empty, notes 4'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Hint'));
    await tester.pump();
    expect(find.bySemanticsLabel('Row 1, column 1, 1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Erase'));
    await tester.pump();
    expect(find.bySemanticsLabel('Row 1, column 1, empty'), findsOneWidget);
  });

  group('pause', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => testBloc(),
            child: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('hides the board and blocks input until resumed', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));

      await tester.tap(find.bySemanticsLabel('Pause'));
      await tester.pump();
      expect(find.text('Paused'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Row ')), findsNothing);

      await tester.tap(find.bySemanticsLabel('Enter 5'), warnIfMissed: false);
      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(find.text('Paused'), findsNothing);
      expect(find.bySemanticsLabel('Row 1, column 1, empty'), findsOneWidget);
    });

    testWidgets('is paused on return after the app was hidden', (tester) async {
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpScreen(tester);

      // Frames stop while hidden, so check after coming back.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('Paused'), findsOneWidget);
    });
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(412, 915)]) {
    testWidgets('main screen fits a ${size.width}x${size.height} screen', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => testBloc(),
            child: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Undo'), findsOneWidget);
    });
  }
}
