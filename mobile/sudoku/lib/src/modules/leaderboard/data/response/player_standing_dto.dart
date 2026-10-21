import 'package:json_annotation/json_annotation.dart';
part 'player_standing_dto.g.dart';

/// The backend's ScoreResponseDTO, as returned by /scores/my_score.
@JsonSerializable()
class PlayerStandingDTO {
  String? userId;
  String? displayName;
  int? puzzlesCompleted;
  int? leaderboardScore;
  int? rank;

  PlayerStandingDTO(
    this.userId,
    this.displayName,
    this.puzzlesCompleted,
    this.leaderboardScore,
    this.rank,
  );

  factory PlayerStandingDTO.fromJson(Map<String, dynamic> json) =>
      _$PlayerStandingDTOFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerStandingDTOToJson(this);
}
