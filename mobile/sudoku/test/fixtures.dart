import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sudoku/src/core/util/generic_use_case_result.dart';
import 'package:sudoku/src/core/util/network_monitor.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';

const testPuzzle = [
  [0, 2, 0, 0, 0, 0, 7, 0, 9],
  [4, 0, 0, 7, 0, 9, 0, 2, 3],
  [7, 8, 0, 0, 0, 0, 0, 5, 0],
  [0, 0, 0, 0, 6, 0, 0, 0, 7],
  [3, 0, 5, 8, 9, 0, 0, 1, 0],
  [8, 0, 0, 2, 0, 0, 3, 6, 5],
  [0, 3, 1, 6, 0, 2, 0, 0, 0],
  [0, 0, 2, 9, 0, 0, 0, 3, 0],
  [9, 0, 0, 5, 3, 1, 0, 4, 2],
];

const testSolution = [
  [1, 2, 3, 4, 5, 6, 7, 8, 9],
  [4, 5, 6, 7, 8, 9, 1, 2, 3],
  [7, 8, 9, 1, 2, 3, 4, 5, 6],
  [2, 1, 4, 3, 6, 5, 8, 9, 7],
  [3, 6, 5, 8, 9, 7, 2, 1, 4],
  [8, 9, 7, 2, 1, 4, 3, 6, 5],
  [5, 3, 1, 6, 4, 2, 9, 7, 8],
  [6, 4, 2, 9, 7, 8, 5, 3, 1],
  [9, 7, 8, 5, 3, 1, 6, 4, 2],
];

SudokuGameModel testGame() => SudokuGameModel(
  id: 'test',
  difficulty: 'medium',
  puzzle: [
    for (final row in testPuzzle) [...row],
  ],
  solution: testSolution,
);

class FakeUseCase implements MainUseCase {
  int calls = 0;

  @override
  MainRepository get repository => throw UnimplementedError();

  @override
  Future<GenericUseCaseResult<SudokuGameModel?>> invoke() async {
    calls++;
    return GenericUseCaseResult(value: testGame(), isSuccessful: true);
  }
}

/// Stands in for the connectivity_plus plugin, which has no platform
/// implementation in tests.
class FakeConnectivity implements Connectivity {
  List<ConnectivityResult> current = [ConnectivityResult.wifi];
  final changes = StreamController<List<ConnectivityResult>>.broadcast();

  void setOnline(bool online) {
    current = [online ? ConnectivityResult.wifi : ConnectivityResult.none];
    changes.add(current);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;
}

MainBloc testBloc({FakeUseCase? useCase, FakeConnectivity? connectivity}) =>
    MainBloc(
      useCase ?? FakeUseCase(),
      NetworkMonitor(connectivity: connectivity ?? FakeConnectivity()),
    );
