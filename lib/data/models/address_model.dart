import '../../domain/entities/address.dart';

/// Serialisable [Address].
///
/// Models extend their entity rather than duplicating fields, so the domain
/// layer stays free of JSON concerns while data can flow straight through.
class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.label,
    required super.line1,
    required super.city,
    required super.postcode,
    required super.state,
    super.line2,
    super.latitude,
    super.longitude,
    super.notes,
    super.isDefault,
  });

  factory AddressModel.fromEntity(Address a) => AddressModel(
        id: a.id,
        label: a.label,
        line1: a.line1,
        line2: a.line2,
        city: a.city,
        postcode: a.postcode,
        state: a.state,
        latitude: a.latitude,
        longitude: a.longitude,
        notes: a.notes,
        isDefault: a.isDefault,
      );

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] as String,
        label: AddressLabel.fromName(json['label'] as String?),
        line1: json['line1'] as String,
        line2: json['line2'] as String?,
        city: json['city'] as String,
        postcode: json['postcode'] as String,
        state: json['state'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label.name,
        'line1': line1,
        'line2': line2,
        'city': city,
        'postcode': postcode,
        'state': state,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'isDefault': isDefault,
      };
}
