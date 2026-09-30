import 'package:equatable/equatable.dart';

enum WalletType {
  cash('cash', 'Tunai'),
  bank('bank', 'Bank'),
  eWallet('e-wallet', 'E-Wallet');

  const WalletType(this.value, this.label);
  final String value;
  final String label;

  static WalletType fromString(String value) {
    return WalletType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WalletType.cash,
    );
  }
}

class WalletEntity extends Equatable {
  const WalletEntity({
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
  final WalletType type;
  final int balance; // dalam satuan terkecil (sen/rupiah)
  final String currency;
  final String? color;
  final String? icon;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletEntity copyWith({
    String? id,
    String? userId,
    String? name,
    WalletType? type,
    int? balance,
    String? currency,
    String? color,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        balance,
        currency,
        color,
        icon,
        isDefault,
        createdAt,
        updatedAt,
      ];
}
