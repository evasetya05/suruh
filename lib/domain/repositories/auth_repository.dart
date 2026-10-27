import '../../core/utils/result.dart';
import '../entities/user.dart';

/// Authentication + session contract.
///
/// Implemented twice: `DemoAuthRepository` (seeded local accounts) and
/// `FirebaseAuthRepository` (Firebase Auth + a Firestore `users` document).
abstract interface class AuthRepository {
  /// Emits the signed-in user, or `null` when signed out.
  Stream<User?> get authStateChanges;

  /// The currently cached user without hitting the backend.
  User? get currentUser;

  Future<Result<User>> signIn({
    required String email,
    required String password,
  });

  Future<Result<User>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  });

  /// Signs in as one of the seeded demo personas without typing credentials.
  Future<Result<User>> signInAsDemo(UserRole role);

  Future<Result<void>> signOut();

  Future<Result<void>> sendPasswordReset(String email);

  /// Restores a persisted session on app start.
  Future<Result<User?>> restoreSession();
}
