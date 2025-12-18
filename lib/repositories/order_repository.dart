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

      final rawData = (response.data is Map && response.data['data'] != null)
          ? response.data['data']
          : response.data;

      if (rawData is! List) {
        throw 'Unexpected response format: expected List';
      }

      return rawData.map((e) => PaymentMethod.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ??
          'Không thể tải phương thức thanh toán';
    } catch (e) {
      throw 'Data parsing error: $e';
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
      final response = await _dio.post(
        '/orders',
        data: {
          'shipping_name': address.fullName,
          'shipping_phone': address.phoneNumber,
          'shipping_address': address.fullAddress,
          'province_code': address.provinceCode,
          'ward_code': address.wardCode,
          'payment_method': paymentMethod,
          'coupon_code': couponCode,
        },
      );

      // 1. Get the data map (Handle wrapper if exists)
      final Map<String, dynamic> responseData =
          (response.data is Map && response.data['data'] != null)
          ? Map<String, dynamic>.from(
              response.data['data'],
            ) // Create a modifiable copy
          : Map<String, dynamic>.from(response.data);

      // 2. PATCH: Inject the missing 'payment_method' that we already know
      if (responseData['payment_method'] == null) {
        responseData['payment_method'] = paymentMethod;
      }

      // 3. Parse
      return Order.fromJson(responseData);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Order creation failed';
    }
  }

  // 4. Get Order History
  Future<List<Order>> getMyOrders() async {
    try {
      final response = await _dio.get('/orders');
      return (response.data as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      throw 'Failed to load orders';
    }
  }

  // 5. Get Order Details
  Future<Order> getOrderDetails(String idOrNumber) async {
    try {
      final response = await _dio.get('/orders/$idOrNumber');
      return Order.fromJson(response.data);
    } catch (e) {
      throw 'Failed to load order details';
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});
