import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/market_price.dart';

class MarketApiService {
  // ─────────────────────────────────────────────────────────
  // Piyasa Verileri
  // ─────────────────────────────────────────────────────────

  Future<Map<String, List<MarketPrice>>> fetchCategorizedMarkets() async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.categorizedMarketEndpoint}'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Map<String, List<MarketPrice>> result = {};
        data.forEach((category, prices) {
          result[category] =
              (prices as List).map((p) => MarketPrice.fromJson(p, category)).toList();
        });
        return result;
      }
      return {};
    } catch (e) {
      debugPrint('Market API Service Error: $e');
      return {};
    }
  }

  Future<List<MarketPrice>> fetchBinancePrices() async {
    const symbolsList = [
      'BTCUSDT',
      'ETHUSDT',
      'BNBUSDT',
      'SOLUSDT',
      'XRPUSDT',
      'ADAUSDT',
      'DOGEUSDT',
      'AVAXUSDT',
      'DOTUSDT',
      'LINKUSDT',
    ];

    try {
      final uri = Uri.parse(
          'https://api.binance.com/api/v3/ticker/24hr?symbols=${Uri.encodeComponent(jsonEncode(symbolsList))}');

      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final symbol = item['symbol']?.toString() ?? '';
          final cleanSymbol = symbol.replaceAll('USDT', '');
          return MarketPrice(
            id: 'binance_$symbol',
            symbol: symbol,
            name: cleanSymbol,
            currentPrice:
                double.tryParse(item['lastPrice']?.toString() ?? '0') ?? 0.0,
            priceChange24h:
                double.tryParse(item['priceChange']?.toString() ?? '0') ?? 0.0,
            priceChangePercentage24h: double.tryParse(
                    item['priceChangePercent']?.toString() ?? '0') ??
                0.0,
            dayHigh: double.tryParse(item['highPrice']?.toString() ?? '0'),
            dayLow: double.tryParse(item['lowPrice']?.toString() ?? '0'),
            volume: double.tryParse(item['volume']?.toString() ?? '0')?.toInt(),
            category: 'crypto',
            imageUrl:
                'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${cleanSymbol.toLowerCase()}.png',
          );
        }).toList();
      } else {
        debugPrint(
            'Binance API Error: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Binance API Service Exception: $e');
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
      debugPrint('Create Alarm Error: $e');
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
      debugPrint('Delete Alarm Error: $e');
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
      debugPrint('Toggle Alarm Error: $e');
      return null;
    }
  }
}
