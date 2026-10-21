import 'package:json_annotation/json_annotation.dart';
part 'leaderboard_dto.g.dart';

/// The backend's LeaderboardResponseDTO.
@JsonSerializable()
class LeaderboardDTO {
  List<LeaderboardEntryDTO>? global;
  LeaderboardEntryDTO? me;
  List<LeaderboardEntryDTO>? nearby;

  /// "ready", or "initializing" while the board is rebuilt.
  String? state;
  String? message;
  int? retryAfterSeconds;

  LeaderboardDTO(
    this.global,
    this.me,
    this.nearby,
    this.state,
    this.message,
    this.retryAfterSeconds,
  );

  factory LeaderboardDTO.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardDTOFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardDTOToJson(this);
}

@JsonSerializable()
class LeaderboardEntryDTO {
  int? rank;
  String? userId;
  String? displayName;
  int? leaderboardScore;

  LeaderboardEntryDTO(
    this.rank,
    this.userId,
    this.displayName,
    this.leaderboardScore,
  );

  factory LeaderboardEntryDTO.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryDTOFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardEntryDTOToJson(this);
}
