import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      final String host = Uri.base.host;
      print('Detected host: $host'); // Debugging
      if (host == 'localhost' || 
          host == '127.0.0.1' || 
          host.startsWith('192.168.') || 
          host.startsWith('10.')) {
        return '${Uri.base.origin}/api';
      }
      // Production web or non-local environment
      return 'https://finans.onurtopaloglu.uk/api'; 
    }
    return 'https://finans.onurtopaloglu.uk/api';
  }
  
  static const String loginEndpoint = '/auth/login/';
  static const String registerEndpoint = '/auth/register/';
  static const String refreshEndpoint = '/auth/refresh/';
  static const String portfolioEndpoint = '/portfolio/';
  static const String assetsEndpoint = '/portfolio/assets/';
  static const String transactionsEndpoint = '/portfolio/transactions/';
  static const String financeEndpoint = '/finance/';
  static const String incomesEndpoint = '/finance/incomes/';
  static const String expensesEndpoint = '/finance/expenses/';
  static const String budgetsEndpoint = '/finance/budgets/';
  static const String toolsEndpoint = '/tools/';
  static const String notesEndpoint = '/tools/notes/';
  static const String marketEndpoint = '/market/';
  static const String pricesEndpoint = '/market/prices/';
  static const String tickerEndpoint = '/market/ticker/';
}
