import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/location.dart';
import 'package:mobile/services/networking.dart';

class LocationRepository {
  final Dio _dio;
  LocationRepository(this._dio);

  // GET /master-data/provinces
  Future<List<Province>> getProvinces() async {
    try {
      final response = await _dio.get('/master-data/provinces');
      return (response.data as List).map((e) => Province.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load provinces';
    }
  }

  // GET /master-data/provinces/:code/wards
  Future<List<Ward>> getWards(int provinceCode) async {
    try {
      final response = await _dio.get(
        '/master-data/provinces/$provinceCode/wards',
      );
      return (response.data as List).map((e) => Ward.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load wards';
    }
  }
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(dioProvider));
});
