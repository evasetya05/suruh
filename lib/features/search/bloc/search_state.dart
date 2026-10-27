part of 'search_bloc.dart';

enum SearchStatus { idle, searching, success, failure }

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.idle,
    this.results,
    this.recentQueries = const <String>[],
    this.errorMessage,
  });

  final String query;
  final SearchStatus status;
  final SearchResults? results;
  final List<String> recentQueries;
  final String? errorMessage;

  bool get isSearching => status == SearchStatus.searching;

  /// True when a completed search returned nothing.
  bool get hasNoResults =>
      status == SearchStatus.success && (results?.isEmpty ?? true);

  List<Restaurant> get restaurants => results?.restaurants ?? const <Restaurant>[];
  List<FoodItem> get dishes => results?.dishes ?? const <FoodItem>[];

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    SearchResults? results,
    List<String>? recentQueries,
    String? errorMessage,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: clearResults ? null : (results ?? this.results),
      recentQueries: recentQueries ?? this.recentQueries,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        query,
        status,
        results?.query,
        results?.totalCount,
        recentQueries,
        errorMessage,
      ];
}
