/// Infrastructure-level errors thrown by data sources.
///
/// These never cross the repository boundary - repositories map them to
/// [Failure]s. See `docs/ARCHITECTURE.md` for the error contract.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network unavailable', super.cause]);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error', super.cause]);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache read/write failed', super.cause]);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error', super.cause]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found', super.cause]);
}
