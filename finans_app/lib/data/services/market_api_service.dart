import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/market_price.dart';

class MarketApiService {
  Future<Map<String, List<MarketPrice>>> fetchCategorizedMarkets() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categorizedMarketEndpoint}'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Map<String, List<MarketPrice>> result = {};
        
        data.forEach((category, prices) {
          result[category] = (prices as List)
              .map((p) => MarketPrice.fromJson(p, category))
              .toList();
        });
        
        return result;
      }
      return {};
    } catch (e) {
      print('Market API Service Error: $e');
      return {};
    }
  }

  Future<bool> createAlarm({
    required String symbol,
    required String marketType,
    required double targetPrice,
    required String condition,
    required String token,
  }) async {
    try {
      final response = await http.post(
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
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create Alarm Error: $e');
      return false;
    }
  }
}
