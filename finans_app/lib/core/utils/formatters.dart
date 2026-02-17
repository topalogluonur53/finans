import 'package:intl/intl.dart';

class Formatters {
  static final _currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _currencyTRY = NumberFormat.currency(symbol: '₺', decimalDigits: 2);

  static String formatMoney(double amount, {String currency = 'TRY'}) {
    if (currency == 'USD') return _currencyUSD.format(amount);
    return _currencyTRY.format(amount);
  }

  static String formatPercent(double value) {
    if (value >= 0) {
      return '+${value.toStringAsFixed(2)}%';
    } else {
      return '${value.toStringAsFixed(2)}%';
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
