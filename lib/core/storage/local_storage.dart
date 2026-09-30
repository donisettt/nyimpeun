import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyimpeun/core/constants/app_constants.dart';

class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  // ─── Onboarding ───────────────────────────────────────────────────────────
  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(AppConstants.keyHasSeenOnboarding, value);
  }

  bool get hasSeenOnboarding =>
      _prefs.getBool(AppConstants.keyHasSeenOnboarding) ?? false;

  bool get isFirstLaunch =>
      _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;

  Future<void> setFirstLaunchDone() async {
    await _prefs.setBool(AppConstants.keyIsFirstLaunch, false);
  }

  // ─── User Cache (non-sensitive) ───────────────────────────────────────────
  Future<void> saveUserName(String name) async {
    await _prefs.setString(AppConstants.keyUserName, name);
  }

  String? get userName => _prefs.getString(AppConstants.keyUserName);

  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(AppConstants.keyUserEmail, email);
  }

  String? get userEmail => _prefs.getString(AppConstants.keyUserEmail);

  // ─── PIN Flag (non-sensitive, actual hash in SecureStorage) ───────────────
  Future<void> setHasPin(bool value) async {
    await _prefs.setBool(AppConstants.keyHasPin, value);
  }

  bool get hasPin => _prefs.getBool(AppConstants.keyHasPin) ?? false;

  // ─── Clear ────────────────────────────────────────────────────────────────
  /// Hapus data user non-PIN: dipanggil saat sesi kadaluarsa. hasPin dipertahankan.
  Future<void> clearUserData() async {
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyUserEmail);
    // TIDAK hapus keyHasPin agar PIN login tetap tersedia
  }

  /// Hapus semua data user termasuk hasPin: dipanggil saat user benar-benar logout.
  Future<void> clearAllUserData() async {
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyHasPin);
  }
}
