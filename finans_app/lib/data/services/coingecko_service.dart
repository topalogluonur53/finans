import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:finans_app/data/models/market_price.dart';

class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  // Fetch cryptocurrency prices
  Future<List<MarketPrice>> fetchCryptoPrices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MarketPrice.fromCoinGecko(item, 'crypto')).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching crypto prices: $e');
      return [];
    }
  }

  // Fetch commodity prices (Gold, Silver)
  Future<List<MarketPrice>> fetchCommodityPrices() async {
    try {
      // CoinGecko has tokenized commodities
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&ids=pax-gold,tether-gold,silver-tokenized-stock-defichain&sparkline=false'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MarketPrice.fromCoinGecko(item, 'commodity')).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching commodity prices: $e');
      return [];
    }
  }

  // Fetch major currency exchange rates (via crypto stablecoins as proxy)
  Future<List<MarketPrice>> fetchCurrencyRates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&ids=tether,usd-coin,dai,true-usd,euro-coin&sparkline=false'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MarketPrice.fromCoinGecko(item, 'currency')).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching currency rates: $e');
      return [];
    }
  }

  // Fetch all market data
  Future<Map<String, List<MarketPrice>>> fetchAllMarkets() async {
    final results = await Future.wait([
      fetchCryptoPrices(),
      fetchCommodityPrices(),
      fetchCurrencyRates(),
    ]);

    return {
      'crypto': results[0],
      'commodity': results[1],
      'currency': results[2],
    };
  }

  // Simple price lookup for specific symbols
  Future<double?> getPrice(String symbol) async {
    try {
      final cryptoId = _symbolToCoinGeckoId(symbol);
      if (cryptoId == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/simple/price?ids=$cryptoId&vs_currencies=usd'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data[cryptoId]?['usd']?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting price for $symbol: $e');
      return null;
    }
  }

  String? _symbolToCoinGeckoId(String symbol) {
    final map = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'SOL': 'solana',
      'USDT': 'tether',
      'USDC': 'usd-coin',
      'GOLD': 'pax-gold',
      'SILVER': 'silver-tokenized-stock-defichain',
    };
    return map[symbol.toUpperCase()];
  }
}
