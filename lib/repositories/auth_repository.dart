import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/services/networking.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 1. REAL API CALL
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // 2. Return the JSON map directly.
      // Expected: { accessToken: "...", refreshToken: "...", user: { ... } }
      return response.data;
    } on DioException catch (e) {
      // Handle server errors (e.g., 401 Unauthorized)
      final message = e.response?.data['message'] ?? 'Login failed';
      throw message;
    }
  }

  // Optional: Endpoint to get user profile if you restart the app
  Future<User> getUserProfile() async {
    final response = await _dio.get('/auth/me'); // Adjust path to your API
    // Your backend likely returns just the user object here, or { user: ... }
    // Adjust based on your actual /me response.
    return User.fromJson(response.data);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
