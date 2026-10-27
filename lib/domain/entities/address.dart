import 'package:equatable/equatable.dart';

enum AddressLabel {
  home('Home'),
  work('Work'),
  other('Other');

  const AddressLabel(this.display);
  final String display;

  static AddressLabel fromName(String? value) => AddressLabel.values.firstWhere(
        (AddressLabel l) => l.name == value,
        orElse: () => AddressLabel.other,
      );
}

class Address extends Equatable {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.postcode,
    required this.state,
    this.line2,
    this.latitude,
    this.longitude,
    this.notes,
    this.isDefault = false,
  });

  final String id;
  final AddressLabel label;
  final String line1;
  final String? line2;
  final String city;
  final String postcode;
  final String state;
  final double? latitude;
  final double? longitude;

  /// Rider instructions, e.g. "Leave at guard house".
  final String? notes;
  final bool isDefault;

  /// `12 Jalan Bukit Bintang, 50200 Kuala Lumpur, WP Kuala Lumpur`
  String get formatted => <String>[
        line1,
        if (line2 != null && line2!.isNotEmpty) line2!,
        '$postcode $city',
        state,
      ].join(', ');

  String get shortForm => line2 == null || line2!.isEmpty
      ? '$line1, $city'
      : '$line1, $line2, $city';

  Address copyWith({
    AddressLabel? label,
    String? line1,
    String? line2,
    String? city,
    String? postcode,
    String? state,
    String? notes,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      state: state ?? this.state,
      latitude: latitude,
      longitude: longitude,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        label,
        line1,
        line2,
        city,
        postcode,
        state,
        notes,
        isDefault,
      ];
}
