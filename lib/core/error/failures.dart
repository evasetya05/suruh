import 'package:equatable/equatable.dart';

/// A domain-level error.
///
/// Data sources throw [AppException]s; repositories translate them into
/// [Failure]s so the domain and presentation layers never import
/// infrastructure types (Firebase, http, sqlite, ...).
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  /// Human-readable, safe to show in the UI.
  final String message;

  /// Original error, for logging only.
  final Object? cause;

  @override
  List<Object?> get props => <Object?>[message, runtimeType];

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Showing saved data.',
    Object? cause,
  ]) : super(cause: cause);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
    Object? cause,
  ]) : super(cause: cause);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Could not read saved data.',
    Object? cause,
  ]) : super(cause: cause);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed.',
    Object? cause,
  ]) : super(cause: cause);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'We could not find what you were looking for.',
    Object? cause,
  ]) : super(cause: cause);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}
