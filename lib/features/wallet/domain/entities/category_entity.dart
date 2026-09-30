import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type, // 'income' | 'expense'
    this.userId,
    this.icon,
    this.color,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime? createdAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  @override
  List<Object?> get props => [id, userId, name, type, icon, color, isDefault];
}
