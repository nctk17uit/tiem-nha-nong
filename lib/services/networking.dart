import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/services/storage.dart';
import 'package:mobile/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(storageProvider);

  final options = BaseOptions(
    baseUrl: dotenv.env['APP_URL']!,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  final dio = Dio(options);

  // We use QueuedInterceptorsWrapper to process requests sequentially during
  // the refresh phase.
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      // 1. ON REQUEST: Add Access Token
      onRequest: (options, handler) async {
        final token = await storage.read(key: AuthController.accessKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },

      // 2. ON ERROR: Handle 401 & Refresh
      onError: (DioException error, handler) async {
        // Check if it's a 401 AND we haven't already tried to refresh this specific request
        // (We add a custom tag '_retry' to avoid infinite loops)
        if (error.response?.statusCode == 401 &&
            error.requestOptions.extra['isRetry'] != true) {
          if (kDebugMode) {
            print(">>> 401 Detected. Attempting Refresh...");
          }

          try {
            // A. Get the Refresh Token
            final refreshToken = await storage.read(
              key: AuthController.refreshKey,
            );

            if (refreshToken == null) {
              // No refresh token available? We can't do anything.
              return handler.next(error);
            }

            // B. Call Refresh Endpoint
            // IMPORTANT: Create a NEW Dio instance to avoid circular interceptors
            // or reusing the locked instance.
            final refreshDio = Dio(BaseOptions(baseUrl: options.baseUrl));

            final refreshResponse = await refreshDio.post(
              '/auth/refresh-token',
              data: {'refreshToken': refreshToken},
            );

            // C. Save New Tokens
            final newAccessToken = refreshResponse.data['accessToken'];
            final newRefreshToken =
                refreshResponse.data['refreshToken']; // If your API rotates it

            await storage.write(
              key: AuthController.accessKey,
              value: newAccessToken,
            );
            // Only update refresh token if the server returned a new one
            if (newRefreshToken != null) {
              await storage.write(key: 'refreshToken', value: newRefreshToken);
            }

            if (kDebugMode) {
              print(">>> Token Refreshed Successfully.");
            }

            // D. Retry the Original Request
            // Copy the original options
            final retryOptions = error.requestOptions;

            // Update the header with the NEW token
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            // Mark as a retry to prevent infinite loops
            retryOptions.extra['isRetry'] = true;

            // Perform the request again using the main dio instance
            final response = await dio.fetch(retryOptions);

            // Resolve the original request with this new valid response
            return handler.resolve(response);
          } catch (refreshError) {
            // E. Refresh Failed? (Session completely expired)
            if (kDebugMode) {
              print(">>> Refresh Failed: $refreshError");
            }

            // Clear storage so the user is treated as Guest next time
            await storage.deleteAll();

            // Propagate the original error (or the refresh error) so the UI knows it failed
            return handler.next(error);
          }
        }

        // If not 401, just pass the error along
        return handler.next(error);
      },
    ),
  );

  return dio;
});
