import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../services/networking.dart';

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  // 1. Fetch Server Cart
  Future<List<CartItem>> getCart() async {
    final response = await _dio.get('/cart');
    final List list = response.data['cart'] ?? [];
    return list.map((e) => CartItem.fromJson(e)).toList();
  }

  // 2. Add Item (Logged In)
  Future<void> addToCart(String variantId, int quantity) async {
    await _dio.post(
      '/cart/items',
      data: {'variant_id': variantId, 'quantity': quantity},
    );
  }

  // 3. Update Quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _dio.put('/cart/items/$cartItemId', data: {'quantity': quantity});
  }

  // 4. Remove Item
  Future<void> removeItem(String cartItemId) async {
    await _dio.delete('/cart/items/$cartItemId');
  }

  // 5. MERGE
  Future<List<CartMergeNotification>> mergeCart(
    List<CartItem> localItems,
  ) async {
    // Convert local items to the format API expects: [{variant_id, quantity}]
    final payload = localItems
        .map((e) => {'variant_id': e.variantId, 'quantity': e.quantity})
        .toList();

    final response = await _dio.post('/cart/merge', data: {'items': payload});

    // Parse notifications
    final notifs = (response.data['notifications'] as List? ?? [])
        .map((e) => CartMergeNotification.fromJson(e))
        .toList();

    return notifs;
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});
