import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';

import 'fixtures.dart';

SudokuGameModel _model(MainBloc bloc) =>
    (bloc.state as Success<SudokuGameModel>).value!;

void main() {
  group('entering numbers', () {
    late MainBloc bloc;

    setUp(() async {
      bloc = testBloc();
      await bloc.fetchSudokuChallenge();
    });

    tearDown(() => bloc.close());

    test('enterNumber fills an empty cell and emits a new state', () {
      final before = _model(bloc);

      bloc.enterNumber(0, 0, 1);

      expect(_model(bloc).board[0][0], 1);
      expect(_model(bloc), isNot(before));
      expect(before.board[0][0], 0);
      expect(_model(bloc).puzzle[0][0], 0);
    });

    test('enterNumber ignores given cells', () {
      final before = _model(bloc);

      bloc.enterNumber(0, 1, 5);

      expect(_model(bloc), before);
      expect(_model(bloc).board[0][1], 2);
    });

    test('board cannot be mutated directly', () {
      expect(() => _model(bloc).board[0][0] = 1, throwsUnsupportedError);
    });
  });

  group('undo, notes, hint and erase', () {
    late MainBloc bloc;

    setUp(() async {
      bloc = testBloc();
      await bloc.fetchSudokuChallenge();
    });

    tearDown(() => bloc.close());

    test('undo reverts changes one at a time', () {
      expect(bloc.canUndo, isFalse);

      bloc.enterNumber(0, 0, 5);
      bloc.enterNumber(0, 0, 1);
      bloc.undo();
      expect(_model(bloc).board[0][0], 5);

      bloc.undo();
      expect(_model(bloc).board[0][0], 0);
      expect(bloc.canUndo, isFalse);
    });

    test('changes that do nothing are not added to the undo history', () {
      bloc.enterNumber(0, 1, 5); // given cell
      bloc.erase(0, 0); // already empty

      expect(bloc.canUndo, isFalse);
    });

    test('notes toggle on empty cells only', () {
      bloc.toggleNote(0, 0, 3);
      bloc.toggleNote(0, 0, 4);
      bloc.toggleNote(0, 0, 3);
      bloc.toggleNote(0, 1, 3); // given cell

      expect(_model(bloc).notesAt(0, 0), {4});
      expect(_model(bloc).notesAt(0, 1), isEmpty);
    });

    test('entering a value clears its notes and the digit from peers', () {
      bloc.toggleNote(0, 0, 1);
      bloc.toggleNote(0, 2, 3); // same row
      bloc.toggleNote(2, 2, 3); // same box
      bloc.toggleNote(8, 1, 3); // unrelated empty cell

      bloc.enterNumber(0, 0, 3);

      expect(_model(bloc).notesAt(0, 0), isEmpty);
      expect(_model(bloc).notesAt(0, 2), isEmpty);
      expect(_model(bloc).notesAt(2, 2), isEmpty);
      expect(_model(bloc).notesAt(8, 1), {3});
    });

    test('erase clears a value and notes but not givens', () {
      bloc.enterNumber(0, 0, 5);
      bloc.erase(0, 0);
      bloc.erase(0, 1);

      expect(_model(bloc).board[0][0], 0);
      expect(_model(bloc).board[0][1], 2);
    });

    test('hint fills the selected cell with its solution', () {
      expect(bloc.hint(2), 2);
      expect(_model(bloc).board[0][2], 3);
    });

    test('hint falls back to the first cell that needs one', () {
      bloc.enterNumber(0, 0, 1); // correct already

      expect(bloc.hint(0), 2);
      expect(bloc.hint(null), 3);
      expect(_model(bloc).board[0][3], 4);
    });

    test('hint does nothing on a solved board', () {
      for (var i = 0; i < 81; i++) {
        bloc.enterNumber(i ~/ 9, i % 9, testSolution[i ~/ 9][i % 9]);
      }

      expect(bloc.hint(null), isNull);
    });
  });

  group('connectivity', () {
    late FakeConnectivity connectivity;
    late FakeUseCase useCase;
    late MainBloc bloc;

    setUp(() {
      connectivity = FakeConnectivity();
      useCase = FakeUseCase();
      bloc = testBloc(useCase: useCase, connectivity: connectivity);
    });

    tearDown(() => bloc.close());

    test(
      'fails with a no-connection message without calling the API',
      () async {
        connectivity.setOnline(false);

        await bloc.fetchSudokuChallenge();

        expect(bloc.state, isA<Failure<SudokuGameModel>>());
        expect(
          (bloc.state as Failure<SudokuGameModel>).msg,
          MainBloc.noConnectionMessage,
        );
        expect(useCase.calls, 0);
      },
    );

    test('loads the puzzle once the connection comes back', () async {
      connectivity.setOnline(false);
      await bloc.fetchSudokuChallenge();

      connectivity.setOnline(true);
      await pumpEventQueue();

      expect(bloc.state, isA<Success<SudokuGameModel>>());
      expect(useCase.calls, 1);
    });

    test('keeps a loaded puzzle when the connection drops', () async {
      await bloc.fetchSudokuChallenge();
      bloc.enterNumber(0, 0, 1);

      connectivity.setOnline(false);
      await pumpEventQueue();
      connectivity.setOnline(true);
      await pumpEventQueue();

      expect(_model(bloc).board[0][0], 1);
      expect(useCase.calls, 1);
    });
  });
}
