import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/cart.dart';
import '../entities/food_item.dart';
import '../entities/promo.dart';
import '../entities/restaurant.dart';
import '../repositories/cart_repository.dart';
import '../repositories/catalog_repository.dart';

class LoadCart extends UseCase<Cart, NoParams> {
  const LoadCart(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(NoParams params) => _repository.load();
}

class AddToCartParams extends Equatable {
  const AddToCartParams({
    required this.item,
    required this.restaurant,
    this.quantity = 1,
    this.notes = '',
  });

  final FoodItem item;
  final Restaurant restaurant;
  final int quantity;
  final String notes;

  @override
  List<Object?> get props => <Object?>[item, restaurant, quantity, notes];
}

/// Adds a dish, refusing sold-out items and closed restaurants before the
/// repository is involved.
class AddToCart extends UseCase<Cart, AddToCartParams> {
  const AddToCart(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(AddToCartParams params) async {
    if (!params.item.isAvailable) {
      return Result<Cart>.failure(
        ValidationFailure('${params.item.name} is sold out right now.'),
      );
    }
    if (!params.restaurant.isOpen) {
      return Result<Cart>.failure(
        ValidationFailure('${params.restaurant.name} is currently closed.'),
      );
    }
    if (params.quantity < 1) {
      return const Result<Cart>.failure(
        ValidationFailure('Quantity must be at least 1.'),
      );
    }
    return _repository.addItem(
      item: params.item,
      restaurant: params.restaurant,
      quantity: params.quantity,
      notes: params.notes,
    );
  }
}

class UpdateQuantityParams extends Equatable {
  const UpdateQuantityParams({required this.lineId, required this.quantity});

  final String lineId;
  final int quantity;

  @override
  List<Object?> get props => <Object?>[lineId, quantity];
}

/// Setting quantity to zero removes the line - the stepper's minus button at
/// quantity 1 relies on this.
class UpdateCartQuantity extends UseCase<Cart, UpdateQuantityParams> {
  const UpdateCartQuantity(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(UpdateQuantityParams params) {
    if (params.quantity <= 0) {
      return _repository.removeLine(params.lineId);
    }
    return _repository.updateQuantity(
      lineId: params.lineId,
      quantity: params.quantity,
    );
  }
}

class RemoveCartLine extends UseCase<Cart, String> {
  const RemoveCartLine(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(String lineId) => _repository.removeLine(lineId);
}

class ClearCart extends UseCase<Cart, NoParams> {
  const ClearCart(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(NoParams params) => _repository.clear();
}

/// Resolves a typed voucher code against the promo catalogue, then applies it.
class ApplyPromoCode extends UseCase<Cart, String> {
  const ApplyPromoCode(this._cart, this._catalog);

  final CartRepository _cart;
  final CatalogRepository _catalog;

  @override
  Future<Result<Cart>> call(String code) async {
    final String normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const Result<Cart>.failure(
        ValidationFailure('Enter a promo code.'),
      );
    }

    final Result<List<Promo>> promosResult = await _catalog.getPromos();
    if (promosResult.failureOrNull case final failure?) {
      return Result<Cart>.failure(failure);
    }

    final Promo? promo = promosResult.valueOrNull!
        .where((Promo p) => p.code.toUpperCase() == normalized)
        .firstOrNull;

    if (promo == null) {
      return Result<Cart>.failure(
        ValidationFailure('"$normalized" is not a valid promo code.'),
      );
    }
    if (promo.isExpired) {
      return const Result<Cart>.failure(
        ValidationFailure('This promo code has expired.'),
      );
    }

    final Result<Cart> cartResult = await _cart.load();
    if (cartResult.failureOrNull case final failure?) {
      return Result<Cart>.failure(failure);
    }
    final Cart cart = cartResult.valueOrNull!;
    if (!promo.isEligibleFor(cart.subtotal)) {
      return Result<Cart>.failure(
        ValidationFailure(
          'Spend at least RM ${promo.minSpendMyr.toStringAsFixed(0)} to use this code.',
        ),
      );
    }

    return _cart.applyPromo(promo);
  }
}

class RemovePromo extends UseCase<Cart, NoParams> {
  const RemovePromo(this._repository);

  final CartRepository _repository;

  @override
  Future<Result<Cart>> call(NoParams params) => _repository.removePromo();
}
