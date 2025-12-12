import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/networking.dart';

class ProductRepository {
  final Dio _dio;
  ProductRepository(this._dio);

  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    String? brandId,
    String? sortBy, // price_asc, price_desc, newest, rating_desc
    double? priceMin,
    double? priceMax,
    bool? inStock,
    int page = 1,
    int limit = 10,
  }) async {
    // 1. Build Query Parameters
    final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (brandId != null) queryParams['brand_id'] = brandId;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (priceMin != null) queryParams['price_min'] = priceMin;
    if (priceMax != null) queryParams['price_max'] = priceMax;
    if (inStock == true) queryParams['in_stock'] = true;

    try {
      // 2. Call API
      final response = await _dio.get(
        '/products',
        queryParameters: queryParams,
      );

      // 3. Parse Response
      // Structure: { "data": [...], "pagination": {...} }
      final List<dynamic> list = response.data['data'] ?? [];

      return list.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }

  // Add this method inside ProductRepository class
  Future<Product> getProductDetail(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});
