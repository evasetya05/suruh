part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// First load - shows skeletons.
class HomeRequested extends HomeEvent {
  const HomeRequested();
}

/// Pull-to-refresh - keeps the existing feed visible while reloading.
class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}
