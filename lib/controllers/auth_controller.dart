import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/services/storage.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/controllers/cart_controller.dart';
import 'package:flutter/foundation.dart';

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
      final repo = ref.read(authRepositoryProvider);

      // If server is down, fail fast after 5 seconds instead of hanging.
      final user = await repo.getUserProfile().timeout(
        const Duration(seconds: 5),
      );

      return user;
    } catch (e) {
      // 3. IMPROVED ERROR HANDLING
      if (e is DioException || e is TimeoutException) {
        if (kDebugMode) {
          print("Auth Check Failed (Offline/Timeout): $e");
        }
        return null;
      }

      // If it's a 401 (Refresh failed) or logic error, force logout.
      await logout();
      return null;
    }
  }

  // --- LOGIN ---
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);

      // 1. API Login
      final data = await repo.login(email, password);

      // 2. Handle Success (Save Token + Merge Cart)
      return _handleAuthSuccess(data);
    });
  }

  // --- REGISTER ---
  Future<bool> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(name, email, password);

      // Success: Still a guest (User is null), but loading is done.
      state = const AsyncValue.data(null);
      return true; // Signal UI to navigate to Verify Screen
    } catch (e, st) {
      // Error: Update state so UI shows Snackbar
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> verifyCode(String email, String code) async {
    state = const AsyncValue.loading();

    // We manually try/catch instead of using guard so we can 'rethrow'
    try {
      final repo = ref.read(authRepositoryProvider);

      // 1. API Verify
      final data = await repo.verifyCode(email, code);

      // 2. Handle Success (Save Token + Merge Cart)
      await _handleAuthSuccess(data);

      // 3. Update State explicitly
      state = AsyncValue.data(User.fromJson(data['user']));
    } catch (e, st) {
      // 4. Update State to error AND Rethrow so UI knows it failed
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      // 1. Call API
      await repo.forgotPassword(email);

      // 2. Success: Stop loading, keep user as null (Guest)
      state = const AsyncValue.data(null);
      return true; // Signal UI to navigate
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Verifies code and sets the new password.
  /// Logs the user in immediately upon success.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);

      // 1. Call API
      final data = await repo.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      // 2. Handle Success (Save Tokens + Merge Cart)
      final user = await _handleAuthSuccess(data);

      // 3. Update State (Logs user in)
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Signal UI to show error snackbar
    }
  }

  // --- HELPER: Shared Logic for Login & Verify ---
  Future<User> _handleAuthSuccess(Map<String, dynamic> data) async {
    final storage = ref.read(storageProvider);

    // 1. Save Tokens
    await storage.write(key: accessKey, value: data['accessToken']);
    await storage.write(key: refreshKey, value: data['refreshToken']);

    // 2. Trigger Cart Merge
    // We await this so the user doesn't see an empty cart on the next screen
    final cartController = ref.read(cartControllerProvider.notifier);

    await cartController.mergeLocalCartToServer().then((notifications) {
      if (notifications.isNotEmpty) {
        if (kDebugMode) {
          print("Merge Notifications: ${notifications.length}");
        }
      }
    });

    return User.fromJson(data['user']);
  }

  Future<void> logout() async {
    final storage = ref.read(storageProvider);
    await storage.deleteAll();
    state = const AsyncValue.data(null);

    // Clear cart state on logout so next user doesn't see old items
    ref.read(cartControllerProvider.notifier).clearState();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
