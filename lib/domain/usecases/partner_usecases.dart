import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/food_item.dart';
import '../entities/order.dart';
import '../entities/restaurant.dart';
import '../repositories/partner_repository.dart';

/// Everything the partner dashboard shows above the order list.
class PartnerDashboard extends Equatable {
  const PartnerDashboard({
    required this.restaurant,
    required this.stats,
    required this.menu,
  });

  final Restaurant restaurant;
  final PartnerStats stats;
  final List<FoodItem> menu;

  @override
  List<Object?> get props => <Object?>[restaurant, menu];
}

/// Resolves the partner's restaurant, then loads its stats and menu together.
class GetPartnerDashboard extends UseCase<PartnerDashboard, String> {
  const GetPartnerDashboard(this._repository);

  final PartnerRepository _repository;

  @override
  Future<Result<PartnerDashboard>> call(String ownerId) async {
    final Result<Restaurant> restaurantResult =
        await _repository.getManagedRestaurant(ownerId);
    if (restaurantResult.failureOrNull case final failure?) {
      return Result<PartnerDashboard>.failure(failure);
    }
    final Restaurant restaurant = restaurantResult.valueOrNull!;

    final List<Object> parts = await Future.wait<Object>(<Future<Object>>[
      _repository.getStats(restaurant.id),
      _repository.getMenu(restaurant.id),
    ]);

    final Result<PartnerStats> stats = parts[0] as Result<PartnerStats>;
    if (stats.failureOrNull case final failure?) {
      return Result<PartnerDashboard>.failure(failure);
    }
    final Result<List<FoodItem>> menu = parts[1] as Result<List<FoodItem>>;
    if (menu.failureOrNull case final failure?) {
      return Result<PartnerDashboard>.failure(failure);
    }

    return Result<PartnerDashboard>.success(
      PartnerDashboard(
        restaurant: restaurant,
        stats: stats.valueOrNull!,
        menu: menu.valueOrNull!,
      ),
    );
  }
}

class CreateMenuItemParams extends Equatable {
  const CreateMenuItemParams({
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.priceMyr,
    required this.categoryId,
    required this.emoji,
    this.discountPriceMyr,
    this.ingredients = const <String>[],
    this.isVegetarian = false,
    this.isSpicy = false,
    this.prepMinutes = 15,
  });

  final String restaurantId;
  final String name;
  final String description;
  final double priceMyr;
  final String categoryId;
  final String emoji;
  final double? discountPriceMyr;
  final List<String> ingredients;
  final bool isVegetarian;
  final bool isSpicy;
  final int prepMinutes;

  @override
  List<Object?> get props =>
      <Object?>[restaurantId, name, priceMyr, categoryId, discountPriceMyr];
}

class CreateMenuItem extends UseCase<FoodItem, CreateMenuItemParams> {
  const CreateMenuItem(this._repository);

  final PartnerRepository _repository;

  @override
  Future<Result<FoodItem>> call(CreateMenuItemParams params) async {
    if (params.name.trim().isEmpty) {
      return const Result<FoodItem>.failure(
        ValidationFailure('Dish name is required.'),
      );
    }
    if (params.priceMyr <= 0) {
      return const Result<FoodItem>.failure(
        ValidationFailure('Price must be greater than 0.'),
      );
    }
    if (params.discountPriceMyr != null &&
        params.discountPriceMyr! >= params.priceMyr) {
      return const Result<FoodItem>.failure(
        ValidationFailure(
          'Offer price must be lower than the normal price.',
        ),
      );
    }
    return _repository.createMenuItem(
      restaurantId: params.restaurantId,
      name: params.name.trim(),
      description: params.description.trim(),
      priceMyr: params.priceMyr,
      categoryId: params.categoryId,
      emoji: params.emoji,
      discountPriceMyr: params.discountPriceMyr,
      ingredients: params.ingredients,
      isVegetarian: params.isVegetarian,
      isSpicy: params.isSpicy,
      prepMinutes: params.prepMinutes,
    );
  }
}

class UpdateMenuItem extends UseCase<FoodItem, FoodItem> {
  const UpdateMenuItem(this._repository);

  final PartnerRepository _repository;

  @override
  Future<Result<FoodItem>> call(FoodItem item) {
    if (item.name.trim().isEmpty) {
      return Future<Result<FoodItem>>.value(
        const Result<FoodItem>.failure(
          ValidationFailure('Dish name is required.'),
        ),
      );
    }
    return _repository.updateMenuItem(item);
  }
}

class DeleteMenuItem extends UseCase<void, String> {
  const DeleteMenuItem(this._repository);

  final PartnerRepository _repository;

  @override
  Future<Result<void>> call(String foodItemId) =>
      _repository.deleteMenuItem(foodItemId);
}

class SetItemAvailabilityParams extends Equatable {
  const SetItemAvailabilityParams({
    required this.foodItemId,
    required this.isAvailable,
  });

  final String foodItemId;
  final bool isAvailable;

  @override
  List<Object?> get props => <Object?>[foodItemId, isAvailable];
}

class SetItemAvailability extends UseCase<FoodItem, SetItemAvailabilityParams> {
  const SetItemAvailability(this._repository);

  final PartnerRepository _repository;

  @override
  Future<Result<FoodItem>> call(SetItemAvailabilityParams params) =>
      _repository.setItemAvailability(
        foodItemId: params.foodItemId,
        isAvailable: params.isAvailable,
      );
}

class SetRestaurantOpenParams extends Equatable {
  const SetRestaurantOpenParams({
    required this.restaurantId,
    required this.isOpen,
  });

  final String restaurantId;
  final bool isOpen;

  @override
  List<Object?> get props => <Object?>[restaurantId, isOpen];
}

class SetRestaurantOpen extends UseCase<Restaurant, SetRestaurantOpenParams> {
  const SetRestaurantOpen(this._repository);

  final PartnerRepository _repository;

  @override
  Future<Result<Restaurant>> call(SetRestaurantOpenParams params) =>
      _repository.setRestaurantOpen(
        restaurantId: params.restaurantId,
        isOpen: params.isOpen,
      );
}

/// Groups a partner's orders into the dashboard's three queues.
class PartnerOrderQueues {
  const PartnerOrderQueues({
    required this.incoming,
    required this.inKitchen,
    required this.completed,
  });

  /// Awaiting acceptance.
  final List<Order> incoming;

  /// Accepted, being cooked or waiting for a rider.
  final List<Order> inKitchen;

  /// Delivered or cancelled.
  final List<Order> completed;

  factory PartnerOrderQueues.fromOrders(List<Order> orders) {
    return PartnerOrderQueues(
      incoming: orders
          .where((Order o) => o.status == OrderStatus.placed)
          .toList(growable: false),
      inKitchen: orders
          .where(
            (Order o) =>
                o.status == OrderStatus.confirmed ||
                o.status == OrderStatus.preparing ||
                o.status == OrderStatus.readyForPickup ||
                o.status == OrderStatus.outForDelivery,
          )
          .toList(growable: false),
      completed: orders
          .where((Order o) => o.status.isTerminal)
          .toList(growable: false),
    );
  }
}
