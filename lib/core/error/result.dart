import 'failure.dart';

/// Functional result wrapper. Prefer this over throwing from repositories.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Err() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Err(:final failure) => failure,
      };

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Success<R>(transform(value)),
      Err(:final failure) => Err<R>(failure),
    };
  }

  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    return switch (this) {
      Success(:final value) => transform(value),
      Err(:final failure) => Err<R>(failure),
    };
  }

  R fold<R>({
    required R Function(Failure failure) onErr,
    required R Function(T value) onSuccess,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Err(:final failure) => onErr(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
