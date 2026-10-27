import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../../core/utils/validators.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => <Object?>[email, password];
}

/// Signs a user in, validating input before touching the backend so obviously
/// bad credentials never cost a network round-trip.
class SignIn extends UseCase<User, SignInParams> {
  const SignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call(SignInParams params) async {
    final String? emailError = Validators.email(params.email);
    if (emailError != null) {
      return Result<User>.failure(ValidationFailure(emailError));
    }
    final String? passwordError = Validators.password(params.password);
    if (passwordError != null) {
      return Result<User>.failure(ValidationFailure(passwordError));
    }
    return _repository.signIn(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

class RegisterParams extends Equatable {
  const RegisterParams({
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

class Register extends UseCase<User, RegisterParams> {
  const Register(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call(RegisterParams params) async {
    final String? error = Validators.name(params.name) ??
        Validators.email(params.email) ??
        Validators.phone(params.phone) ??
        Validators.password(params.password);
    if (error != null) {
      return Result<User>.failure(ValidationFailure(error));
    }
    return _repository.register(
      name: params.name.trim(),
      email: params.email.trim(),
      phone: params.phone.trim(),
      password: params.password,
      role: params.role,
    );
  }
}

class SignInAsDemo extends UseCase<User, UserRole> {
  const SignInAsDemo(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call(UserRole params) => _repository.signInAsDemo(params);
}

class SignOut extends UseCase<void, NoParams> {
  const SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.signOut();
}

class RestoreSession extends UseCase<User?, NoParams> {
  const RestoreSession(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User?>> call(NoParams params) => _repository.restoreSession();
}

class SendPasswordReset extends UseCase<void, String> {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) {
    final String? error = Validators.email(params);
    if (error != null) {
      return Future<Result<void>>.value(
        Result<void>.failure(ValidationFailure(error)),
      );
    }
    return _repository.sendPasswordReset(params.trim());
  }
}
