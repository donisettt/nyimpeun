import 'package:nyimpeun/features/wallet/domain/entities/transaction_entity.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.date,
    this.walletId,
    this.walletName,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? walletId;
  final String? walletName;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String type;
  final int amount;
  final String? note;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Support joined data from Supabase (wallets and categories tables joined)
    final wallet = json['wallets'] as Map<String, dynamic>?;
    final category = json['categories'] as Map<String, dynamic>?;

    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String?,
      walletName: wallet?['name'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String).toLocal(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'wallet_id': walletId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'note': note,
        // Convert to UTC before converting to ISO 8601 so Supabase stores the exact correct moment
        // instead of interpreting the local time string without offset as UTC.
        'date': date.toUtc().toIso8601String(),
      };

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        userId: userId,
        walletId: walletId,
        walletName: walletName,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
        type: TransactionType.fromString(type),
        amount: amount,
        note: note,
        date: date,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static TransactionModel fromEntity(TransactionEntity entity) =>
      TransactionModel(
        id: entity.id,
        userId: entity.userId,
        walletId: entity.walletId,
        categoryId: entity.categoryId,
        type: entity.type.value,
        amount: entity.amount,
        note: entity.note,
        date: entity.date,
      );
}
