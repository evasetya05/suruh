part of 'auth_bloc.dart';

enum AuthStatus {
  /// Session restore has not finished - the splash screen waits on this.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.infoMessage,
  });

  final AuthStatus status;
  final User? user;

  /// True while a sign-in / register / reset request is in flight.
  final bool isSubmitting;
  final String? errorMessage;
  final String? infoMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isResolved => status != AuthStatus.unknown;

  UserRole get role => user?.role ?? UserRole.customer;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isSubmitting,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      // Signing out emits a fresh AuthState rather than copying, so `user` is
      // never cleared here by accident.
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearMessages ? null : (infoMessage ?? this.infoMessage),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, user, isSubmitting, errorMessage, infoMessage];
}
