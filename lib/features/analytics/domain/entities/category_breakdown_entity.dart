class CategoryBreakdownEntity {
  const CategoryBreakdownEntity({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
    this.categoryIcon,
    this.categoryColor,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final int totalAmount;
  final double percentage; // 0.0 - 1.0
  final int transactionCount;
}
