part of 'browse_bloc.dart';

sealed class BrowseEvent extends Equatable {
  const BrowseEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class BrowseStarted extends BrowseEvent {
  const BrowseStarted({this.categoryId});

  /// Pre-selected category when arriving from a home tile.
  final String? categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

class BrowseFilterChanged extends BrowseEvent {
  const BrowseFilterChanged(this.filter);

  final RestaurantFilter filter;

  @override
  List<Object?> get props => <Object?>[
        filter.categoryId,
        filter.sort,
        filter.freeDeliveryOnly,
        filter.openNowOnly,
        filter.minRating,
        filter.maxPriceLevel,
      ];
}

class BrowseFiltersCleared extends BrowseEvent {
  const BrowseFiltersCleared();
}
