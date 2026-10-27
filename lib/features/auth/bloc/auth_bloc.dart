import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the session for the whole app.
///
/// Provided above the router in `app.dart`, so `GoRouter`'s redirect can read
/// it to gate authenticated routes and the shell can react to sign-out
/// instantly.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignIn signIn,
    required Register register,
    required SignInAsDemo signInAsDemo,
    required SignOut signOut,
    required RestoreSession restoreSession,
    required SendPasswordReset sendPasswordReset,
  })  : _signIn = signIn,
        _register = register,
        _signInAsDemo = signInAsDemo,
        _signOut = signOut,
        _restoreSession = restoreSession,
        _sendPasswordReset = sendPasswordReset,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthDemoSignInRequested>(_onDemoSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthProfileRefreshed>(_onProfileRefreshed);
    on<AuthMessageCleared>(_onMessageCleared);
  }

  final SignIn _signIn;
  final Register _register;
  final SignInAsDemo _signInAsDemo;
  final SignOut _signOut;
  final RestoreSession _restoreSession;
  final SendPasswordReset _sendPasswordReset;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final Result<User?> result = await _restoreSession(const NoParams());
    result.fold(
      // A failed restore is not an error the user needs to see - it just means
      // "not signed in".
      (Failure _) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (User? user) => emit(
        user == null
            ? state.copyWith(status: AuthStatus.unauthenticated)
            : state.copyWith(status: AuthStatus.authenticated, user: user),
      ),
    );
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    final Result<User> result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    _emitAuthResult(result, emit);
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    final Result<User> result = await _register(
      RegisterParams(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        role: event.role,
      ),
    );
    _emitAuthResult(result, emit);
  }

  Future<void> _onDemoSignIn(
    AuthDemoSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    final Result<User> result = await _signInAsDemo(event.role);
    _emitAuthResult(result, emit);
  }

  void _emitAuthResult(Result<User> result, Emitter<AuthState> emit) {
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          isSubmitting: false,
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (User user) => emit(
        state.copyWith(
          isSubmitting: false,
          status: AuthStatus.authenticated,
          user: user,
          clearMessages: true,
        ),
      ),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOut(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    final Result<void> result = await _sendPasswordReset(event.email);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(isSubmitting: false, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Password reset instructions sent to ${event.email}.',
        ),
      ),
    );
  }

  /// Applied after a profile edit, favourite toggle or address change so the
  /// session everyone reads from stays current.
  void _onProfileRefreshed(
    AuthProfileRefreshed event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(user: event.user, status: AuthStatus.authenticated));
  }

  void _onMessageCleared(AuthMessageCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearMessages: true));
  }
}
