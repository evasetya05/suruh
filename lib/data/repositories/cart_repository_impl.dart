import '../../core/error/failures.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/cart_repository.dart';
import '../models/cart_model.dart';

/// Local-only cart.
///
/// The basket is device state, not server state, so it lives entirely in
/// [LocalStorage] and is written synchronously after every mutation. That makes
/// it survive a web refresh and an app kill without any backend round-trip.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({required LocalStorage storage}) : _storage = storage;

  final LocalStorage _storage;

  @override
  Future<Result<Cart>> load() => guard<Cart>(() async => _read());

  @override
  Future<Result<Cart>> addItem({
    required FoodItem item,
    required Restaurant restaurant,
    int quantity = 1,
    String notes = '',
  }) {
    return guard<Cart>(() async {
      final Cart current = _read();

      // One restaurant per cart. The UI catches this first and offers to start
      // a new basket, but the rule is enforced here so it holds regardless of
      // which caller reaches it.
      if (!current.belongsTo(restaurant.id) && current.isNotEmpty) {
        throw ValidationFailure(
          'Your cart already has items from ${current.restaurantName}. '
          'Clear it to order from ${restaurant.name}.',
        );
      }

      final CartItem candidate =
          CartItem(item: item, quantity: quantity, notes: notes);
      final List<CartItem> lines = List<CartItem>.of(current.lines);
      final int existing =
          lines.indexWhere((CartItem l) => l.lineId == candidate.lineId);

      if (existing == -1) {
        lines.add(candidate);
      } else {
        lines[existing] = lines[existing]
            .copyWith(quantity: lines[existing].quantity + quantity);
      }

      final Cart updated = current.copyWith(
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        deliveryFeeMyr: restaurant.deliveryFeeMyr,
        minOrderMyr: restaurant.minOrderMyr,
        lines: lines,
      );
      return _write(updated);
    });
  }

  @override
  Future<Result<Cart>> updateQuantity({
    required String lineId,
    required int quantity,
  }) {
    return guard<Cart>(() async {
      final Cart current = _read();
      final List<CartItem> lines = List<CartItem>.of(current.lines);
      final int index = lines.indexWhere((CartItem l) => l.lineId == lineId);
      if (index == -1) {
        throw const NotFoundFailure('That item is no longer in your cart.');
      }
      lines[index] = lines[index].copyWith(quantity: quantity);
      return _write(current.copyWith(lines: lines));
    });
  }

  @override
  Future<Result<Cart>> removeLine(String lineId) {
    return guard<Cart>(() async {
      final Cart current = _read();
      final List<CartItem> lines = current.lines
          .where((CartItem l) => l.lineId != lineId)
          .toList(growable: false);

      // Emptying the cart also releases the restaurant lock and any promo, so
      // the next dish added can come from anywhere.
      if (lines.isEmpty) return _write(Cart.empty);
      return _write(current.copyWith(lines: lines));
    });
  }

  @override
  Future<Result<Cart>> applyPromo(Promo promo) {
    return guard<Cart>(() async {
      final Cart current = _read();
      if (!promo.isEligibleFor(current.subtotal)) {
        throw ValidationFailure(
          'Spend at least RM ${promo.minSpendMyr.toStringAsFixed(0)} '
          'to use ${promo.code}.',
        );
      }
      return _write(current.copyWith(appliedPromo: promo));
    });
  }

  @override
  Future<Result<Cart>> removePromo() => guard<Cart>(
        () async => _write(_read().copyWith(clearPromo: true)),
      );

  @override
  Future<Result<Cart>> clear() => guard<Cart>(() async {
        await _storage.remove(LocalStorage.kCart);
        return Cart.empty;
      });

  Cart _read() {
    final Map<String, dynamic>? json = _storage.readJson(LocalStorage.kCart);
    if (json == null) return Cart.empty;
    return CartMapper.fromJson(json);
  }

  Future<Cart> _write(Cart cart) async {
    if (cart.isEmpty) {
      await _storage.remove(LocalStorage.kCart);
      return Cart.empty;
    }
    await _storage.writeJson(LocalStorage.kCart, CartMapper.toJson(cart));
    return cart;
  }
}
