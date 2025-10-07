class GenericUseCaseResult<T> {
  final T value;
  final bool isSuccessful;
  final String msg;

  GenericUseCaseResult({
    required this.value,
    required this.isSuccessful,
    this.msg = '',
  });

  @override
  String toString() {
    return 'UseCase val = [value: $value, isSuccessful: $isSuccessful, msg: $msg]';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenericUseCaseResult<T> &&
        other.value == value &&
        other.isSuccessful == isSuccessful &&
        other.msg == msg;
  }

  @override
  int get hashCode => value.hashCode ^ isSuccessful.hashCode ^ msg.hashCode;
}
