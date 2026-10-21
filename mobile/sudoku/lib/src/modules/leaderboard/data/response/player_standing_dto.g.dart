// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_standing_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerStandingDTO _$PlayerStandingDTOFromJson(Map<String, dynamic> json) =>
    PlayerStandingDTO(
      json['userId'] as String?,
      json['displayName'] as String?,
      (json['puzzlesCompleted'] as num?)?.toInt(),
      (json['leaderboardScore'] as num?)?.toInt(),
      (json['rank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlayerStandingDTOToJson(PlayerStandingDTO instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'puzzlesCompleted': instance.puzzlesCompleted,
      'leaderboardScore': instance.leaderboardScore,
      'rank': instance.rank,
    };
