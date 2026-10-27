part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

class SearchRecentRemoved extends SearchEvent {
  const SearchRecentRemoved(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}
