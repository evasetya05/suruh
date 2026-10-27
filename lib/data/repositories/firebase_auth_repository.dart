import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/error/exceptions.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/firestore_data_source.dart';
import '../models/user_model.dart';

/// Firebase Authentication backed by a Firestore `users/{uid}` profile
/// document.
///
/// Firebase Auth owns credentials; the profile document owns everything the app
/// actually renders (role, addresses, favourites, loyalty tier). Both are kept
/// in step here so the rest of the app only ever sees a single [User].
///
/// Selected by setting `AppConfig.backend = Backend.firebase`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirestoreDataSource remote,
    required LocalStorage storage,
    fb.FirebaseAuth? auth,
  })  : _remote = remote,
        _storage = storage,
        _auth = auth ?? fb.FirebaseAuth.instance;

  final FirestoreDataSource _remote;
  final LocalStorage _storage;
  final fb.FirebaseAuth _auth;

  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((fb.User? account) async {
        if (account == null) {
          _currentUser = null;
          return null;
        }
        final User user = await _loadProfile(account);
        _currentUser = user;
        return user;
      });

  @override
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) {
    return guard<User>(() async {
      try {
        final fb.UserCredential credential =
            await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final User user = await _loadProfile(credential.user!);
        await _persist(user);
        return user;
      } on fb.FirebaseAuthException catch (error) {
        throw _mapAuthError(error);
      }
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
      try {
        final fb.UserCredential credential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user!.updateDisplayName(name);

        final UserModel profile = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
          addresses: const <Address>[],
          createdAt: DateTime.now(),
        );
        await _remote.upsertUser(profile);
        await _persist(profile);
        return profile;
      } on fb.FirebaseAuthException catch (error) {
        throw _mapAuthError(error);
      }
    });
  }

  /// Demo personas do not exist in a real Firebase project. Rather than
  /// silently signing in as the wrong account, this fails loudly with guidance.
  @override
  Future<Result<User>> signInAsDemo(UserRole role) {
    return guard<User>(() async {
      throw const AuthException(
        'Demo personas are only available on the local demo backend. '
        'Sign in with a real account, or set AppConfig.backend to Backend.demo.',
      );
    });
  }

  @override
  Future<Result<void>> signOut() {
    return guard<void>(() async {
      await _auth.signOut();
      _currentUser = null;
      await _storage.clearSession();
    });
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) {
    return guard<void>(() async {
      try {
        await _auth.sendPasswordResetEmail(email: email);
      } on fb.FirebaseAuthException catch (error) {
        throw _mapAuthError(error);
      }
    });
  }

  @override
  Future<Result<User?>> restoreSession() {
    return guard<User?>(() async {
      final fb.User? account = _auth.currentUser;
      if (account == null) return null;
      final User user = await _loadProfile(account);
      await _persist(user);
      return user;
    });
  }

  /// Reads the Firestore profile, creating a minimal one the first time an
  /// account signs in (e.g. after a provider-based sign-up).
  Future<User> _loadProfile(fb.User account) async {
    final UserModel? profile = await _remote.getUserById(account.uid);
    if (profile != null) return profile;

    final UserModel created = UserModel(
      id: account.uid,
      name: account.displayName ?? 'MSDevBuild Eats user',
      email: account.email ?? '',
      phone: account.phoneNumber ?? '',
      role: UserRole.customer,
      photoUrl: account.photoURL,
      createdAt: DateTime.now(),
    );
    await _remote.upsertUser(created);
    return created;
  }

  Future<void> _persist(User user) async {
    _currentUser = user;
    await _storage.writeJson(
      LocalStorage.kSession,
      UserModel.fromEntity(user).toJson(),
    );
  }

  AppException _mapAuthError(fb.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => const AuthException('That email address is not valid.'),
      'user-disabled' => const AuthException('This account has been disabled.'),
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        const AuthException('Incorrect email or password.'),
      'email-already-in-use' => const AuthException(
          'An account with that email already exists. Try signing in.',
        ),
      'weak-password' =>
        const AuthException('Choose a stronger password (6+ characters).'),
      'too-many-requests' => const AuthException(
          'Too many attempts. Please wait a moment and try again.',
        ),
      'network-request-failed' =>
        const NetworkException('No internet connection.'),
      _ => AuthException(error.message ?? 'Authentication failed.', error),
    };
  }
}
