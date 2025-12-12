import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/networking.dart';

class CategoryRepository {
  final Dio _dio;
  CategoryRepository(this._dio);

  Future<List<Category>> getCategories({
    String? search,
    String view = 'tree',
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'view': view};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Ensure this matches your API endpoint exactly
      final response = await _dio.get(
        '/categories',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw e;
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});
