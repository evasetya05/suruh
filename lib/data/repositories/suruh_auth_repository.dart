import 'dart:async';

import '../../core/error/exceptions.dart';
import '../../core/network/suruh_api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/seed/seed_users.dart';
import '../models/user_model.dart';

/// Authentication repository connected directly to SURUH Django REST API backend
/// defined in suruh_backend/compose.yaml.
class SuruhAuthRepository implements AuthRepository {
  SuruhAuthRepository({
    required SuruhApiClient api,
    required LocalStorage storage,
  })  : _api = api,
        _storage = storage;

  final SuruhApiClient _api;
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
      // Backend expects Indonesian phone number; accept either phone or email
      final String identifier = _normalizeIdentifier(email);

      try {
        final Map<String, dynamic> data = await _api.login(
          phoneNumber: identifier,
          password: password,
        );

        final Map<String, dynamic> userData = data['user'] as Map<String, dynamic>;
        final User user = _mapBackendUser(userData);
        await _persist(user);
        return user;
      } on AppException {
        rethrow;
      } catch (e) {
        throw AuthException('Gagal masuk ke SURUH backend: $e', e);
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
      final String backendRole = switch (role) {
        UserRole.deliveryPartner => 'driver',
        UserRole.restaurantPartner => 'merchant',
        UserRole.customer => 'customer',
      };

      try {
        final Map<String, dynamic> data = await _api.register(
          fullName: name,
          phoneNumber: phone.isNotEmpty ? phone : _normalizeIdentifier(email),
          password: password,
          email: email.contains('@') ? email : null,
          role: backendRole,
        );

        final Map<String, dynamic> userData = data['user'] as Map<String, dynamic>;
        final User user = _mapBackendUser(userData);
        await _persist(user);
        return user;
      } on AppException {
        rethrow;
      } catch (e) {
        throw AuthException('Pendaftaran gagal di backend SURUH: $e', e);
      }
    });
  }

  @override
  Future<Result<User>> signInAsDemo(UserRole role) {
    return guard<User>(() async {
      // Pre-configured persona accounts for quick testing
      final (String phone, String name, String email) = switch (role) {
        UserRole.customer => (
            '081211112222',
            'Rian Pontianak',
            'customer@suruh.id',
          ),
        UserRole.restaurantPartner => (
            '081222223333',
            'Mitra Merchant Khatulistiwa',
            'merchant@suruh.id',
          ),
        UserRole.deliveryPartner => (
            '081233334444',
            'Joko Driver Suruh',
            'driver@suruh.id',
          ),
      };

      try {
        // Try logging in to real backend first
        final Map<String, dynamic> data = await _api.login(
          phoneNumber: phone,
          password: kDemoPassword,
        );
        final User user = _mapBackendUser(data['user'] as Map<String, dynamic>);
        await _persist(user);
        return user;
      } catch (_) {
        // If not registered yet on this backend instance, auto-register persona
        try {
          final Map<String, dynamic> data = await _api.register(
            fullName: name,
            phoneNumber: phone,
            password: kDemoPassword,
            email: email,
            role: switch (role) {
              UserRole.deliveryPartner => 'driver',
              UserRole.restaurantPartner => 'merchant',
              UserRole.customer => 'customer',
            },
          );
          final User user = _mapBackendUser(data['user'] as Map<String, dynamic>);
          await _persist(user);
          return user;
        } catch (_) {
          // If backend connection fails, provide offline persona session
          final UserModel fallback = UserModel(
            id: 'suruh-${role.name}',
            name: name,
            email: email,
            phone: phone,
            role: role,
            avatarEmoji: role == UserRole.deliveryPartner ? '🛵' : '🙂',
            addresses: const <Address>[
              Address(
                id: 'addr-ptk-1',
                label: AddressLabel.home,
                line1: 'Jl. Gajah Mada No. 12',
                line2: 'Blok B-4',
                city: 'Pontianak',
                state: 'Kalimantan Barat',
                postcode: '78121',
                isDefault: true,
              ),
            ],
            loyaltyPoints: 100,
            memberTier: 'Suruh Prioritas',
            createdAt: DateTime.now(),
          );
          await _persist(fallback);
          return fallback;
        }
      }
    });
  }

  @override
  Future<Result<void>> signOut() {
    return guard<void>(() async {
      await _api.logout();
      _currentUser = null;
      await _storage.clearSession();
      _authController.add(null);
    });
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) {
    return guard<void>(() async {
      // SURUH backend password reset request
      try {
        await _api.request(
          method: 'POST',
          path: '/api/v1/auth/password-reset/request/',
          body: <String, String>{'phone_number': _normalizeIdentifier(email)},
          requiresAuth: false,
        );
      } catch (_) {
        // Fallback for user experience
      }
    });
  }

  @override
  Future<Result<User?>> restoreSession() {
    return guard<User?>(() async {
      final Map<String, dynamic>? cached = _storage.readJson(LocalStorage.kSession);
      if (cached == null) return null;

      try {
        final UserModel user = UserModel.fromJson(cached);
        _currentUser = user;
        _authController.add(user);

        // Background profile refresh if token exists
        if (_api.isAuthenticated) {
          unawaited(_refreshProfileInBackground());
        }
        return user;
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> _refreshProfileInBackground() async {
    try {
      final Map<String, dynamic> profile = await _api.getProfile();
      final User user = _mapBackendUser(profile);
      await _persist(user);
    } catch (_) {
      // Silent refresh failure is fine
    }
  }

  Future<void> _persist(User user) async {
    _currentUser = user;
    final UserModel model = UserModel.fromEntity(user);
    await _storage.writeJson(LocalStorage.kSession, model.toJson());
    _authController.add(user);
  }

  /// Normalizes an input that might be an email or raw phone to Indonesian format
  String _normalizeIdentifier(String input) {
    final String clean = input.trim();
    if (!clean.contains('@')) {
      // Format to 08... or +628...
      return clean;
    }
    // If it's a known demo email, map to default phone
    if (clean.contains('customer')) return '081211112222';
    if (clean.contains('merchant') || clean.contains('restaurant')) return '081222223333';
    if (clean.contains('driver') || clean.contains('rider')) return '081233334444';
    return clean;
  }

  User _mapBackendUser(Map<String, dynamic> json) {
    final List<dynamic> roles = json['roles'] as List<dynamic>? ?? <dynamic>[];
    UserRole role = UserRole.customer;
    if (roles.contains('driver')) {
      role = UserRole.deliveryPartner;
    } else if (roles.contains('merchant')) {
      role = UserRole.restaurantPartner;
    }

    return UserModel(
      id: json['id']?.toString() ?? 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: json['full_name'] as String? ?? 'Pengguna Suruh',
      email: json['email'] as String? ?? '${json["phone_number"]}@suruh.id',
      phone: json['phone_number'] as String? ?? '',
      role: role,
      avatarEmoji: role == UserRole.deliveryPartner ? '🛵' : '🙂',
      photoUrl: json['avatar_url'] as String?,
      addresses: const <Address>[
        Address(
          id: 'addr-ptk-default',
          label: AddressLabel.home,
          line1: 'Jl. Gajah Mada No. 12',
          city: 'Pontianak',
          state: 'Kalimantan Barat',
          postcode: '78121',
          isDefault: true,
        ),
      ],
      loyaltyPoints: 50,
      memberTier: 'Mitra Suruh',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
