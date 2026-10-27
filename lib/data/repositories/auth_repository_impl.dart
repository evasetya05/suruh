import 'dart:async';

import '../../core/error/exceptions.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../datasources/local/seed/seed_users.dart';
import '../models/user_model.dart';

/// Demo-backed authentication.
///
/// Accepts any seeded account with the shared demo password, and lets new
/// accounts be registered in memory. The session is persisted to
/// [LocalStorage] so a page refresh on web keeps you signed in.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required DemoDataSource remote,
    required LocalStorage storage,
  })  : _remote = remote,
        _storage = storage;

  final DemoDataSource _remote;
  final LocalStorage _storage;

  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  User? _currentUser;

  @override
  Stream<User?> get authStateChanges async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) {
    return guard<User>(() async {
      final UserModel? user = await _remote.findUserByEmail(email);
      if (user == null) {
        throw const AuthException('No account found with that email address.');
      }
      // Every seeded persona shares one password; see docs/SETUP.md.
      if (password != kDemoPassword) {
        throw const AuthException(
          'Incorrect password. The demo password is "demo1234".',
        );
      }
      await _persist(user);
      return user;
    });
  }

  @override
  Future<Result<User>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) {
    return guard<User>(() async {
      final UserModel? existing = await _remote.findUserByEmail(email);
      if (existing != null) {
        throw const AuthException(
          'An account with that email already exists. Try signing in.',
        );
      }

      final UserModel created = UserModel(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        role: role,
        avatarEmoji: '🙂',
        addresses: const <Address>[],
        loyaltyPoints: 0,
        memberTier: 'Member',
        createdAt: DateTime.now(),
      );

      await _remote.upsertUser(created);
      await _persist(created);
      return created;
    });
  }

  @override
  Future<Result<User>> signInAsDemo(UserRole role) {
    return guard<User>(() async {
      final UserModel persona = kSeedUsers.firstWhere(
        (UserModel u) => u.role == role,
        orElse: () => kSeedUsers.first,
      );
      final UserModel fresh = await _remote.getUserById(persona.id);
      await _persist(fresh);
      return fresh;
    });
  }

  @override
  Future<Result<void>> signOut() {
    return guard<void>(() async {
      _currentUser = null;
      await _storage.clearSession();
      _authController.add(null);
    });
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) {
    return guard<void>(() async {
      final UserModel? user = await _remote.findUserByEmail(email);
      if (user == null) {
        throw const AuthException('No account found with that email address.');
      }
      // Nothing to send in the demo backend - the Firebase implementation calls
      // FirebaseAuth.sendPasswordResetEmail here.
    });
  }

  @override
  Future<Result<User?>> restoreSession() {
    return guard<User?>(() async {
      final Map<String, dynamic>? json =
          _storage.readJson(LocalStorage.kSession);
      if (json == null) return null;

      final UserModel cached = UserModel.fromJson(json);
      // Re-read from the backend so favourites and addresses added in a
      // previous session are reflected.
      try {
        final UserModel fresh = await _remote.getUserById(cached.id);
        _currentUser = fresh;
        _authController.add(fresh);
        return fresh;
      } on NotFoundException {
        _currentUser = cached;
        _authController.add(cached);
        return cached;
      }
    });
  }

  Future<void> _persist(UserModel user) async {
    _currentUser = user;
    await _storage.writeJson(LocalStorage.kSession, user.toJson());
    _authController.add(user);
  }

  Future<void> dispose() => _authController.close();
}
