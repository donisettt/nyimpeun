import 'package:nyimpeun/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Login dengan email dan password
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registrasi akun baru
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Logout
  Future<void> signOut();

  /// Ambil user yang sedang login
  Future<UserEntity?> getCurrentUser();

  /// Cek apakah sesi aktif
  Future<bool> hasSession();

  /// Refresh session token
  Future<void> refreshSession();

  // ─── Profile Management ────────────────────────────────────────────────────

  /// Update data profil (nama, nomor HP, mata uang)
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
  });

  /// Update email (Supabase akan kirim konfirmasi ke email baru)
  Future<void> updateEmail(String newEmail);

  /// Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Upload avatar ke Supabase Storage, return URL publik
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  });

  /// Simpan avatarUrl ke profil
  Future<UserEntity> updateAvatar(String avatarUrl);
}
