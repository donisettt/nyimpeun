import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get initials {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }
}

extension DoubleExtension on double {
  String toCurrency({String locale = 'id_ID', String symbol = 'Rp'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  String toCompact() {
    if (abs() >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(1)}M';
    } else if (abs() >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}Jt';
    } else if (abs() >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}Rb';
    }
    return toStringAsFixed(0);
  }
}

extension IntExtension on int {
  String toCurrency({String locale = 'id_ID', String symbol = 'Rp'}) {
    return toDouble().toCurrency(locale: locale, symbol: symbol);
  }
}

extension DateTimeExtension on DateTime {
  String toDisplayDate() {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(this);
  }

  String toShortDate() {
    return DateFormat('dd MMM yyyy', 'id_ID').format(this);
  }

  String toTime() {
    return DateFormat('HH:mm').format(this);
  }

  String toRelative() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} menit lalu';
      }
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }
    return toShortDate();
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
