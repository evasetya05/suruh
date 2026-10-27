import 'package:equatable/equatable.dart';

import 'address.dart';

/// Which app experience a signed-in account sees.
///
/// The demo ships all three in one binary so a reviewer can switch personas
/// without re-installing.
enum UserRole {
  customer('Customer'),
  restaurantPartner('Restaurant partner'),
  deliveryPartner('Delivery partner');

  const UserRole(this.label);
  final String label;

  static UserRole fromName(String? value) => UserRole.values.firstWhere(
        (UserRole role) => role.name == value,
        orElse: () => UserRole.customer,
      );
}

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarEmoji = '🙂',
    this.photoUrl,
    this.addresses = const <Address>[],
    this.favouriteRestaurantIds = const <String>{},
    this.loyaltyPoints = 0,
    this.memberTier = 'Member',
    this.createdAt,
    /// Set for [UserRole.restaurantPartner] - the restaurant they operate.
    this.managedRestaurantId,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String avatarEmoji;
  final String? photoUrl;
  final List<Address> addresses;
  final Set<String> favouriteRestaurantIds;
  final int loyaltyPoints;
  final String memberTier;
  final DateTime? createdAt;
  final String? managedRestaurantId;

  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (Address a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get firstName => name.split(' ').first;

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarEmoji,
    String? photoUrl,
    List<Address>? addresses,
    Set<String>? favouriteRestaurantIds,
    int? loyaltyPoints,
    String? memberTier,
    UserRole? role,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      photoUrl: photoUrl ?? this.photoUrl,
      addresses: addresses ?? this.addresses,
      favouriteRestaurantIds:
          favouriteRestaurantIds ?? this.favouriteRestaurantIds,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      memberTier: memberTier ?? this.memberTier,
      createdAt: createdAt,
      managedRestaurantId: managedRestaurantId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        email,
        phone,
        role,
        avatarEmoji,
        addresses,
        favouriteRestaurantIds,
        loyaltyPoints,
        memberTier,
        managedRestaurantId,
      ];
}
