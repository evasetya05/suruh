part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.feed,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final HomeStatus status;
  final HomeFeed? feed;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isLoading =>
      status == HomeStatus.loading || status == HomeStatus.initial;

  bool get hasFeed => feed != null;

  HomeState copyWith({
    HomeStatus? status,
    HomeFeed? feed,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, feed, isRefreshing, errorMessage];
}
