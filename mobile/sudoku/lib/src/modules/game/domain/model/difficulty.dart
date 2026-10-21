enum Difficulty {
  easy,
  medium,
  hard;

  String get label => name[0].toUpperCase() + name.substring(1);
}
