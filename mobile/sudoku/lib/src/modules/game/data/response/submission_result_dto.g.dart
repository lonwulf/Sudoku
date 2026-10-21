// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmissionResultDTO _$SubmissionResultDTOFromJson(Map<String, dynamic> json) =>
    SubmissionResultDTO(
      json['userId'] as String?,
      json['displayName'] as String?,
      (json['puzzlesCompleted'] as num?)?.toInt(),
      (json['leaderboardScore'] as num?)?.toInt(),
      (json['rank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SubmissionResultDTOToJson(
  SubmissionResultDTO instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'displayName': instance.displayName,
  'puzzlesCompleted': instance.puzzlesCompleted,
  'leaderboardScore': instance.leaderboardScore,
  'rank': instance.rank,
};
