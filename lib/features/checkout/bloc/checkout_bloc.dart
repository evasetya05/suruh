import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

/// Checkout: pick an address, pick a payment method, place the order.
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required PlaceOrder placeOrder,
    required GetAddresses getAddresses,
  })  : _placeOrder = placeOrder,
        _getAddresses = getAddresses,
        super(const CheckoutState()) {
    on<CheckoutStarted>(_onStarted);
    on<CheckoutAddressSelected>(_onAddressSelected);
    on<CheckoutPaymentSelected>(_onPaymentSelected);
    on<CheckoutNoteChanged>(_onNoteChanged);
    on<CheckoutSubmitted>(_onSubmitted);
  }

  final PlaceOrder _placeOrder;
  final GetAddresses _getAddresses;

  Future<void> _onStarted(
    CheckoutStarted event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.loading, user: event.user));

    final Result<List<Address>> result = await _getAddresses(event.user.id);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          errorMessage: failure.message,
        ),
      ),
      (List<Address> addresses) => emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          addresses: addresses,
          // Default to the address marked default, so most checkouts are a
          // single tap on "Place order".
          selectedAddress: addresses.isEmpty
              ? null
              : addresses.firstWhere(
                  (Address a) => a.isDefault,
                  orElse: () => addresses.first,
                ),
          clearError: true,
        ),
      ),
    );
  }

  void _onAddressSelected(
    CheckoutAddressSelected event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(selectedAddress: event.address));
  }

  void _onPaymentSelected(
    CheckoutPaymentSelected event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(paymentMethod: event.method));
  }

  void _onNoteChanged(
    CheckoutNoteChanged event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(riderNote: event.note));
  }

  Future<void> _onSubmitted(
    CheckoutSubmitted event,
    Emitter<CheckoutState> emit,
  ) async {
    final Address? address = state.selectedAddress;
    final User? user = state.user;

    if (address == null || user == null) {
      emit(
        state.copyWith(
          errorMessage: 'Choose a delivery address before placing the order.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.placing, clearError: true));

    final Result<Order> result = await _placeOrder(
      PlaceOrderParams(
        cart: event.cart,
        address: address,
        paymentMethod: state.paymentMethod,
        user: user,
        riderNote: state.riderNote.isEmpty ? null : state.riderNote,
      ),
    );

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          errorMessage: failure.message,
        ),
      ),
      (Order order) => emit(
        state.copyWith(status: CheckoutStatus.placed, placedOrder: order),
      ),
    );
  }
}
