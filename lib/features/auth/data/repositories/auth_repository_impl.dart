import 'package:nyimpeun/core/errors/app_exception.dart';
import 'package:nyimpeun/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:nyimpeun/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nyimpeun/features/auth/data/models/auth_request.dart';
import 'package:nyimpeun/features/auth/domain/entities/user_entity.dart';
import 'package:nyimpeun/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDatasource,
    required AuthLocalDataSource localDatasource,
  })  : _remote = remoteDatasource,
        _local = localDatasource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _remote.signInWithPassword(
      SignInRequest(email: email, password: password),
    );

    await _local.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      userId: response.user.id,
    );
    await _local.cacheUserInfo(
      name: response.user.fullName,
      email: response.user.email,
    );

    // Fetch complete profile dari database
    try {
      final profile = await _remote.getProfile(response.user.id);
      await _local.cacheUserInfo(
        name: profile.fullName,
        email: profile.email,
      );
      return profile.toEntity();
    } catch (_) {
      return response.user.toEntity();
    }
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _remote.signUp(
      SignUpRequest(email: email, password: password, fullName: fullName),
    );

    // Jika Supabase langsung memberikan session (email confirm dimatikan)
    if (response.session != null) {
      await _local.saveTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
        userId: response.user.id,
      );
      await _local.cacheUserInfo(
        name: fullName,
        email: response.user.email,
      );
    } else {
      // Session null — coba auto sign-in langsung
      // (ini terjadi jika Supabase sudah disable email confirm tapi response
      // tidak mengembalikan session field)
      try {
        final signInResponse = await _remote.signInWithPassword(
          SignInRequest(email: email, password: password),
        );
        await _local.saveTokens(
          accessToken: signInResponse.accessToken,
          refreshToken: signInResponse.refreshToken,
          userId: signInResponse.user.id,
        );
        await _local.cacheUserInfo(
          name: fullName,
          email: signInResponse.user.email,
        );
        return signInResponse.user.toEntity();
      } catch (_) {
        // Auto sign-in gagal — kembalikan user saja (perlu konfirmasi email)
      }
    }

    return response.user.toEntity();
  }

  @override
  Future<void> signOut() async {
    final token = await _local.getAccessToken();
    if (token != null) {
      await _remote.signOut(token);
    }
    await _local.clearSessionFull();
  }

  @override
  Future<bool> hasSession() async {
    final token = await _local.getAccessToken();
    return token != null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userId = await _local.getUserId();
    if (userId == null) return null;

    try {
      final profile = await _remote.getProfile(userId);
      await _local.cacheUserInfo(
        name: profile.fullName,
        email: profile.email,
      );
      return profile.toEntity();
    } on AuthException {
      // Token mungkin kadaluarsa — coba refresh dulu
      try {
        await refreshSession();
        final profile = await _remote.getProfile(userId);
        await _local.cacheUserInfo(
          name: profile.fullName,
          email: profile.email,
        );
        return profile.toEntity();
      } catch (_) {
        await _local.clearSession();
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> refreshSession() async {
    final refreshToken = await _local.getRefreshToken();
    if (refreshToken == null) throw const AuthException();

    final response = await _remote.refreshToken(refreshToken);
    await _local.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      userId: response.user.id,
    );
  }

  // ─── Profile Management ────────────────────────────────────────────────────

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
  }) async {
    final userId = await _local.getUserId();
    if (userId == null) throw const AuthException('Tidak ada sesi aktif');

    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;

    final updated = await _remote.updateProfile(userId, data);

    if (fullName != null) {
      await _local.cacheUserInfo(name: fullName, email: _local.cachedUserEmail ?? '');
    }
    return updated.toEntity();
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    final token = await _local.getAccessToken();
    if (token == null) throw const AuthException('Tidak ada sesi aktif');
    await _remote.updateAuthEmail(token, newEmail);
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = await _local.getUserId();
    if (userId == null) throw const AuthException('Tidak ada sesi aktif');

    final cachedEmail = _local.cachedUserEmail;
    if (cachedEmail == null) throw const AuthException('Email tidak ditemukan');

    await _remote.signInWithPassword(
      SignInRequest(email: cachedEmail, password: currentPassword),
    );

    final token = await _local.getAccessToken();
    if (token == null) throw const AuthException('Token tidak ditemukan');
    await _remote.updateAuthPassword(token, newPassword);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    final token = await _local.getAccessToken();
    if (token == null) throw const AuthException('Tidak ada sesi aktif');
    return _remote.uploadAvatar(
      userId: userId,
      filePath: filePath,
      accessToken: token,
    );
  }

  @override
  Future<UserEntity> updateAvatar(String avatarUrl) async {
    final userId = await _local.getUserId();
    if (userId == null) throw const AuthException('Tidak ada sesi aktif');
    final updated = await _remote.updateProfile(userId, {'avatar_url': avatarUrl});
    return updated.toEntity();
  }
}
