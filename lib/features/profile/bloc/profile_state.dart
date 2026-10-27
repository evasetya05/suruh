part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.addresses = const <Address>[],
    this.favourites = const <Restaurant>[],
    this.isSaving = false,
    this.isLoadingFavourites = false,
    this.successMessage,
    this.errorMessage,
  });

  final ProfileStatus status;
  final User? user;
  final List<Address> addresses;
  final List<Restaurant> favourites;
  final bool isSaving;
  final bool isLoadingFavourites;
  final String? successMessage;
  final String? errorMessage;

  bool get isLoading =>
      status == ProfileStatus.loading || status == ProfileStatus.initial;

  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    List<Address>? addresses,
    List<Restaurant>? favourites,
    bool? isSaving,
    bool? isLoadingFavourites,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      addresses: addresses ?? this.addresses,
      favourites: favourites ?? this.favourites,
      isSaving: isSaving ?? this.isSaving,
      isLoadingFavourites: isLoadingFavourites ?? this.isLoadingFavourites,
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      errorMessage: clearMessages || clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        user,
        addresses,
        favourites,
        isSaving,
        isLoadingFavourites,
        successMessage,
        errorMessage,
      ];
}
