import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../../core/utils/result.dart';
import '../../../domain/usecases/catalog_usecases.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Drives the home feed.
///
/// Pull-to-refresh keeps the previous feed on screen (`isRefreshing`) instead
/// of dropping back to skeletons - re-showing a loading state for content the
/// user is already looking at reads as a bug.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required GetHomeFeed getHomeFeed})
      : _getHomeFeed = getHomeFeed,
        super(const HomeState()) {
    on<HomeRequested>(_onRequested);
    on<HomeRefreshed>(_onRefreshed);
  }

  final GetHomeFeed _getHomeFeed;

  Future<void> _onRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _load(emit);
  }

  Future<void> _load(Emitter<HomeState> emit) async {
    final Result<HomeFeed> result = await _getHomeFeed(const NoParams());
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          // A refresh failure keeps the stale feed and surfaces a message
          // rather than blanking the screen.
          status: state.feed == null ? HomeStatus.failure : HomeStatus.success,
          isRefreshing: false,
          errorMessage: failure.message,
        ),
      ),
      (HomeFeed feed) => emit(
        state.copyWith(
          status: HomeStatus.success,
          feed: feed,
          isRefreshing: false,
          clearError: true,
        ),
      ),
    );
  }
}
