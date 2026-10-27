part of 'restaurant_bloc.dart';

enum RestaurantStatus { initial, loading, success, failure }

class RestaurantState extends Equatable {
  const RestaurantState({
    this.status = RestaurantStatus.initial,
    this.detail,
    this.isFavourite = false,
    this.selectedSectionId,
    this.menuQuery = '',
    this.errorMessage,
  });

  final RestaurantStatus status;
  final RestaurantDetail? detail;
  final bool isFavourite;
  final String? selectedSectionId;

  /// In-menu search, applied on top of the section grouping.
  final String menuQuery;
  final String? errorMessage;

  bool get isLoading =>
      status == RestaurantStatus.loading || status == RestaurantStatus.initial;

  /// Menu sections with [menuQuery] applied. Sections that end up empty are
  /// dropped so the list never shows a header with nothing under it.
  Map<FoodCategory, List<FoodItem>> get visibleSections {
    final Map<FoodCategory, List<FoodItem>> all =
        detail?.menuSections ?? <FoodCategory, List<FoodItem>>{};
    final String needle = menuQuery.trim().toLowerCase();
    if (needle.isEmpty) return all;

    final Map<FoodCategory, List<FoodItem>> filtered =
        <FoodCategory, List<FoodItem>>{};
    all.forEach((FoodCategory category, List<FoodItem> items) {
      final List<FoodItem> matches = items
          .where(
            (FoodItem i) =>
                i.name.toLowerCase().contains(needle) ||
                i.description.toLowerCase().contains(needle),
          )
          .toList(growable: false);
      if (matches.isNotEmpty) filtered[category] = matches;
    });
    return filtered;
  }

  bool get hasMenuResults => visibleSections.isNotEmpty;

  RestaurantState copyWith({
    RestaurantStatus? status,
    RestaurantDetail? detail,
    bool? isFavourite,
    String? selectedSectionId,
    String? menuQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RestaurantState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isFavourite: isFavourite ?? this.isFavourite,
      selectedSectionId: selectedSectionId ?? this.selectedSectionId,
      menuQuery: menuQuery ?? this.menuQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        detail,
        isFavourite,
        selectedSectionId,
        menuQuery,
        errorMessage,
      ];
}
