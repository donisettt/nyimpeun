class AppConstants {
  AppConstants._();

  static const String appName = 'Nyimpeun';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyPinHash = 'pin_hash';
  static const String keyHasPin = 'has_pin';
  static const String keyPinAttempts = 'pin_attempts';
  static const String keyPinLockedUntil = 'pin_locked_until';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';

  // PIN config
  static const int pinLength = 6;
  static const int maxPinAttempts = 5;
  static const int pinLockDurationMinutes = 15;

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
}
