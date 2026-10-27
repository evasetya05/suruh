import '../../core/error/exceptions.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../models/address_model.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';

/// Profile, addresses and favourites.
///
/// Mutations are written to the backing store *and* mirrored into
/// [LocalStorage] so the signed-in session stays correct offline.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required DemoDataSource remote,
    required LocalStorage storage,
  })  : _remote = remote,
        _storage = storage;

  final DemoDataSource _remote;
  final LocalStorage _storage;

  @override
  Future<Result<User>> getProfile(String userId) =>
      guard<User>(() => _remote.getUserById(userId));

  @override
  Future<Result<User>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarEmoji,
  }) {
    return guard<User>(() async {
      final UserModel current = await _remote.getUserById(userId);
      final UserModel updated = UserModel.fromEntity(
        current.copyWith(name: name, phone: phone, avatarEmoji: avatarEmoji),
      );
      await _remote.upsertUser(updated);
      await _syncSession(updated);
      return updated;
    });
  }

  @override
  Future<Result<List<Address>>> getAddresses(String userId) {
    return guard<List<Address>>(() async {
      final UserModel user = await _remote.getUserById(userId);
      return user.addresses;
    });
  }

  @override
  Future<Result<List<Address>>> saveAddress({
    required String userId,
    required Address address,
  }) {
    return guard<List<Address>>(() async {
      final UserModel current = await _remote.getUserById(userId);
      final List<Address> addresses = List<Address>.of(current.addresses);

      final int index =
          addresses.indexWhere((Address a) => a.id == address.id);
      if (index == -1) {
        // First address a user saves becomes their default automatically.
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
      return _saveAddresses(current, normalised);
    });
  }

  @override
  Future<Result<List<Address>>> deleteAddress({
    required String userId,
    required String addressId,
  }) {
    return guard<List<Address>>(() async {
      final UserModel current = await _remote.getUserById(userId);
      final List<Address> remaining = current.addresses
          .where((Address a) => a.id != addressId)
          .toList(growable: true);
      if (remaining.length == current.addresses.length) {
        throw const NotFoundException('That address no longer exists.');
      }
      return _saveAddresses(current, _ensureSingleDefault(remaining));
    });
  }

  @override
  Future<Result<List<Address>>> setDefaultAddress({
    required String userId,
    required String addressId,
  }) {
    return guard<List<Address>>(() async {
      final UserModel current = await _remote.getUserById(userId);
      if (!current.addresses.any((Address a) => a.id == addressId)) {
        throw const NotFoundException('That address no longer exists.');
      }
      return _saveAddresses(
        current,
        _ensureSingleDefault(current.addresses, preferId: addressId),
      );
    });
  }

  @override
  Future<Result<Set<String>>> getFavouriteIds(String userId) {
    return guard<Set<String>>(() async {
      final UserModel user = await _remote.getUserById(userId);
      return user.favouriteRestaurantIds;
    });
  }

  @override
  Future<Result<List<Restaurant>>> getFavouriteRestaurants(String userId) {
    return guard<List<Restaurant>>(() async {
      final UserModel user = await _remote.getUserById(userId);
      final List<RestaurantModel> all = await _remote.getRestaurants();
      return all
          .where((RestaurantModel r) =>
              user.favouriteRestaurantIds.contains(r.id))
          .toList(growable: false);
    });
  }

  @override
  Future<Result<Set<String>>> toggleFavourite({
    required String userId,
    required String restaurantId,
  }) {
    return guard<Set<String>>(() async {
      final UserModel current = await _remote.getUserById(userId);
      final Set<String> favourites =
          Set<String>.of(current.favouriteRestaurantIds);

      if (!favourites.remove(restaurantId)) {
        favourites.add(restaurantId);
      }

      final UserModel updated = UserModel.fromEntity(
        current.copyWith(favouriteRestaurantIds: favourites),
      );
      await _remote.upsertUser(updated);
      await _syncSession(updated);
      return favourites;
    });
  }

  // --- Helpers --------------------------------------------------------------

  Future<List<Address>> _saveAddresses(
    UserModel user,
    List<Address> addresses,
  ) async {
    final UserModel updated =
        UserModel.fromEntity(user.copyWith(addresses: addresses));
    await _remote.upsertUser(updated);
    await _syncSession(updated);
    await _storage.writeJsonList(
      LocalStorage.kAddresses,
      addresses
          .map((Address a) => AddressModel.fromEntity(a).toJson())
          .toList(growable: false),
    );
    return addresses;
  }

  /// Guarantees exactly one default address survives any mutation.
  List<Address> _ensureSingleDefault(
    List<Address> addresses, {
    String? preferId,
  }) {
    if (addresses.isEmpty) return const <Address>[];

    final String defaultId = preferId ??
        addresses
            .firstWhere(
              (Address a) => a.isDefault,
              orElse: () => addresses.first,
            )
            .id;

    return addresses
        .map((Address a) => a.copyWith(isDefault: a.id == defaultId))
        .toList(growable: false);
  }

  /// Keeps the persisted session document in step with profile changes.
  Future<void> _syncSession(UserModel user) async {
    final Map<String, dynamic>? session =
        _storage.readJson(LocalStorage.kSession);
    if (session == null || session['id'] != user.id) return;
    await _storage.writeJson(LocalStorage.kSession, user.toJson());
  }
}
