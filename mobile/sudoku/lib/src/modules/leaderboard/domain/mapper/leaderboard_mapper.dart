import 'package:sudoku/src/modules/leaderboard/data/response/leaderboard_dto.dart';
import 'package:sudoku/src/modules/leaderboard/data/response/player_standing_dto.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_entry.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';

const _unnamed = 'Player';

extension LeaderboardMapper on LeaderboardDTO {
  LeaderboardPage toDomainModel() {
    if (state == 'initializing') {
      return LeaderboardPage(warmingUpRetrySeconds: retryAfterSeconds ?? 5);
    }
    return LeaderboardPage(
      // typed empty lists: with a bare `const []` the entries are dynamic and
      // the mapper extension isn't found
      top: [
        for (final entry in global ?? const <LeaderboardEntryDTO>[])
          entry.toDomainModel(),
      ],
      me: me?.toDomainModel(),
      nearby: [
        for (final entry in nearby ?? const <LeaderboardEntryDTO>[])
          entry.toDomainModel(),
      ],
    );
  }
}

extension LeaderboardEntryMapper on LeaderboardEntryDTO {
  LeaderboardEntry toDomainModel() {
    return LeaderboardEntry(
      rank: rank ?? 0,
      userId: userId ?? '',
      name: displayName ?? _unnamed,
      score: leaderboardScore ?? 0,
    );
  }
}

extension PlayerStandingMapper on PlayerStandingDTO {
  PlayerStanding toDomainModel() {
    return PlayerStanding(
      name: displayName ?? _unnamed,
      score: leaderboardScore ?? 0,
      puzzlesCompleted: puzzlesCompleted ?? 0,
      rank: rank,
    );
  }
}
