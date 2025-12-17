import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/services/networking.dart';

class AddressRepository {
  final Dio _dio;
  AddressRepository(this._dio);

  // GET /users/me/addresses
  Future<List<ShippingAddress>> getAddresses() async {
    try {
      final response = await _dio.get('/users/me/addresses');
      return (response.data as List) .map((e) => ShippingAddress.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load addresses';
    }
  }

  // POST /users/me/addresses
  Future<ShippingAddress> createAddress(ShippingAddress address) async {
    try {
      final response = await _dio.post(
        '/users/me/addresses',
        data: address.toJson(),
      );
      // Create returns the new object with ID
      return ShippingAddress.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to add address';
    }
  }

  // PUT /users/me/addresses/:id
  Future<void> updateAddress(String id, ShippingAddress address) async {
    try {
      await _dio.put('/users/me/addresses/$id', data: address.toJson());
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update address';
    }
  }

  // DELETE /users/me/addresses/:id
  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete('/users/me/addresses/$id');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete address';
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(dioProvider));
});
