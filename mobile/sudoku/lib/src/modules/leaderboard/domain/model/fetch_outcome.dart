import 'package:equatable/equatable.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/core/util/api_status.dart';

/// Result of loading something only signed-in players can see.
sealed class FetchOutcome<T> extends Equatable {
  const FetchOutcome();

  /// 401 means sign in; other client errors carry the server's message;
  /// anything else (offline, 5xx) gets [failedMessage].
  factory FetchOutcome.from(APIResult<T> result, String failedMessage) {
    switch (result.status) {
      case APIStatus.success:
        return Fetched(result.result as T);
      case APIStatus.error:
        final code = result.code;
        if (code == 401) return NeedsSignIn<T>();
        if (code != null && code >= 400 && code < 500) {
          return FetchFailed<T>(result.msg ?? failedMessage);
        }
        return FetchFailed<T>(failedMessage);
    }
  }

  @override
  List<Object?> get props => [];
}

final class Fetched<T> extends FetchOutcome<T> {
  final T value;

  const Fetched(this.value);

  @override
  List<Object?> get props => [value];
}

final class NeedsSignIn<T> extends FetchOutcome<T> {
  const NeedsSignIn();
}

final class FetchFailed<T> extends FetchOutcome<T> {
  final String message;

  const FetchFailed(this.message);

  @override
  List<Object?> get props => [message];
}
