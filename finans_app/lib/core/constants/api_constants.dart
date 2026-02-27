import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      final String host = Uri.base.host;
      debugPrint('Detected host: "$host"'); // Debugging
      final String origin = Uri.base.origin;

      if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
        // Local geliştirme: finans_backend port 8001'de çalışıyor
        return 'http://127.0.0.1:8001/api';
      }

      // Production: Sitenin kendi adresi üzerinden proxy kullan (SSL uyumlu)
      return '$origin/api';
    }
    // Mobil veya diğer fallback
    return 'https://finans.onurtopaloglu.uk/api';
  }

  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String refreshEndpoint = '/auth/refresh/';
  static const String changePasswordEndpoint = '/auth/change-password/';
  static const String portfolioEndpoint = '/portfolio/';
  static const String assetsEndpoint = '/portfolio/assets/';
  static const String transactionsEndpoint = '/portfolio/transactions/';
  static const String financeEndpoint = '/finance/';
  static const String incomesEndpoint = '/finance/incomes/';
  static const String expensesEndpoint = '/finance/expenses/';
  static const String budgetsEndpoint = '/finance/budgets/';
  static const String recurringEndpoint = '/finance/recurring/';
  static const String toolsEndpoint = '/tools/';
  static const String notesEndpoint = '/tools/notes/';
  static const String marketEndpoint = '/market/';
  static const String categorizedMarketEndpoint = '/market/categorized/';
  static const String tickerEndpoint = '/market/ticker/';
  static const String alarmsEndpoint = '/market/alarms/';
}
