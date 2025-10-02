// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SudokuGameDTO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SudokuGameDTO _$SudokuGameDTOFromJson(
  Map<String, dynamic> json,
) => SudokuGameDTO(
  json['id'] as String?,
  json['difficulty'] as String?,
  (json['puzzle'] as List<dynamic>?)
      ?.map((e) => (e as List<dynamic>).map((e) => (e as num).toInt()).toList())
      .toList(),
  (json['solution'] as List<dynamic>?)
      ?.map((e) => (e as List<dynamic>).map((e) => (e as num).toInt()).toList())
      .toList(),
);

Map<String, dynamic> _$SudokuGameDTOToJson(SudokuGameDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'difficulty': instance.difficulty,
      'puzzle': instance.puzzle,
      'solution': instance.solution,
    };
