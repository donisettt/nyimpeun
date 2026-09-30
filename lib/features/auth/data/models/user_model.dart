import 'package:nyimpeun/features/auth/domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.currency = 'IDR',
    this.hasPin = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String currency;
  final bool hasPin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      currency: json['currency'] as String? ?? 'IDR',
      hasPin: json['has_pin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Parse dari Supabase auth user (nested structure)
  factory UserModel.fromSupabaseUser(Map<String, dynamic> json) {
    final metadata = json['user_metadata'] as Map<String, dynamic>? ?? {};
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: metadata['full_name'] as String? ?? '',
      avatarUrl: metadata['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'currency': currency,
        'has_pin': hasPin,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        currency: currency,
        hasPin: hasPin,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
