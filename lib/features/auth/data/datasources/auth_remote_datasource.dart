import 'dart:io';
import 'package:dio/dio.dart';
import 'package:nyimpeun/core/constants/supabase_constants.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';
import 'package:nyimpeun/core/network/api_interceptor.dart';
import 'package:nyimpeun/features/auth/data/models/auth_request.dart';
import 'package:nyimpeun/features/auth/data/models/auth_response.dart';
import 'package:nyimpeun/features/auth/data/models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<AuthResponse> signInWithPassword(SignInRequest request) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.authEndpoint}/token',
        queryParameters: {'grant_type': 'password'},
        data: request.toJson(),
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<SignUpResponse> signUp(SignUpRequest request) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.authEndpoint}/signup',
        data: request.toJson(),
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );
      return SignUpResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> signOut(String accessToken) async {
    try {
      await _dio.post(
        '${SupabaseConstants.authEndpoint}/logout',
        options: Options(headers: {
          'apikey': SupabaseConstants.anonKey,
          'Authorization': 'Bearer $accessToken',
        }),
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (_) {
      // Ignore signout errors
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '${SupabaseConstants.authEndpoint}/token',
        queryParameters: {'grant_type': 'refresh_token'},
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ─── Profile ───────────────────────────────────────────────────────────────

  Future<UserModel> getProfile(String userId) async {
    try {
      final response = await _dio.get(
        '${SupabaseConstants.restEndpoint}/profiles',
        queryParameters: {'id': 'eq.$userId', 'select': '*'},
        options: Options(headers: {'apikey': SupabaseConstants.anonKey}),
      );
      final list = response.data as List;
      if (list.isEmpty) throw const NotFoundException('Profil tidak ditemukan');
      return UserModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<UserModel> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '${SupabaseConstants.restEndpoint}/profiles',
        queryParameters: {'id': 'eq.$userId'},
        data: data,
        options: Options(headers: {
          'apikey': SupabaseConstants.anonKey,
          'Prefer': 'return=representation',
        }),
      );
      final list = response.data as List;
      if (list.isEmpty) throw const NotFoundException('Profil tidak ditemukan');
      return UserModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Update email via Supabase Auth API
  Future<void> updateAuthEmail(String accessToken, String newEmail) async {
    try {
      await _dio.put(
        '${SupabaseConstants.authEndpoint}/user',
        data: {'email': newEmail},
        options: Options(headers: {
          'apikey': SupabaseConstants.anonKey,
          'Authorization': 'Bearer $accessToken',
        }),
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Update password via Supabase Auth API (requires active session)
  Future<void> updateAuthPassword(String accessToken, String newPassword) async {
    try {
      await _dio.put(
        '${SupabaseConstants.authEndpoint}/user',
        data: {'password': newPassword},
        options: Options(headers: {
          'apikey': SupabaseConstants.anonKey,
          'Authorization': 'Bearer $accessToken',
        }),
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Upload avatar ke Supabase Storage, return public URL
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
    required String accessToken,
  }) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$fileName';

      await _dio.post(
        '${SupabaseConstants.url}/storage/v1/object/avatars/$storagePath',
        data: file.openRead(),
        options: Options(
          headers: {
            'apikey': SupabaseConstants.anonKey,
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'image/jpeg',
            'x-upsert': 'true',
          },
          contentType: 'image/jpeg',
        ),
      );

      return '${SupabaseConstants.url}/storage/v1/object/public/avatars/$storagePath';
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
