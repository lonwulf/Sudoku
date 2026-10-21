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
