import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../core/error/failures.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/usecases/catalog_usecases.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Debounced catalogue search over restaurants and dishes.
///
/// `restartable` plus a debounce means only the newest query is ever in flight,
/// so a fast typist cannot get results from an earlier keystroke landing last.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required SearchCatalog searchCatalog,
    required LocalStorage storage,
  })  : _searchCatalog = searchCatalog,
        _storage = storage,
        super(SearchState(recentQueries: storage.getStringList(LocalStorage.kRecentSearches))) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: restartable(),
    );
    on<SearchCleared>(_onCleared);
    on<SearchRecentRemoved>(_onRecentRemoved);
  }

  final SearchCatalog _searchCatalog;
  final LocalStorage _storage;

  static const Duration _debounce = Duration(milliseconds: 320);
  static const int _maxRecent = 8;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final String query = event.query.trim();
    emit(state.copyWith(query: event.query));

    if (query.length < 2) {
      emit(state.copyWith(status: SearchStatus.idle, clearResults: true));
      return;
    }

    await Future<void>.delayed(_debounce);
    if (emit.isDone) return;

    emit(state.copyWith(status: SearchStatus.searching));

    final Result<SearchResults> result = await _searchCatalog(query);
    if (emit.isDone) return;

    await result.fold(
      (Failure failure) async => emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (SearchResults results) async {
        // Only remember queries that actually found something - a typo in the
        // history is noise, not a shortcut.
        if (!results.isEmpty) await _remember(query);
        emit(
          state.copyWith(
            status: SearchStatus.success,
            results: results,
            recentQueries: _storage.getStringList(LocalStorage.kRecentSearches),
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _remember(String query) async {
    final List<String> recent =
        List<String>.of(_storage.getStringList(LocalStorage.kRecentSearches))
          ..removeWhere((String q) => q.toLowerCase() == query.toLowerCase())
          ..insert(0, query);
    await _storage.setStringList(
      LocalStorage.kRecentSearches,
      recent.take(_maxRecent).toList(growable: false),
    );
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(
      state.copyWith(
        query: '',
        status: SearchStatus.idle,
        clearResults: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onRecentRemoved(
    SearchRecentRemoved event,
    Emitter<SearchState> emit,
  ) async {
    final List<String> recent =
        List<String>.of(_storage.getStringList(LocalStorage.kRecentSearches))
          ..remove(event.query);
    await _storage.setStringList(LocalStorage.kRecentSearches, recent);
    emit(state.copyWith(recentQueries: recent));
  }
}
