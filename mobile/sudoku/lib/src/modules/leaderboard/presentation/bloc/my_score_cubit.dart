import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/fetch_outcome.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_my_score_use_case.dart';

enum MyScoreStatus { loading, ready, signInRequired, failed }

class MyScoreState extends Equatable {
  final MyScoreStatus status;
  final PlayerStanding? standing;
  final String? message;

  const MyScoreState({
    this.status = MyScoreStatus.loading,
    this.standing,
    this.message,
  });

  @override
  List<Object?> get props => [status, standing, message];
}

class MyScoreCubit extends Cubit<MyScoreState> {
  final GetMyScoreUseCase useCase;

  MyScoreCubit(this.useCase) : super(const MyScoreState());

  /// A [refresh] keeps the current totals on screen while reloading.
  Future<void> load({bool refresh = false}) async {
    if (!refresh || state.status != MyScoreStatus.ready) {
      emit(const MyScoreState());
    }
    FetchOutcome<PlayerStanding> outcome;
    try {
      outcome = await useCase.invoke();
    } catch (e, stackTrace) {
      LoggerService.logError(e, stackTrace: stackTrace);
      outcome = const FetchFailed(GetMyScoreUseCase.failedMessage);
    }
    if (isClosed) return;
    emit(switch (outcome) {
      Fetched(:final value) => MyScoreState(
        status: MyScoreStatus.ready,
        standing: value,
      ),
      NeedsSignIn() => const MyScoreState(status: MyScoreStatus.signInRequired),
      FetchFailed(:final message) => MyScoreState(
        status: MyScoreStatus.failed,
        message: message,
      ),
    });
  }
}
