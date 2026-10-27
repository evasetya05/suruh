import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/user_usecases.dart';

part 'profile_state.dart';

/// Profile, saved addresses and favourite restaurants.
///
/// Every mutation returns the updated [User], which the screen forwards to
/// [AuthBloc] so the session everyone else reads stays in step.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetProfile getProfile,
    required UpdateProfile updateProfile,
    required GetAddresses getAddresses,
    required SaveAddress saveAddress,
    required DeleteAddress deleteAddress,
    required SetDefaultAddress setDefaultAddress,
    required GetFavouriteRestaurants getFavourites,
    required ToggleFavourite toggleFavourite,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        _getAddresses = getAddresses,
        _saveAddress = saveAddress,
        _deleteAddress = deleteAddress,
        _setDefaultAddress = setDefaultAddress,
        _getFavourites = getFavourites,
        _toggleFavourite = toggleFavourite,
        super(const ProfileState());

  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;
  final GetAddresses _getAddresses;
  final SaveAddress _saveAddress;
  final DeleteAddress _deleteAddress;
  final SetDefaultAddress _setDefaultAddress;
  final GetFavouriteRestaurants _getFavourites;
  final ToggleFavourite _toggleFavourite;

  Future<void> load(String userId) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    final Result<User> profile = await _getProfile(userId);
    if (profile.failureOrNull case final Failure failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ProfileStatus.success,
        user: profile.valueOrNull,
        addresses: profile.valueOrNull!.addresses,
        clearError: true,
      ),
    );
  }

  Future<void> loadAddresses(String userId) async {
    final Result<List<Address>> result = await _getAddresses(userId);
    result.fold(
      (Failure failure) => emit(state.copyWith(errorMessage: failure.message)),
      (List<Address> addresses) => emit(state.copyWith(addresses: addresses)),
    );
  }

  Future<void> loadFavourites(String userId) async {
    emit(state.copyWith(isLoadingFavourites: true));
    final Result<List<Restaurant>> result = await _getFavourites(userId);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          isLoadingFavourites: false,
          errorMessage: failure.message,
        ),
      ),
      (List<Restaurant> favourites) => emit(
        state.copyWith(
          isLoadingFavourites: false,
          favourites: favourites,
          clearError: true,
        ),
      ),
    );
  }

  Future<User?> saveProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarEmoji,
  }) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    final Result<User> result = await _updateProfile(
      UpdateProfileParams(
        userId: userId,
        name: name,
        phone: phone,
        avatarEmoji: avatarEmoji,
      ),
    );

    return result.fold(
      (Failure failure) {
        emit(state.copyWith(isSaving: false, errorMessage: failure.message));
        return null;
      },
      (User user) {
        emit(
          state.copyWith(
            isSaving: false,
            user: user,
            successMessage: 'Profile updated',
          ),
        );
        return user;
      },
    );
  }

  Future<void> saveAddress(String userId, Address address) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    final Result<List<Address>> result =
        await _saveAddress(SaveAddressParams(userId: userId, address: address));
    _emitAddresses(result, 'Address saved');
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    final Result<List<Address>> result = await _deleteAddress(
      AddressRefParams(userId: userId, addressId: addressId),
    );
    _emitAddresses(result, 'Address removed');
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    final Result<List<Address>> result = await _setDefaultAddress(
      AddressRefParams(userId: userId, addressId: addressId),
    );
    _emitAddresses(result, 'Default address updated');
  }

  Future<void> toggleFavourite(String userId, String restaurantId) async {
    // Drop it from the visible list straight away; the reload below reconciles.
    emit(
      state.copyWith(
        favourites: state.favourites
            .where((Restaurant r) => r.id != restaurantId)
            .toList(growable: false),
      ),
    );

    final Result<Set<String>> result = await _toggleFavourite(
      ToggleFavouriteParams(userId: userId, restaurantId: restaurantId),
    );

    if (result.failureOrNull case final Failure failure) {
      emit(state.copyWith(errorMessage: failure.message));
    }
    await loadFavourites(userId);
  }

  void _emitAddresses(Result<List<Address>> result, String successMessage) {
    result.fold(
      (Failure failure) =>
          emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
      (List<Address> addresses) => emit(
        state.copyWith(
          isSaving: false,
          addresses: addresses,
          successMessage: successMessage,
        ),
      ),
    );
  }

  void clearMessages() => emit(state.copyWith(clearMessages: true));
}
