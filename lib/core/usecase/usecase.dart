import 'package:equatable/equatable.dart';

import '../utils/result.dart';

/// A single unit of application business logic.
///
/// Blocs depend on use cases, never on repositories directly - that keeps
/// orchestration (e.g. "place order" = validate cart + reserve + charge) out of
/// the presentation layer and makes it independently testable.
abstract class UseCase<T, Params> {
  const UseCase();

  Future<Result<T>> call(Params params);
}

/// A use case that exposes a live stream instead of a one-shot future.
abstract class StreamUseCase<T, Params> {
  const StreamUseCase();

  Stream<T> call(Params params);
}

/// Marker for use cases that take no arguments.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const <Object?>[];
}
