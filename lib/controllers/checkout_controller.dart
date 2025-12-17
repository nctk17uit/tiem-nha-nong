import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/models/payment_method.dart';
import 'package:mobile/models/order.dart';
import 'package:mobile/repositories/order_repository.dart';
import 'package:mobile/controllers/cart_controller.dart';

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
    PaymentMethod? selectedPayment,
    List<PaymentMethod>? availableMethods,
    String? couponCode,
    double? discountAmount,
    bool? isLoading,
    String? error,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
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
    // Load payment methods when controller initializes
    Future(() => _loadPaymentMethods());
    return CheckoutState();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await ref
          .read(orderRepositoryProvider)
          .getPaymentMethods();
      // Select the first enabled method by default to avoid null errors
      final defaultMethod = methods.firstWhere(
        (m) => m.isEnabled,
        orElse: () => methods.first,
      );

      state = state.copyWith(
        availableMethods: methods,
        selectedPayment: defaultMethod,
      );
    } catch (e) {
      // Handle error (optional: set error state)
    }
  }

  // Set Address (called when user selects from Address List)
  void setAddress(ShippingAddress address) {
    state = state.copyWith(selectedAddress: address);
  }

  // Set Payment Method (called when user taps Radio Button)
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPayment: method);
  }

  // Apply Coupon
  Future<void> applyCoupon(String code) async {
    state = state.copyWith(isLoading: true, error: null);

    // Get total from Cart Controller
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        couponCode: null,
        discountAmount: 0,
      );
      rethrow; // To show Snackbar in UI
    }
  }

  void removeCoupon() {
    state = state.copyWith(couponCode: null, discountAmount: 0);
  }

  // Place Order Action
  Future<Order> placeOrder() async {
    if (state.selectedAddress == null) throw "Vui lòng chọn địa chỉ giao hàng";
    if (state.selectedPayment == null) throw "Vui lòng chọn phương thức thanh toán";

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call Repository
      final order = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            address: state.selectedAddress!,
            paymentMethod: state.selectedPayment!.id,
            couponCode: state.couponCode,
          );

      // Success: Clear Cart & Reset State
      ref.read(cartControllerProvider.notifier).clearState();

      // Note: We don't reset CheckoutState immediately here so UI can read the result
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
