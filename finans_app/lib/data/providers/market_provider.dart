import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/services/coingecko_service.dart';

class MarketData {
  final String symbol;
  final double price;
  final double changePercent;
  final String category;

  MarketData({
    required this.symbol, 
    required this.price, 
    required this.changePercent, 
    required this.category
  });

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      symbol: json['symbol'],
      price: double.parse(json['price'].toString()),
      changePercent: double.parse(json['change_percent_24h']?.toString() ?? '0'),
      category: json['category'] ?? 'crypto',
    );
  }
}

class MarketProvider extends ChangeNotifier {
  List<MarketData> _prices = [];
  bool _isLoading = false;
  Timer? _timer;
  double _usdTryRate = 32.50; // Default fallback

  List<MarketData> get prices => _prices;
  bool get isLoading => _isLoading;
  double get usdTryRate => _usdTryRate;

  void startPolling() {
    _fetchPrices();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchPrices();
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  final CoinGeckoService _service = CoinGeckoService();

  Future<void> _fetchPrices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _service.fetchAllMarkets();
      List<MarketData> allPrices = [];
      
      data.forEach((category, prices) {
        for (var p in prices) {
          allPrices.add(MarketData(
            symbol: p.symbol,
            price: p.currentPrice,
            changePercent: p.priceChangePercentage24h,
            category: category,
          ));
          
          if (p.symbol == 'USD/TRY') {
            _usdTryRate = p.currentPrice;
          }
        }
      });

      _prices = allPrices;
    } catch (e) {
      print('Error fetching prices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getPrice(String symbol) {
    if (symbol.isEmpty) return 0.0;
    final search = symbol.toUpperCase();
    try {
      final data = _prices.firstWhere((p) => p.symbol.toUpperCase() == search);
      return data.price;
    } catch (_) {
      return 0.0;
    }
  }

  MarketData? getMarketData(String symbol) {
    if (symbol.isEmpty) return null;
    final search = symbol.toUpperCase();
    try {
      return _prices.firstWhere((p) => p.symbol.toUpperCase() == search);
    } catch (_) {
      return null;
    }
  }
}
