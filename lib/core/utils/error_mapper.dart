import '../error/exceptions.dart';
import '../error/failures.dart';

/// Single translation point from infrastructure exceptions to domain failures.
Failure mapErrorToFailure(Object error, [StackTrace? stackTrace]) {
  return switch (error) {
    NetworkException(:final String message) => NetworkFailure(message, error),
    AuthException(:final String message) => AuthFailure(message, error),
    NotFoundException(:final String message) => NotFoundFailure(message, error),
    CacheException(:final String message) => CacheFailure(message, error),
    ServerException(:final String message) => ServerFailure(message, error),
    Failure() => error,
    _ => ServerFailure(
        'Unexpected error. Please try again.',
        error,
      ),
  };
}
