import 'package:equatable/equatable.dart';

/// Operational city/region served by SURUH platform.
/// Loaded dynamically from the backend API.
class OperationalCity extends Equatable {
  const OperationalCity({
    required this.id,
    required this.name,
    required this.slug,
    this.whatsappNumber,
    this.sortOrder = 0,
  });

  factory OperationalCity.fromJson(Map<String, dynamic> json) {
    return OperationalCity(
      id: json['id']?.toString() ?? json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      whatsappNumber: json['effective_whatsapp_number']?.toString() ??
          json['whatsapp_number']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'slug': slug,
        'whatsapp_number': whatsappNumber,
        'sort_order': sortOrder,
      };

  final String id;
  final String name;
  final String slug;
  final String? whatsappNumber;
  final int sortOrder;

  @override
  List<Object?> get props => <Object?>[id, name, slug, whatsappNumber, sortOrder];
}
