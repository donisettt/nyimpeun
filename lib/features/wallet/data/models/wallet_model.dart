import 'package:nyimpeun/features/wallet/domain/entities/wallet_entity.dart';

class WalletModel {
  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'IDR',
    this.color,
    this.icon,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String type;
  final int balance;
  final String currency;
  final String? color;
  final String? icon;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'cash',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type,
        'balance': balance,
        'currency': currency,
        'color': color,
        'icon': icon,
        'is_default': isDefault,
      };

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'type': type,
        'balance': balance,
        'currency': currency,
        'color': color,
        'icon': icon,
        'is_default': isDefault,
      };

  WalletEntity toEntity() => WalletEntity(
        id: id,
        userId: userId,
        name: name,
        type: WalletType.fromString(type),
        balance: balance,
        currency: currency,
        color: color,
        icon: icon,
        isDefault: isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static WalletModel fromEntity(WalletEntity entity) => WalletModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        type: entity.type.value,
        balance: entity.balance,
        currency: entity.currency,
        color: entity.color,
        icon: entity.icon,
        isDefault: entity.isDefault,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
