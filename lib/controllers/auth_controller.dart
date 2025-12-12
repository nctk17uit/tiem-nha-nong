import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/services/storage.dart';
import 'package:mobile/repositories/auth_repository.dart';

class AuthController extends AsyncNotifier<User?> {
  // 1. Make keys PUBLIC so dioProvider can use AuthController.accessKey
  static const accessKey = 'accessToken';
  static const refreshKey = 'refreshToken';

  @override
  FutureOr<User?> build() async {
    final storage = ref.watch(storageProvider);

    // 1. Check if we have a token saved
    final token = await storage.read(key: accessKey);
    if (token == null) {
      return null; // No token = Guest
    }

    try {
      // 2. Token exists: Try to fetch profile
      // The Interceptor will handle 401s and Auto-Refresh transparently here.
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getUserProfile();
      return user;
    } catch (e) {
      // 3. IMPROVED ERROR HANDLING
      // If the error is a DioException, check if it's a network issue
      if (e is DioException) {
        // If it's a connection error (No Internet), DO NOT logout.
        // Throw the error so the UI shows a "Retry" button.
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          rethrow;
        }
      }

      // If it's a 401 (Refresh failed) or any other logic error,
      // then we force a logout to clean up.
      await logout();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(storageProvider);

      final data = await repo.login(email, password);

      // Use the public keys
      await storage.write(key: accessKey, value: data['accessToken']);
      await storage.write(key: refreshKey, value: data['refreshToken']);

      return User.fromJson(data['user']);
    });
  }

  Future<void> logout() async {
    final storage = ref.read(storageProvider);
    await storage.deleteAll();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
