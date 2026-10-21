import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/util/generic_use_case_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';
import 'package:sudoku/src/modules/game/presentation/screens/main_screen.dart';

import 'fixtures.dart';

class _FakeUseCase implements MainUseCase {
  @override
  MainRepository get repository => throw UnimplementedError();

  @override
  Future<GenericUseCaseResult<SudokuGameModel?>> invoke() async =>
      GenericUseCaseResult(value: testGame(), isSuccessful: true);
}

void main() {
  testWidgets('shows the puzzle difficulty and a running timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => MainBloc(_FakeUseCase()),
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
          create: (_) => MainBloc(_FakeUseCase()),
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
            create: (_) => MainBloc(_FakeUseCase()),
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
