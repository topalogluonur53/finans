import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/market_price.dart';

class MarketApiService {
  // Son başarılı veri zamanını takip et (stale veri uyarısı için)
  DateTime? _lastSuccessfulFetch;

  bool get isDataStale {
    if (_lastSuccessfulFetch == null) return true;
    return DateTime.now().difference(_lastSuccessfulFetch!) >
        const Duration(minutes: 20);
  }

  // ─────────────────────────────────────────────────────────
  // Kategorize Piyasa Verileri (Backend / Yahoo Finance)
  // ─────────────────────────────────────────────────────────

  Future<Map<String, List<MarketPrice>>> fetchCategorizedMarkets() async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.categorizedMarketEndpoint}'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> raw = json.decode(response.body);
        final Map<String, List<MarketPrice>> result = {};

        raw.forEach((category, prices) {
          if (prices is List) {
            final list = prices
                .map((p) => MarketPrice.fromJson(
                      p as Map<String, dynamic>,
                      category,
                    ))
                .where((mp) => mp.currentPrice > 0) // Sıfır fiyatlı kayıtları ele
                .toList();
            if (list.isNotEmpty) {
              result[category] = list;
            }
          }
        });

        if (result.isNotEmpty) {
          _lastSuccessfulFetch = DateTime.now();
        }
        return result;
      } else {
        debugPrint(
            'MarketApiService: Backend hata ${response.statusCode} - ${response.body}');
        return {};
      }
    } on Exception catch (e) {
      debugPrint('MarketApiService fetchCategorizedMarkets exception: $e');
      return {};
    }
  }

  // ─────────────────────────────────────────────────────────
  // Binance Kripto Fiyatları (Doğrudan Binance API)
  // ─────────────────────────────────────────────────────────

  static const List<String> _cryptoSymbols = [
    'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT',
    'ADAUSDT', 'DOGEUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT',
    'MATICUSDT', 'LTCUSDT', 'UNIUSDT', 'ATOMUSDT', 'NEARUSDT',
  ];

  Future<List<MarketPrice>> fetchBinancePrices() async {
    try {
      final uri = Uri.parse(
        'https://api.binance.com/api/v3/ticker/24hr'
        '?symbols=${Uri.encodeComponent(jsonEncode(_cryptoSymbols))}',
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) {
              final symbol = item['symbol']?.toString() ?? '';
              final cleanSymbol = symbol.replaceAll('USDT', '');
              final price =
                  double.tryParse(item['lastPrice']?.toString() ?? '') ?? 0.0;
              if (price <= 0) return null;

              return MarketPrice(
                id: 'binance_$symbol',
                symbol: symbol,
                name: cleanSymbol,
                currentPrice: price,
                priceChange24h:
                    double.tryParse(item['priceChange']?.toString() ?? '') ??
                        0.0,
                priceChangePercentage24h: double.tryParse(
                        item['priceChangePercent']?.toString() ?? '') ??
                    0.0,
                dayHigh:
                    double.tryParse(item['highPrice']?.toString() ?? ''),
                dayLow:
                    double.tryParse(item['lowPrice']?.toString() ?? ''),
                volume: (double.tryParse(item['volume']?.toString() ?? ''))
                    ?.toInt(),
                category: 'crypto',
                imageUrl:
                    'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${cleanSymbol.toLowerCase()}.png',
              );
            })
            .whereType<MarketPrice>()
            .toList();
      } else {
        debugPrint(
            'Binance API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } on Exception catch (e) {
      debugPrint('fetchBinancePrices exception: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // Alarmlar
  // ─────────────────────────────────────────────────────────

  Future<bool> createAlarm({
    required String symbol,
    required String marketType,
    required double targetPrice,
    required String condition,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.alarmsEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'symbol': symbol,
              'market_type': marketType,
              'target_price': targetPrice,
              'condition': condition,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('createAlarm error: $e');
      return false;
    }
  }

  Future<bool> deleteAlarm(int id, String token) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.alarmsEndpoint}$id/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('deleteAlarm error: $e');
      return false;
    }
  }

  Future<bool?> toggleAlarm(int id, String token) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.alarmsEndpoint}$id/toggle_active/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['is_active'] as bool?;
      }
      return null;
    } catch (e) {
      debugPrint('toggleAlarm error: $e');
      return null;
    }
  }
}
