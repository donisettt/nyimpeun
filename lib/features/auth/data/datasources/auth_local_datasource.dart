import 'package:nyimpeun/core/storage/local_storage.dart';
import 'package:nyimpeun/core/storage/secure_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({
    required SecureStorage secureStorage,
    required LocalStorage localStorage,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage;

  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  // ─── Token Management ─────────────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _secureStorage.saveAccessToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
    await _secureStorage.saveUserId(userId);
  }

  Future<String?> getAccessToken() => _secureStorage.getAccessToken();
  Future<String?> getRefreshToken() => _secureStorage.getRefreshToken();
  Future<String?> getUserId() => _secureStorage.getUserId();

  /// Hapus hanya tokens — dipanggil saat token kadaluarsa
  Future<void> clearSession() async {
    await _secureStorage.clearSession();
  }

  /// Logout penuh — hapus semua tokens dan data user
  Future<void> clearSessionFull() async {
    await _secureStorage.clearSessionFull();
    await _localStorage.clearUserData();
  }

  // ─── User Cache ───────────────────────────────────────────────────────────
  Future<void> cacheUserInfo({
    required String name,
    required String email,
  }) async {
    await _localStorage.saveUserName(name);
    await _localStorage.saveUserEmail(email);
  }

  String? get cachedUserName => _localStorage.userName;
  String? get cachedUserEmail => _localStorage.userEmail;
}
