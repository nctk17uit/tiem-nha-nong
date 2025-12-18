import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/models/payment_method.dart';
import 'package:mobile/models/order.dart';
import 'package:mobile/repositories/order_repository.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:mobile/controllers/address_controller.dart';

class CheckoutState {
  final ShippingAddress? selectedAddress;
  final PaymentMethod? selectedPayment;
  final List<PaymentMethod> availableMethods;
  final String? couponCode;
  final double discountAmount;
  final bool isLoading;
  final String? error;

  CheckoutState({
    this.selectedAddress,
    this.selectedPayment,
    this.availableMethods = const [],
    this.couponCode,
    this.discountAmount = 0,
    this.isLoading = false,
    this.error,
  });

  CheckoutState copyWith({
    ShippingAddress? selectedAddress,
    bool forceClearAddress = false, // If true, sets selectedAddress to null
    PaymentMethod? selectedPayment,
    List<PaymentMethod>? availableMethods,
    String? couponCode,
    double? discountAmount,
    bool? isLoading,
    String? error,
  }) {
    return CheckoutState(
      // If force flag is on, use null. Else use new value or keep old value.
      selectedAddress: forceClearAddress
          ? null
          : (selectedAddress ?? this.selectedAddress),

      selectedPayment: selectedPayment ?? this.selectedPayment,
      availableMethods: availableMethods ?? this.availableMethods,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    // 1. LIVE LISTENER: Watch address changes in the background
    ref.listen(addressControllerProvider, (previous, next) {
      next.whenData((currentAddresses) {
        _validateSelectedAddress(currentAddresses);
      });
    });

    // 2. NEW: Sync Coupon with Cart Total
    // If the cart total changes, re-apply the coupon to validate against new rules
    ref.listen(cartControllerProvider, (previous, next) {
      if (state.couponCode != null && previous?.total != next.total) {
        applyCoupon(state.couponCode!);
      }
    });

    // 3. Initialize Data
    Future(() async {
      await _loadPaymentMethods();
      await _loadDefaultAddress();
    });

    return CheckoutState();
  }

  // --- SYNC LOGIC ---
  void _validateSelectedAddress(List<ShippingAddress> currentAddresses) {
    // A. No address selected yet? Try to auto-select default.
    if (state.selectedAddress == null) {
      if (currentAddresses.isNotEmpty) {
        final defaultAddr = currentAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => currentAddresses.first,
        );
        state = state.copyWith(selectedAddress: defaultAddr);
      }
      return;
    }

    // B. We have a selection. Does it still exist?
    final currentSelectedId = state.selectedAddress!.id;
    final matchIndex = currentAddresses.indexWhere(
      (a) => a.id == currentSelectedId,
    );

    if (matchIndex == -1) {
      // SCENARIO 1: Selected address was DELETED.
      if (currentAddresses.isNotEmpty) {
        // Fallback to new default
        final newDefault = currentAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => currentAddresses.first,
        );
        state = state.copyWith(selectedAddress: newDefault);
      } else {
        // SCENARIO 2: List is EMPTY. Force clear.
        state = state.copyWith(forceClearAddress: true);
      }
    } else {
      // SCENARIO 3: Address exists (maybe edited). Update state.
      state = state.copyWith(selectedAddress: currentAddresses[matchIndex]);
    }
  }

  // --- LOADERS ---

  Future<void> _loadDefaultAddress() async {
    try {
      // Use controller provider to share cache
      final addresses = await ref.read(addressControllerProvider.future);

      if (state.selectedAddress == null && addresses.isNotEmpty) {
        final defaultAddr = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        state = state.copyWith(selectedAddress: defaultAddr);
      }
    } catch (e) {
      // Silently fail, UI will show "Add Address"
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await ref
          .read(orderRepositoryProvider)
          .getPaymentMethods();

      // --- FIX: Filter the list to only show enabled items ---
      final activeMethods = methods.where((m) => m.isEnabled).toList();

      if (activeMethods.isNotEmpty) {
        // Auto-select the first valid method
        state = state.copyWith(
          availableMethods: activeMethods,
          selectedPayment: activeMethods.first,
        );
      } else {
        // Handle case where NO payment methods are available
        state = state.copyWith(availableMethods: [], selectedPayment: null);
      }
    } catch (e) {
      print("Payment fetch error: $e");
    }
  }

  void setAddress(ShippingAddress address) {
    state = state.copyWith(selectedAddress: address);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPayment: method);
  }

  Future<void> applyCoupon(String code) async {
    if (code.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    final cartTotal = ref.read(cartControllerProvider).total;

    try {
      final result = await ref
          .read(orderRepositoryProvider)
          .applyCoupon(code: code, cartTotal: cartTotal);

      state = state.copyWith(
        isLoading: false,
        couponCode: code,
        discountAmount: (result['discount_amount'] as num).toDouble(),
      );
    } catch (e) {
      // Clear coupon data on error and store the message
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        couponCode: null,
        discountAmount: 0,
      );
      rethrow; // Rethrow so the UI can catch it for SnackBars
    }
  }

  void removeCoupon() {
    state = state.copyWith(couponCode: null, discountAmount: 0);
  }

  Future<Order> placeOrder() async {
    if (state.selectedAddress == null) throw "Please select a shipping address";
    if (state.selectedPayment == null) throw "Please select a payment method";

    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            address: state.selectedAddress!,
            paymentMethod: state.selectedPayment!.id,
            couponCode: state.couponCode,
          );

      // Success! Clear cart locally.
      ref.read(cartControllerProvider.notifier).clearState();

      state = state.copyWith(isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
