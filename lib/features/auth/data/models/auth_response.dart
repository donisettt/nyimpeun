import 'package:nyimpeun/features/auth/data/models/user_model.dart';

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final int? expiresIn;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: json['expires_in'] as int?,
      user: userJson != null
          ? UserModel.fromSupabaseUser(userJson)
          : UserModel.fromSupabaseUser({}),
    );
  }
}

/// Response khusus signup — Supabase mengembalikan user tapi session bisa null
/// jika email confirmation diaktifkan
class SignUpResponse {
  const SignUpResponse({
    required this.user,
    this.session,
    this.requiresEmailConfirmation = false,
  });

  final UserModel user;
  final AuthResponse? session;
  final bool requiresEmailConfirmation;

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final sessionJson = json['session'] as Map<String, dynamic>?;

    final user = userJson != null
        ? UserModel.fromSupabaseUser(userJson)
        : UserModel.fromSupabaseUser({'id': '', 'email': ''});

    AuthResponse? session;
    if (sessionJson != null) {
      session = AuthResponse.fromJson({
        ...sessionJson,
        'user': userJson,
      });
    }

    return SignUpResponse(
      user: user,
      session: session,
      requiresEmailConfirmation: session == null,
    );
  }
}
