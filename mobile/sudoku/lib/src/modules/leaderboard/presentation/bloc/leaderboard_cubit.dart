import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/fetch_outcome.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_entry.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_leaderboard_use_case.dart';

enum LeaderboardStatus { loading, ready, warmingUp, signInRequired, failed }

class LeaderboardState extends Equatable {
  final LeaderboardStatus status;
  final List<LeaderboardEntry> top;
  final LeaderboardEntry? me;
  final List<LeaderboardEntry> nearby;

  /// The last page was full, so there may be more players below.
  final bool hasMore;
  final bool loadingMore;

  /// Loading the next page failed; scrolling or Retry tries again.
  final bool loadMoreFailed;
  final String? message;

  const LeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.top = const [],
    this.me,
    this.nearby = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.message,
  });

  /// The player is below the loaded part of the board, so the players
  /// around them are shown separately.
  bool get showNearby {
    final me = this.me;
    return me != null && nearby.isNotEmpty && me.rank > top.length;
  }

  LeaderboardState copyWith({
    List<LeaderboardEntry>? top,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => LeaderboardState(
    status: status,
    top: top ?? this.top,
    me: me,
    nearby: nearby,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    top,
    me,
    nearby,
    hasMore,
    loadingMore,
    loadMoreFailed,
    message,
  ];
}

class LeaderboardCubit extends Cubit<LeaderboardState> {
  static const pageSize = 20;
  static const warmingUpMessage =
      'The leaderboard is being prepared. It will appear in a moment.';

  final GetLeaderboardUseCase useCase;
  Timer? _retryTimer;

  LeaderboardCubit(this.useCase) : super(const LeaderboardState());

  /// Loads the first page. A [refresh] keeps the current list on screen
  /// until the new one arrives.
  Future<void> load({bool refresh = false}) async {
    _retryTimer?.cancel();
    if (!refresh || state.status != LeaderboardStatus.ready) {
      emit(const LeaderboardState());
    }
    final outcome = await _fetch(0);
    if (isClosed) return;
    switch (outcome) {
      case Fetched(value: final page) when page.warmingUp:
        emit(
          const LeaderboardState(
            status: LeaderboardStatus.warmingUp,
            message: warmingUpMessage,
          ),
        );
        _retryTimer = Timer(
          Duration(seconds: page.warmingUpRetrySeconds!),
          load,
        );
      case Fetched(value: final page):
        emit(
          LeaderboardState(
            status: LeaderboardStatus.ready,
            top: page.top,
            me: page.me,
            nearby: page.nearby,
            hasMore: page.top.length == pageSize,
          ),
        );
      case NeedsSignIn():
        emit(const LeaderboardState(status: LeaderboardStatus.signInRequired));
      case FetchFailed(:final message):
        emit(
          LeaderboardState(status: LeaderboardStatus.failed, message: message),
        );
    }
  }

  Future<void> loadMore() async {
    if (state.status != LeaderboardStatus.ready ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    final outcome = await _fetch(state.top.length ~/ pageSize);
    if (isClosed) return;
    if (outcome case Fetched(value: final page) when !page.warmingUp) {
      // players can move up between pages; don't list anyone twice
      final shown = {for (final entry in state.top) entry.userId};
      final added = page.top.where((entry) => !shown.contains(entry.userId));
      emit(
        state.copyWith(
          top: [...state.top, ...added],
          hasMore: page.top.length == pageSize,
          loadingMore: false,
        ),
      );
    } else {
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  Future<FetchOutcome<LeaderboardPage>> _fetch(int page) async {
    try {
      return await useCase.invoke(page, pageSize);
    } catch (e, stackTrace) {
      LoggerService.logError(e, stackTrace: stackTrace);
      return const FetchFailed(GetLeaderboardUseCase.failedMessage);
    }
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    return super.close();
  }
}
