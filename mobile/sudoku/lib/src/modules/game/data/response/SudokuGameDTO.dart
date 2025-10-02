import 'package:json_annotation/json_annotation.dart';
part 'SudokuGameDTO.g.dart';

@JsonSerializable()
class SudokuGameDTO{
  String? id;
  String? difficulty;
  List<List<int>>? puzzle;
  List<List<int>>? solution;


  SudokuGameDTO(this.id, this.difficulty, this.puzzle, this.solution);


  factory SudokuGameDTO.fromJson(Map<String, dynamic> json) =>
      _$SudokuGameDTOFromJson(json);

  Map<String, dynamic> toJson() => _$SudokuGameDTOToJson(this);
}