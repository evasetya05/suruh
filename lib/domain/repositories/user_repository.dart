import '../../core/utils/result.dart';
import '../entities/address.dart';
import '../entities/restaurant.dart';
import '../entities/user.dart';

/// Profile, saved addresses and favourites.
abstract interface class UserRepository {
  Future<Result<User>> getProfile(String userId);

  Future<Result<User>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarEmoji,
  });

  // --- Addresses ------------------------------------------------------------
  Future<Result<List<Address>>> getAddresses(String userId);

  Future<Result<List<Address>>> saveAddress({
    required String userId,
    required Address address,
  });

  Future<Result<List<Address>>> deleteAddress({
    required String userId,
    required String addressId,
  });

  Future<Result<List<Address>>> setDefaultAddress({
    required String userId,
    required String addressId,
  });

  // --- Favourites -----------------------------------------------------------
  Future<Result<Set<String>>> getFavouriteIds(String userId);

  Future<Result<List<Restaurant>>> getFavouriteRestaurants(String userId);

  /// Adds or removes [restaurantId] and returns the new favourite id set.
  Future<Result<Set<String>>> toggleFavourite({
    required String userId,
    required String restaurantId,
  });
}
