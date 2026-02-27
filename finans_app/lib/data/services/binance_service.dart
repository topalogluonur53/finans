import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';

class BinanceService {
  /// Fetch account balances and calculate total USDT value via backend proxy
  Future<double> getTotalUsdtBalance(String apiKey, String apiSecret) async {
    try {
      final key = apiKey.trim();
      final secret = apiSecret.trim();
      
      final url = Uri.parse('${ApiConstants.baseUrl}/portfolio/binance-balance/');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'apiKey': key,
          'apiSecret': secret,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.tryParse(data['totalUsdt']?.toString() ?? '0') ?? 0.0;
      } else {
        throw Exception('Failed to fetch info: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Binance Proxy Hatası: $e');
    }
  }
}
