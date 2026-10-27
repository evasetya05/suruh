part of 'checkout_bloc.dart';

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class CheckoutStarted extends CheckoutEvent {
  const CheckoutStarted(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

class CheckoutAddressSelected extends CheckoutEvent {
  const CheckoutAddressSelected(this.address);

  final Address address;

  @override
  List<Object?> get props => <Object?>[address];
}

class CheckoutPaymentSelected extends CheckoutEvent {
  const CheckoutPaymentSelected(this.method);

  final PaymentMethod method;

  @override
  List<Object?> get props => <Object?>[method];
}

class CheckoutNoteChanged extends CheckoutEvent {
  const CheckoutNoteChanged(this.note);

  final String note;

  @override
  List<Object?> get props => <Object?>[note];
}

/// The cart travels with the event rather than being held in checkout state,
/// so the order is always placed against the basket as it is right now.
class CheckoutSubmitted extends CheckoutEvent {
  const CheckoutSubmitted(this.cart);

  final Cart cart;

  @override
  List<Object?> get props => <Object?>[cart];
}
