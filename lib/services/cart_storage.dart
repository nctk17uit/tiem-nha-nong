import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/cart.dart';
import 'storage.dart';

class CartStorageService {
  final FlutterSecureStorage _storage;
  static const _key = 'guest_cart';

  CartStorageService(this._storage);

  Future<List<CartItem>> loadCart() async {
    final jsonStr = await _storage.read(key: _key);
    if (jsonStr == null) return [];

    try {
      final List list = jsonDecode(jsonStr);
      return list.map((e) => CartItem.fromLocalJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCart(List<CartItem> items) async {
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.write(key: _key, value: jsonStr);
  }

  Future<void> clearCart() async {
    await _storage.delete(key: _key);
  }
}

final cartStorageProvider = Provider<CartStorageService>((ref) {
  return CartStorageService(ref.watch(storageProvider));
});
