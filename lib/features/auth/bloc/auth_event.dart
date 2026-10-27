part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Fired once at app start to restore a persisted session.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => <Object?>[email, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.role = UserRole.customer,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final UserRole role;

  @override
  List<Object?> get props => <Object?>[name, email, phone, password, role];
}

/// One-tap sign-in as a seeded persona.
class AuthDemoSignInRequested extends AuthEvent {
  const AuthDemoSignInRequested(this.role);

  final UserRole role;

  @override
  List<Object?> get props => <Object?>[role];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}

/// Pushes an updated [User] into the session after a profile mutation.
class AuthProfileRefreshed extends AuthEvent {
  const AuthProfileRefreshed(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

class AuthMessageCleared extends AuthEvent {
  const AuthMessageCleared();
}
