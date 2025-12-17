import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/services/networking.dart';
import 'package:mobile/models/payment_method.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/models/order.dart';

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  // 1. Fetch Payment Methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _dio.get('/payment-methods');
      return (response.data['data'] as List)
          .map((e) => PaymentMethod.fromJson(e))
          .toList();
    } catch (e) {
      // Fallback for offline dev testing
      return [
        PaymentMethod(
          id: 'COD',
          name: 'Cash on Delivery',
          description: 'Pay when you receive',
          isEnabled: true,
        ),
        PaymentMethod(
          id: 'ONLINE',
          name: 'Online Payment',
          description: 'Pay via PayOS',
          isEnabled: true,
        ),
      ];
    }
  }

  // 2. Validate Coupon
  Future<Map<String, dynamic>> applyCoupon({
    required String code,
    required double cartTotal,
  }) async {
    try {
      final response = await _dio.post(
        '/cart/apply-coupon',
        data: {'coupon_code': code, 'cart_total': cartTotal},
      );
      return response.data;
      // Returns: { valid: true, discount_amount: 50000, message: "..." }
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Invalid coupon';
    }
  }

  // 3. Create Order
  Future<Order> createOrder({
    required ShippingAddress address,
    required String paymentMethod,
    String? couponCode,
  }) async {
    try {
      // API Call: POST /orders
      final response = await _dio.post(
        '/orders',
        data: {
          // MAPPING: Your Model -> Backend Keys
          'shipping_name': address.fullName,
          'shipping_phone': address.phoneNumber,

          // Use your helper getter for the full string
          'shipping_address': address.fullAddress,

          'province_code': address.provinceCode,
          'ward_code': address.wardCode,

          'payment_method': paymentMethod,
          'coupon_code': couponCode,
        },
      );

      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Order creation failed';
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});
