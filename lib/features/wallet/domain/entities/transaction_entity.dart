import 'package:equatable/equatable.dart';

enum TransactionType {
  income('income'),
  expense('expense'),
  transfer('transfer');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

class TransactionEntity extends Equatable {
  const TransactionEntity({
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
  final TransactionType type;
  final int amount; // dalam rupiah (integer)
  final String? note;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        categoryId,
        type,
        amount,
        note,
        date,
        createdAt,
        updatedAt,
      ];
}
