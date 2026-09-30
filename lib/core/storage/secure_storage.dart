import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nyimpeun/core/constants/app_constants.dart';
import 'package:nyimpeun/core/errors/app_exception.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  // ─── Access Token ─────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: AppConstants.keyAccessToken, value: token);
    } catch (e) {
      throw const StorageException('Gagal menyimpan token');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.keyAccessToken);
    } catch (e) {
      return null;
    }
  }

  // ─── Refresh Token ────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.keyRefreshToken, value: token);
    } catch (e) {
      throw const StorageException('Gagal menyimpan refresh token');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.keyRefreshToken);
    } catch (e) {
      return null;
    }
  }

  // ─── User ID ──────────────────────────────────────────────────────────────
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: AppConstants.keyUserId, value: userId);
    } catch (e) {
      throw const StorageException('Gagal menyimpan user ID');
    }
  }

  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: AppConstants.keyUserId);
    } catch (e) {
      return null;
    }
  }

  // ─── PIN ──────────────────────────────────────────────────────────────────
  Future<void> savePinHash(String pinHash) async {
    try {
      await _storage.write(key: AppConstants.keyPinHash, value: pinHash);
    } catch (e) {
      throw const StorageException('Gagal menyimpan PIN');
    }
  }

  Future<String?> getPinHash() async {
    try {
      return await _storage.read(key: AppConstants.keyPinHash);
    } catch (e) {
      return null;
    }
  }

  Future<void> deletePinHash() async {
    try {
      await _storage.delete(key: AppConstants.keyPinHash);
    } catch (_) {}
  }

  // ─── PIN Attempts ─────────────────────────────────────────────────────────
  Future<void> savePinAttempts(int attempts) async {
    await _storage.write(
      key: AppConstants.keyPinAttempts,
      value: attempts.toString(),
    );
  }

  Future<int> getPinAttempts() async {
    final value = await _storage.read(key: AppConstants.keyPinAttempts);
    return int.tryParse(value ?? '0') ?? 0;
  }

  Future<void> savePinLockedUntil(DateTime lockedUntil) async {
    await _storage.write(
      key: AppConstants.keyPinLockedUntil,
      value: lockedUntil.toIso8601String(),
    );
  }

  Future<DateTime?> getPinLockedUntil() async {
    final value = await _storage.read(key: AppConstants.keyPinLockedUntil);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  // ─── Clear ────────────────────────────────────────────────────────────────
  /// Hanya menghapus tokens (access + refresh). UserId, PIN hash, dan data
  /// lain tetap dipertahankan agar PIN login tetap bisa digunakan.
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: AppConstants.keyAccessToken);
      await _storage.delete(key: AppConstants.keyRefreshToken);
    } catch (e) {
      throw const StorageException('Gagal menghapus sesi');
    }
  }

  /// Menghapus semua token (access + refresh). userId & PIN tetap.
  /// Dipanggil saat user logout — PIN login masih bisa ditampilkan kembali.
  Future<void> clearSessionFull() async {
    try {
      await _storage.delete(key: AppConstants.keyAccessToken);
      await _storage.delete(key: AppConstants.keyRefreshToken);
      // userId, PIN hash, PIN attempts TIDAK dihapus
    } catch (e) {
      throw const StorageException('Gagal menghapus sesi');
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw const StorageException('Gagal menghapus semua data');
    }
  }
}
