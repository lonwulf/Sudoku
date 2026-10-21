// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardDTO _$LeaderboardDTOFromJson(Map<String, dynamic> json) =>
    LeaderboardDTO(
      (json['global'] as List<dynamic>?)
          ?.map((e) => LeaderboardEntryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['me'] == null
          ? null
          : LeaderboardEntryDTO.fromJson(json['me'] as Map<String, dynamic>),
      (json['nearby'] as List<dynamic>?)
          ?.map((e) => LeaderboardEntryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['state'] as String?,
      json['message'] as String?,
      (json['retryAfterSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LeaderboardDTOToJson(LeaderboardDTO instance) =>
    <String, dynamic>{
      'global': instance.global,
      'me': instance.me,
      'nearby': instance.nearby,
      'state': instance.state,
      'message': instance.message,
      'retryAfterSeconds': instance.retryAfterSeconds,
    };

LeaderboardEntryDTO _$LeaderboardEntryDTOFromJson(Map<String, dynamic> json) =>
    LeaderboardEntryDTO(
      (json['rank'] as num?)?.toInt(),
      json['userId'] as String?,
      json['displayName'] as String?,
      (json['leaderboardScore'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LeaderboardEntryDTOToJson(
  LeaderboardEntryDTO instance,
) => <String, dynamic>{
  'rank': instance.rank,
  'userId': instance.userId,
  'displayName': instance.displayName,
  'leaderboardScore': instance.leaderboardScore,
};
