import '../../domain/entities/cart.dart';
import 'food_item_model.dart';
import 'promo_model.dart';

/// Cart JSON is written to local storage on every mutation, which is what makes
/// the basket survive a browser refresh or app restart.
abstract final class CartMapper {
  static Map<String, dynamic> toJson(Cart cart) => <String, dynamic>{
        'restaurantId': cart.restaurantId,
        'restaurantName': cart.restaurantName,
        'deliveryFeeMyr': cart.deliveryFeeMyr,
        'minOrderMyr': cart.minOrderMyr,
        'lines': cart.lines.map(cartItemToJson).toList(growable: false),
        'appliedPromo': cart.appliedPromo == null
            ? null
            : PromoModel.fromEntity(cart.appliedPromo!).toJson(),
      };

  static Cart fromJson(Map<String, dynamic> json) => Cart(
        restaurantId: json['restaurantId'] as String?,
        restaurantName: json['restaurantName'] as String? ?? '',
        deliveryFeeMyr: (json['deliveryFeeMyr'] as num?)?.toDouble() ?? 0,
        minOrderMyr: (json['minOrderMyr'] as num?)?.toDouble() ?? 0,
        lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => cartItemFromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        appliedPromo: json['appliedPromo'] == null
            ? null
            : PromoModel.fromJson(
                json['appliedPromo'] as Map<String, dynamic>,
              ),
      );

  static Map<String, dynamic> cartItemToJson(CartItem line) =>
      <String, dynamic>{
        'item': FoodItemModel.fromEntity(line.item).toJson(),
        'quantity': line.quantity,
        'notes': line.notes,
      };

  static CartItem cartItemFromJson(Map<String, dynamic> json) => CartItem(
        item: FoodItemModel.fromJson(json['item'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        notes: json['notes'] as String? ?? '',
      );
}
