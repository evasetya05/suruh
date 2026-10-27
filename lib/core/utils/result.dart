import '../error/failures.dart';
import 'error_mapper.dart';

/// A lightweight `Either`-style result used as the return type of every
/// repository and use case.
///
/// Chosen over throwing so that failure handling is part of the type signature
/// and the presentation layer cannot forget an error path.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  /// Value if successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
        Success<T>(:final T value) => value,
        FailureResult<T>() => null,
      };

  /// Failure if unsuccessful, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        FailureResult<T>(:final Failure failure) => failure,
      };

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) =>
      switch (this) {
        Success<T>(:final T value) => onSuccess(value),
        FailureResult<T>(:final Failure failure) => onFailure(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final T value) => Result<R>.success(transform(value)),
        FailureResult<T>(:final Failure failure) => Result<R>.failure(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}

/// Runs [body], converting any [AppException] into the matching [Failure].
///
/// Repositories use this so exception-to-failure mapping lives in exactly one
/// place.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Result<T>.success(await body());
  } on Object catch (error, stackTrace) {
    return Result<T>.failure(mapErrorToFailure(error, stackTrace));
  }
}
