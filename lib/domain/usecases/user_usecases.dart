import 'package:equatable/equatable.dart';

import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/address.dart';
import '../entities/restaurant.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetProfile extends UseCase<User, String> {
  const GetProfile(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<User>> call(String userId) => _repository.getProfile(userId);
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    required this.userId,
    this.name,
    this.phone,
    this.avatarEmoji,
  });

  final String userId;
  final String? name;
  final String? phone;
  final String? avatarEmoji;

  @override
  List<Object?> get props => <Object?>[userId, name, phone, avatarEmoji];
}

class UpdateProfile extends UseCase<User, UpdateProfileParams> {
  const UpdateProfile(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<User>> call(UpdateProfileParams params) =>
      _repository.updateProfile(
        userId: params.userId,
        name: params.name,
        phone: params.phone,
        avatarEmoji: params.avatarEmoji,
      );
}

class GetAddresses extends UseCase<List<Address>, String> {
  const GetAddresses(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<List<Address>>> call(String userId) =>
      _repository.getAddresses(userId);
}

class SaveAddressParams extends Equatable {
  const SaveAddressParams({required this.userId, required this.address});

  final String userId;
  final Address address;

  @override
  List<Object?> get props => <Object?>[userId, address];
}

class SaveAddress extends UseCase<List<Address>, SaveAddressParams> {
  const SaveAddress(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<List<Address>>> call(SaveAddressParams params) =>
      _repository.saveAddress(userId: params.userId, address: params.address);
}

class AddressRefParams extends Equatable {
  const AddressRefParams({required this.userId, required this.addressId});

  final String userId;
  final String addressId;

  @override
  List<Object?> get props => <Object?>[userId, addressId];
}

class DeleteAddress extends UseCase<List<Address>, AddressRefParams> {
  const DeleteAddress(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<List<Address>>> call(AddressRefParams params) =>
      _repository.deleteAddress(
        userId: params.userId,
        addressId: params.addressId,
      );
}

class SetDefaultAddress extends UseCase<List<Address>, AddressRefParams> {
  const SetDefaultAddress(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<List<Address>>> call(AddressRefParams params) =>
      _repository.setDefaultAddress(
        userId: params.userId,
        addressId: params.addressId,
      );
}

class ToggleFavouriteParams extends Equatable {
  const ToggleFavouriteParams({
    required this.userId,
    required this.restaurantId,
  });

  final String userId;
  final String restaurantId;

  @override
  List<Object?> get props => <Object?>[userId, restaurantId];
}

class ToggleFavourite extends UseCase<Set<String>, ToggleFavouriteParams> {
  const ToggleFavourite(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<Set<String>>> call(ToggleFavouriteParams params) =>
      _repository.toggleFavourite(
        userId: params.userId,
        restaurantId: params.restaurantId,
      );
}

class GetFavouriteRestaurants extends UseCase<List<Restaurant>, String> {
  const GetFavouriteRestaurants(this._repository);

  final UserRepository _repository;

  @override
  Future<Result<List<Restaurant>>> call(String userId) =>
      _repository.getFavouriteRestaurants(userId);
}
