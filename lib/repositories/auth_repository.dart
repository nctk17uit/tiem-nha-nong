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

  // Endpoint to get user profile if you restart the app
  Future<User> getUserProfile() async {
    final response = await _dio.get('/auth/me'); // Adjust path to your API
    // Your backend likely returns just the user object here, or { user: ... }
    // Adjust based on your actual /me response.
    return User.fromJson(response.data);
  }

  Future<void> register(String name, String email, String password) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw 'Email này đã được sử dụng.';
      }
      final message = e.response?.data['message'] ?? 'Registration failed';
      throw message;
    }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-code',
        data: {'email': email, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw 'Mã xác thực không đúng hoặc đã hết hạn.';
      }
      final message = e.response?.data['message'] ?? 'Verification failed';
      throw message;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      // Handle standard errors
      final message = e.response?.data['message'] ?? 'Request failed';
      throw message;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'new_password': newPassword},
      );

      // Returns 200 Success with { accessToken, refreshToken, user }
      // This allows us to log the user in immediately.
      return response.data;
    } on DioException catch (e) {
      // 400: Invalid or expired code
      if (e.response?.statusCode == 400) {
        throw 'Mã xác thực không đúng hoặc đã hết hạn.';
      }

      final message = e.response?.data['message'] ?? 'Reset password failed';
      throw message;
    }
  }

  Future<User> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/me',
        data: {'name': name, 'phone_number': phone},
      );
      // Backend should return the updated user object
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Cập nhật thất bại';
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        '/auth/change-password',
        data: {'old_password': currentPassword, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Đổi mật khẩu thất bại';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
