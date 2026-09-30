import 'package:dio/dio.dart';
import 'package:nyimpeun/core/constants/app_constants.dart';
import 'package:nyimpeun/core/constants/supabase_constants.dart';
import 'package:nyimpeun/core/storage/secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureStorage secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  final Dio _dio;
  final SecureStorage _secureStorage;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Always add API key
    options.headers['apikey'] = SupabaseConstants.anonKey;

    // Add auth token if available
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final authResponse =
            await Supabase.instance.client.auth.refreshSession();
        final newToken = authResponse.session?.accessToken;

        if (newToken != null) {
          await _secureStorage.saveAccessToken(newToken);
          if (authResponse.session?.refreshToken != null) {
            await _secureStorage
                .saveRefreshToken(authResponse.session!.refreshToken!);
          }

          // Retry original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh failed – clear session
        await _secureStorage.clearSession();
      } finally {
        _isRefreshing = false;
      }
    }

    super.onError(err, handler);
  }
}

class DioClient {
  DioClient._();

  static Dio create({required SecureStorage secureStorage}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout:
            const Duration(seconds: AppConstants.connectTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: AppConstants.receiveTimeoutSeconds),
        listFormat: ListFormat.multiCompatible, // Required for PostgREST to parse lists like date=gte...&date=lte...
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Prefer': 'return=representation',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(dio: dio, secureStorage: secureStorage),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    ]);

    return dio;
  }
}

// ignore: avoid_print
void debugPrint(String message) {}
