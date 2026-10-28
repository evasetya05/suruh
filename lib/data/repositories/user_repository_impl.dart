import '../../core/error/exceptions.dart';
import '../../core/network/suruh_api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/address_model.dart';
import '../models/user_model.dart';

/// Profile, addresses and favourites connected to SURUH Backend API.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required SuruhApiClient api,
    required LocalStorage storage,
  })  : _api = api,
        _storage = storage;

  final SuruhApiClient _api;
  final LocalStorage _storage;

  @override
  Future<Result<User>> getProfile(String userId) {
    return guard<User>(() async {
      try {
        final Map<String, dynamic> data = await _api.getProfile();
        final UserModel user = _mapBackendUser(data, userId);
        await _syncSession(user);
        return user;
      } catch (_) {
        final UserModel? local = _getLocalUser(userId);
        if (local != null) return local;
        throw const NotFoundException('Profil pengguna tidak ditemukan.');
      }
    });
  }

  @override
  Future<Result<User>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarEmoji,
  }) {
    return guard<User>(() async {
      final UserModel current = _getLocalUser(userId) ??
          UserModel(
            id: userId,
            name: name ?? 'Pengguna SURUH',
            email: 'user@suruh.id',
            phone: phone ?? '',
            role: UserRole.customer,
            avatarEmoji: avatarEmoji ?? '🙂',
            createdAt: DateTime.now(),
          );

      try {
        await _api.updateProfile(fullName: name);
      } catch (_) {
        // Continue with local update if backend patch is unavailable
      }

      final UserModel updated = UserModel.fromEntity(
        current.copyWith(name: name, phone: phone, avatarEmoji: avatarEmoji),
      );
      await _syncSession(updated);
      return updated;
    });
  }

  @override
  Future<Result<List<Address>>> getAddresses(String userId) {
    return guard<List<Address>>(() async {
      final List<Map<String, dynamic>> raw =
          _storage.readJsonList(LocalStorage.kAddresses);
      return raw.map((Map<String, dynamic> a) => AddressModel.fromJson(a)).toList();
    });
  }

  @override
  Future<Result<List<Address>>> saveAddress({
    required String userId,
    required Address address,
  }) {
    return guard<List<Address>>(() async {
      final List<Address> addresses =
          (await getAddresses(userId)).fold((_) => <Address>[], (List<Address> a) => a);

      final int index = addresses.indexWhere((Address a) => a.id == address.id);
      if (index == -1) {
        addresses.add(
          addresses.isEmpty ? address.copyWith(isDefault: true) : address,
        );
      } else {
        addresses[index] = address;
      }

      final List<Address> normalised = _ensureSingleDefault(
        addresses,
        preferId: address.isDefault ? address.id : null,
      );
      await _persistAddresses(normalised);
      return normalised;
    });
  }

  @override
  Future<Result<List<Address>>> deleteAddress({
    required String userId,
    required String addressId,
  }) {
    return guard<List<Address>>(() async {
      final List<Address> addresses =
          (await getAddresses(userId)).fold((_) => <Address>[], (List<Address> a) => a);
      final List<Address> remaining =
          addresses.where((Address a) => a.id != addressId).toList(growable: true);
      if (remaining.length == addresses.length) {
        throw const NotFoundException('Alamat tidak ditemukan.');
      }
      final List<Address> normalised = _ensureSingleDefault(remaining);
      await _persistAddresses(normalised);
      return normalised;
    });
  }

  @override
  Future<Result<List<Address>>> setDefaultAddress({
    required String userId,
    required String addressId,
  }) {
    return guard<List<Address>>(() async {
      final List<Address> addresses =
          (await getAddresses(userId)).fold((_) => <Address>[], (List<Address> a) => a);
      if (!addresses.any((Address a) => a.id == addressId)) {
        throw const NotFoundException('Alamat tidak ditemukan.');
      }
      final List<Address> normalised =
          _ensureSingleDefault(addresses, preferId: addressId);
      await _persistAddresses(normalised);
      return normalised;
    });
  }

  @override
  Future<Result<Set<String>>> getFavouriteIds(String userId) {
    return guard<Set<String>>(() async {
      final List<String> favs = _storage.getStringList('suruh_favs_$userId');
      return favs.toSet();
    });
  }

  @override
  Future<Result<List<Restaurant>>> getFavouriteRestaurants(String userId) {
    return guard<List<Restaurant>>(() async => const <Restaurant>[]);
  }

  @override
  Future<Result<Set<String>>> toggleFavourite({
    required String userId,
    required String restaurantId,
  }) {
    return guard<Set<String>>(() async {
      final Set<String> favs =
          (await getFavouriteIds(userId)).fold((_) => <String>{}, (Set<String> s) => s);
      if (!favs.remove(restaurantId)) {
        favs.add(restaurantId);
      }
      await _storage.setStringList('suruh_favs_$userId', favs.toList());
      return favs;
    });
  }

  // --- Internal Helpers ------------------------------------------------------

  UserModel? _getLocalUser(String userId) {
    final Map<String, dynamic>? session =
        _storage.readJson(LocalStorage.kSession);
    if (session != null) {
      return UserModel.fromJson(session);
    }
    final Map<String, dynamic>? cached =
        _storage.readJson(SuruhApiClient.kCachedProfile);
    if (cached != null) {
      return _mapBackendUser(cached, userId);
    }
    return null;
  }

  UserModel _mapBackendUser(Map<String, dynamic> json, String fallbackId) {
    final List<dynamic> roles = json['roles'] as List<dynamic>? ?? <dynamic>[];
    UserRole role = UserRole.customer;
    if (roles.contains('driver')) {
      role = UserRole.deliveryPartner;
    } else if (roles.contains('merchant')) {
      role = UserRole.restaurantPartner;
    }

    return UserModel(
      id: json['id']?.toString() ?? fallbackId,
      name: json['full_name'] as String? ?? 'Pengguna SURUH',
      email: json['email'] as String? ?? '${json["phone_number"]}@suruh.id',
      phone: json['phone_number'] as String? ?? '',
      role: role,
      avatarEmoji: role == UserRole.deliveryPartner ? '🛵' : '🙂',
      photoUrl: json['avatar_url'] as String?,
      addresses: const <Address>[],
      loyaltyPoints: 100,
      memberTier: 'Mitra SURUH',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Future<void> _persistAddresses(List<Address> addresses) async {
    await _storage.writeJsonList(
      LocalStorage.kAddresses,
      addresses
          .map((Address a) => AddressModel.fromEntity(a).toJson())
          .toList(growable: false),
    );
  }

  List<Address> _ensureSingleDefault(
    List<Address> addresses, {
    String? preferId,
  }) {
    if (addresses.isEmpty) return const <Address>[];

    String defaultId = preferId ?? '';
    if (defaultId.isEmpty) {
      for (final Address a in addresses) {
        if (a.isDefault) {
          defaultId = a.id;
          break;
        }
      }
      if (defaultId.isEmpty) {
        defaultId = addresses.first.id;
      }
    }

    return addresses
        .map<Address>((Address a) => a.copyWith(isDefault: a.id == defaultId))
        .toList(growable: false);
  }

  Future<void> _syncSession(UserModel user) async {
    await _storage.writeJson(LocalStorage.kSession, user.toJson());
  }
}
