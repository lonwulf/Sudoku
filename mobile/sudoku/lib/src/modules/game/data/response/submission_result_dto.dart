import 'package:json_annotation/json_annotation.dart';
part 'submission_result_dto.g.dart';

/// The backend's ScoreResponseDTO.
@JsonSerializable()
class SubmissionResultDTO {
  String? userId;
  String? displayName;
  int? puzzlesCompleted;
  int? leaderboardScore;
  int? rank;

  SubmissionResultDTO(
    this.userId,
    this.displayName,
    this.puzzlesCompleted,
    this.leaderboardScore,
    this.rank,
  );

  factory SubmissionResultDTO.fromJson(Map<String, dynamic> json) =>
      _$SubmissionResultDTOFromJson(json);

  Map<String, dynamic> toJson() => _$SubmissionResultDTOToJson(this);
}
