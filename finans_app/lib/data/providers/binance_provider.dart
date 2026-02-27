import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/data/services/binance_service.dart';

class BinanceProvider extends ChangeNotifier {
  final BinanceService _binanceService = BinanceService();
  
  String? _apiKey;
  String? _apiSecret;
  double? _totalUsdtBalance;
  bool _isLoading = false;
  String? _error;

  String? get apiKey => _apiKey;
  String? get apiSecret => _apiSecret;
  double? get totalUsdtBalance => _totalUsdtBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _apiKey != null && _apiSecret != null;

  BinanceProvider() {
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('binance_api_key');
    _apiSecret = prefs.getString('binance_api_secret');
    notifyListeners();

    if (isConnected) {
      fetchBalance();
    }
  }

  Future<void> saveKeys(String key, String secret) async {
    final trimmedKey = key.trim();
    final trimmedSecret = secret.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('binance_api_key', trimmedKey);
    await prefs.setString('binance_api_secret', trimmedSecret);
    _apiKey = trimmedKey;
    _apiSecret = trimmedSecret;
    notifyListeners();
    fetchBalance();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('binance_api_key');
    await prefs.remove('binance_api_secret');
    _apiKey = null;
    _apiSecret = null;
    _totalUsdtBalance = null;
    notifyListeners();
  }

  Future<void> fetchBalance() async {
    if (!isConnected) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final balance = await _binanceService.getTotalUsdtBalance(_apiKey!, _apiSecret!);
      _totalUsdtBalance = balance;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
