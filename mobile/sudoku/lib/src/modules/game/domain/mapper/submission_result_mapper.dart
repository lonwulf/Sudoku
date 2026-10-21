import 'package:sudoku/src/modules/game/data/response/submission_result_dto.dart';
import 'package:sudoku/src/modules/game/domain/model/submission_result.dart';

extension SubmissionResultMapper on SubmissionResultDTO {
  SubmissionResult toDomainModel() {
    return SubmissionResult(
      score: leaderboardScore ?? 0,
      puzzlesCompleted: puzzlesCompleted ?? 0,
      rank: rank,
    );
  }
}
