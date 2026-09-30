import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compact(
    locale: 'id_ID',
  );

  static String currency(double amount) => _currencyFormatter.format(amount);

  static String compact(double amount) => _compactFormatter.format(amount);

  static String compactCurrency(double amount) => 'Rp ${_compactFormatter.format(amount)}';

  static String date(DateTime dt, {String pattern = 'dd MMMM yyyy'}) {
    return DateFormat(pattern, 'id_ID').format(dt);
  }

  static String time(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  static String monthYear(DateTime dt) {
    return DateFormat('MMMM yyyy', 'id_ID').format(dt);
  }

  /// Format angka saat user mengetik (e.g., 1000000 → 1.000.000)
  static String inputCurrency(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';
    final number = int.tryParse(cleaned) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(number);
  }
}
