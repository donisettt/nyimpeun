import 'package:intl/intl.dart';

class MonthlySummaryEntity {
  const MonthlySummaryEntity({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  final int year;
  final int month;
  final int income;
  final int expense;

  int get net => income - expense;
  bool get isSurplus => net >= 0;

  String get monthLabel {
    final dt = DateTime(year, month);
    return DateFormat('MMM', 'id_ID').format(dt);
  }

  String get monthYearLabel {
    final dt = DateTime(year, month);
    return DateFormat('MMMM yyyy', 'id_ID').format(dt);
  }

  double get savingsRate {
    if (income == 0) return 0;
    return ((income - expense) / income).clamp(0.0, 1.0);
  }
}
