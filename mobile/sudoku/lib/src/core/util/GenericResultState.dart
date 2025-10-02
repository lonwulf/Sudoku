abstract class GenericResultState<T> {
  const GenericResultState();
}

final class Loading<T> extends GenericResultState<T> {
  const Loading();
}

final class Success<T> extends GenericResultState<T> {
  final T? value;
  const Success([this.value]);
}

final class Error<T> extends GenericResultState<T> {
  final String? msg;
  const Error([this.msg]);
}

final class Empty<T> extends GenericResultState<T> {
  const Empty();
}
