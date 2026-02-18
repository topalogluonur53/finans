import 'package:intl/intl.dart';

class Formatters {
  static final _currencyUSD = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
  static final _currencyTRY = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  static final _numberFormat = NumberFormat.decimalPattern('tr_TR')..minimumFractionDigits = 2..maximumFractionDigits = 2;

  static String formatMoney(double amount, {String currency = 'TRY'}) {
    if (currency == 'USD') return _currencyUSD.format(amount);
    if (currency == 'NONE') return _numberFormat.format(amount);
    return _currencyTRY.format(amount);
  }

  static String formatNumber(double value) {
    return _numberFormat.format(value);
  }

  static final _percentFormat = NumberFormat.decimalPattern('tr_TR')..minimumFractionDigits = 2..maximumFractionDigits = 2;

  static String formatPercent(double value) {
    final formatted = _percentFormat.format(value.abs());
    if (value >= 0) {
      return '+$formatted%';
    } else {
      return '-$formatted%';
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
