part of 'checkout_bloc.dart';

enum CheckoutStatus { initial, loading, ready, placing, placed }

class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.user,
    this.addresses = const <Address>[],
    this.selectedAddress,
    this.paymentMethod = PaymentMethod.grabPay,
    this.riderNote = '',
    this.placedOrder,
    this.errorMessage,
  });

  final CheckoutStatus status;
  final User? user;
  final List<Address> addresses;
  final Address? selectedAddress;
  final PaymentMethod paymentMethod;
  final String riderNote;

  /// Set once the order is created; the screen navigates to tracking on this.
  final Order? placedOrder;
  final String? errorMessage;

  bool get isLoading =>
      status == CheckoutStatus.loading || status == CheckoutStatus.initial;

  bool get isPlacing => status == CheckoutStatus.placing;

  bool get canPlaceOrder => selectedAddress != null && !isPlacing;

  CheckoutState copyWith({
    CheckoutStatus? status,
    User? user,
    List<Address>? addresses,
    Address? selectedAddress,
    PaymentMethod? paymentMethod,
    String? riderNote,
    Order? placedOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      user: user ?? this.user,
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      riderNote: riderNote ?? this.riderNote,
      placedOrder: placedOrder ?? this.placedOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        user,
        addresses,
        selectedAddress,
        paymentMethod,
        riderNote,
        placedOrder,
        errorMessage,
      ];
}
