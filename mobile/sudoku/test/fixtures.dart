import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/core/util/generic_use_case_result.dart';
import 'package:sudoku/src/core/util/network_monitor.dart';
import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/auth/data/auth_service.dart';
import 'package:sudoku/src/modules/auth/domain/model/auth_user.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';
import 'package:sudoku/src/modules/game/domain/model/difficulty.dart';
import 'package:sudoku/src/modules/game/domain/model/submission_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';
import 'package:sudoku/src/modules/game/domain/usecase/submit_solution_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/submit_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_entry.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';
import 'package:sudoku/src/modules/leaderboard/domain/repository/leaderboard_repository.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_leaderboard_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_my_score_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/screens/main_screen.dart';
import 'package:sudoku/src/modules/reminder/data/reminder_service.dart';
import 'package:sudoku/src/modules/reminder/domain/model/reminder_settings.dart';
import 'package:sudoku/src/modules/reminder/presentation/bloc/reminder_cubit.dart';

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

/// Solved except row 1, column 1, whose answer is 1.
SudokuGameModel nearlySolvedGame() => SudokuGameModel(
  id: 'nearly',
  difficulty: 'easy',
  puzzle: [
    for (final row in testSolution) [...row],
  ]..[0][0] = 0,
  solution: testSolution,
);

const testUser = AuthUser(id: 'sub-1', name: 'Test Player');

class FakeUseCase implements MainUseCase {
  final SudokuGameModel Function() game;
  int calls = 0;
  Difficulty? lastDifficulty;

  FakeUseCase({this.game = testGame});

  @override
  MainRepository get repository => throw UnimplementedError();

  @override
  Future<GenericUseCaseResult<SudokuGameModel?>> invoke(
    Difficulty difficulty,
  ) async {
    calls++;
    lastDifficulty = difficulty;
    return GenericUseCaseResult(value: game(), isSuccessful: true);
  }
}

class FakeAuthService implements AuthService {
  AuthUser? user;

  /// Who [signIn] signs in; null acts like the player closing the page.
  AuthUser? signInAs;
  int signIns = 0;
  final _changes = StreamController<AuthUser?>.broadcast();

  FakeAuthService({this.user, this.signInAs = testUser});

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<AuthUser?> restore() async => user;

  @override
  Future<AuthUser?> signIn() async {
    signIns++;
    if (signInAs != null) {
      user = signInAs;
      _changes.add(user);
    }
    return signInAs;
  }

  @override
  Future<void> signOut() async {
    user = null;
    _changes.add(null);
  }

  @override
  Future<String?> accessToken() async => user == null ? null : 'token';
}

/// Records submits and answers them with [submitResult].
class FakeMainRepository implements MainRepository {
  APIResult<SubmissionResult> submitResult;
  final submitted = <String>[];

  FakeMainRepository({APIResult<SubmissionResult>? submitResult})
    : submitResult =
          submitResult ??
          APIResult.success(
            const SubmissionResult(score: 40, puzzlesCompleted: 3, rank: 2),
          );

  @override
  Future<APIResult<SudokuGameModel>> fetchChallenge(
    Difficulty difficulty,
  ) async => APIResult.success(testGame());

  @override
  Future<APIResult<SubmissionResult>> submitSolution(
    String id,
    List<List<int>> board,
  ) async {
    submitted.add(id);
    return submitResult;
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

class FakeReminderService implements ReminderService {
  ReminderSettings saved;
  bool permissionGranted;

  FakeReminderService({
    this.saved = const ReminderSettings.off(),
    this.permissionGranted = true,
  });

  @override
  Future<ReminderSettings> load() async => saved;

  @override
  Future<bool> enable(int hour, int minute) async {
    if (!permissionGranted) return false;
    saved = ReminderSettings(enabled: true, hour: hour, minute: minute);
    return true;
  }

  @override
  Future<void> disable() async {
    saved = ReminderSettings(
      enabled: false,
      hour: saved.hour,
      minute: saved.minute,
    );
  }
}

/// MainScreen with its blocs, as SudokuApp provides them.
Widget testApp({
  MainBloc? bloc,
  ReminderService? reminders,
  FakeAuthService? auth,
  FakeMainRepository? repository,
}) {
  final authService = auth ?? FakeAuthService();
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => bloc ?? testBloc()),
        BlocProvider(
          create: (_) =>
              ReminderCubit(reminders ?? FakeReminderService())..load(),
        ),
        BlocProvider(create: (_) => AuthCubit(authService)..restore()),
        BlocProvider(
          create: (_) => SubmitCubit(
            SubmitSolutionUseCase(
              repository ?? FakeMainRepository(),
              authService,
            ),
          ),
        ),
      ],
      child: const MainScreen(),
    ),
  );
}

/// Players ranked [from] onwards, with user ids `u1`, `u2`, ...
List<LeaderboardEntry> testEntries(int from, int count) => [
  for (var rank = from; rank < from + count; rank++)
    LeaderboardEntry(
      rank: rank,
      userId: 'u$rank',
      name: 'Player $rank',
      score: 1000 - rank,
    ),
];

const testStanding = PlayerStanding(
  name: 'Test Player',
  score: 70,
  puzzlesCompleted: 4,
  rank: 3,
);

/// Answers leaderboard pages from [pages] (missing pages are empty) and
/// the player's score from [myScore], recording the pages asked for.
class FakeLeaderboardRepository implements LeaderboardRepository {
  final Map<int, APIResult<LeaderboardPage>> pages;
  APIResult<PlayerStanding> myScore;
  final requestedPages = <int>[];

  FakeLeaderboardRepository({
    Map<int, APIResult<LeaderboardPage>>? pages,
    APIResult<PlayerStanding>? myScore,
  }) : pages = pages ?? {},
       myScore = myScore ?? APIResult.success(testStanding);

  @override
  Future<APIResult<LeaderboardPage>> fetchLeaderboard(
    int page,
    int size,
  ) async {
    requestedPages.add(page);
    return pages[page] ?? APIResult.success(const LeaderboardPage());
  }

  @override
  Future<APIResult<PlayerStanding>> fetchMyScore() async => myScore;
}

/// What the leaderboard and score screens resolve through getIt when
/// opened; undo with `getIt.reset()`.
void registerLeaderboard(FakeLeaderboardRepository repository) {
  getIt
    ..registerFactory(() => GetLeaderboardUseCase(repository))
    ..registerFactory(() => GetMyScoreUseCase(repository));
}
