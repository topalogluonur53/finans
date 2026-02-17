import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';

class MarketProvider extends ChangeNotifier {
  List<MarketData> _prices = [];
  bool _isLoading = false;
  Timer? _timer;

  List<MarketData> get prices => _prices;
  bool get isLoading => _isLoading;

  void startPolling() {
    _fetchPrices();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchPrices();
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> _fetchPrices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.pricesEndpoint)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _prices = data.map((e) => MarketData.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching prices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getPrice(String symbol) {
    if (symbol.isEmpty) return 0.0;
    try {
      return _prices.firstWhere((element) => element.symbol == symbol).price;
    } catch (_) {
      return 0.0; // Return 0 or last known
    }
  }
}

class MarketData {
  final String symbol;
  final double price;
  final double changePercent;

  MarketData({required this.symbol, required this.price, required this.changePercent});

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      symbol: json['symbol'],
      price: double.parse(json['price'].toString()),
      changePercent: double.parse(json['change_percent_24h']?.toString() ?? '0'),
    );
  }
}
