import '../../core/utils/result.dart';
import '../entities/cart.dart';
import '../entities/food_item.dart';
import '../entities/promo.dart';
import '../entities/restaurant.dart';

/// Persisted basket. Survives app restarts via local storage so a half-built
/// order is never lost.
abstract interface class CartRepository {
  Future<Result<Cart>> load();

  /// Adds [item] to the basket.
  ///
  /// Fails with a `ValidationFailure` when the cart already holds dishes from
  /// a different restaurant - callers should prompt to clear first.
  Future<Result<Cart>> addItem({
    required FoodItem item,
    required Restaurant restaurant,
    int quantity = 1,
    String notes = '',
  });

  Future<Result<Cart>> updateQuantity({
    required String lineId,
    required int quantity,
  });

  Future<Result<Cart>> removeLine(String lineId);

  Future<Result<Cart>> applyPromo(Promo promo);

  Future<Result<Cart>> removePromo();

  Future<Result<Cart>> clear();
}
