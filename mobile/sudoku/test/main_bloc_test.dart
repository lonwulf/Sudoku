import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/core/util/generic_use_case_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';

import 'fixtures.dart';

class _FakeUseCase implements MainUseCase {
  @override
  MainRepository get repository => throw UnimplementedError();

  @override
  Future<GenericUseCaseResult<SudokuGameModel?>> invoke() async =>
      GenericUseCaseResult(value: testGame(), isSuccessful: true);
}

SudokuGameModel _model(MainBloc bloc) =>
    (bloc.state as Success<SudokuGameModel>).value!;

void main() {
  late MainBloc bloc;

  setUp(() async {
    bloc = MainBloc(_FakeUseCase());
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
}
