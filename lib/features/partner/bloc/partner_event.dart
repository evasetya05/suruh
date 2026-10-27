part of 'partner_bloc.dart';

sealed class PartnerEvent extends Equatable {
  const PartnerEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class PartnerStarted extends PartnerEvent {
  const PartnerStarted(this.ownerId);

  final String ownerId;

  @override
  List<Object?> get props => <Object?>[ownerId];
}

/// Emitted internally when the order stream pushes a new snapshot.
class PartnerOrdersUpdated extends PartnerEvent {
  const PartnerOrdersUpdated(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => <Object?>[orders];
}

class PartnerOrderAdvanced extends PartnerEvent {
  const PartnerOrderAdvanced({required this.orderId, required this.status});

  final String orderId;
  final OrderStatus status;

  @override
  List<Object?> get props => <Object?>[orderId, status];
}

class PartnerMenuItemCreated extends PartnerEvent {
  const PartnerMenuItemCreated(this.params);

  final CreateMenuItemParams params;

  @override
  List<Object?> get props => <Object?>[params];
}

class PartnerMenuItemUpdated extends PartnerEvent {
  const PartnerMenuItemUpdated(this.item);

  final FoodItem item;

  @override
  List<Object?> get props => <Object?>[item];
}

class PartnerMenuItemDeleted extends PartnerEvent {
  const PartnerMenuItemDeleted(this.foodItemId);

  final String foodItemId;

  @override
  List<Object?> get props => <Object?>[foodItemId];
}

class PartnerAvailabilityToggled extends PartnerEvent {
  const PartnerAvailabilityToggled({
    required this.foodItemId,
    required this.isAvailable,
  });

  final String foodItemId;
  final bool isAvailable;

  @override
  List<Object?> get props => <Object?>[foodItemId, isAvailable];
}

class PartnerStoreToggled extends PartnerEvent {
  const PartnerStoreToggled(this.isOpen);

  final bool isOpen;

  @override
  List<Object?> get props => <Object?>[isOpen];
}

class PartnerMessageCleared extends PartnerEvent {
  const PartnerMessageCleared();
}
