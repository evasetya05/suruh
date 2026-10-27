import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';
import 'address_model.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.avatarEmoji,
    super.photoUrl,
    super.addresses,
    super.favouriteRestaurantIds,
    super.loyaltyPoints,
    super.memberTier,
    super.createdAt,
    super.managedRestaurantId,
  });

  factory UserModel.fromEntity(User u) => UserModel(
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: u.role,
        avatarEmoji: u.avatarEmoji,
        photoUrl: u.photoUrl,
        addresses: u.addresses,
        favouriteRestaurantIds: u.favouriteRestaurantIds,
        loyaltyPoints: u.loyaltyPoints,
        memberTier: u.memberTier,
        createdAt: u.createdAt,
        managedRestaurantId: u.managedRestaurantId,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        role: UserRole.fromName(json['role'] as String?),
        avatarEmoji: json['avatarEmoji'] as String? ?? '🙂',
        photoUrl: json['photoUrl'] as String?,
        addresses: (json['addresses'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                AddressModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        favouriteRestaurantIds:
            (json['favouriteRestaurantIds'] as List<dynamic>? ?? <dynamic>[])
                .cast<String>()
                .toSet(),
        loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
        memberTier: json['memberTier'] as String? ?? 'Member',
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        managedRestaurantId: json['managedRestaurantId'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'avatarEmoji': avatarEmoji,
        'photoUrl': photoUrl,
        'addresses': addresses
            .map((Address a) => AddressModel.fromEntity(a).toJson())
            .toList(growable: false),
        'favouriteRestaurantIds': favouriteRestaurantIds.toList(),
        'loyaltyPoints': loyaltyPoints,
        'memberTier': memberTier,
        'createdAt': createdAt?.toIso8601String(),
        'managedRestaurantId': managedRestaurantId,
      };
}
