import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:finans_app/data/models/market_price.dart';

class CoinGeckoService {
  static const String _baseUrlValue = 'https://api.coingecko.com/api/v3';
  
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 1);

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final time = _cacheTime[key];
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheDuration;
  }

  void _updateCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTime[key] = DateTime.now();
  }

  Future<List<MarketPrice>> fetchCryptoPrices() async {
    const cacheKey = 'crypto_prices';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrlValue/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data
            .where((item) => item != null)
            .map((item) => MarketPrice.fromCoinGecko(item, 'crypto'))
            .toList();
        
        _updateCache(cacheKey, result);
        return result;
      }
      if (_cache.containsKey(cacheKey)) return _cache[cacheKey];
      return [];
    } catch (e) {
      print('Error fetching crypto prices: $e');
      return _cache[cacheKey] ?? [];
    }
  }

  Future<List<MarketPrice>> fetchCommodityPrices() async {
    const cacheKey = 'commodity_prices';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey];

    double tryRate = 43.75; 
    double ounceGold = 2750.0;
    double ounceSilver = 32.50;
    double goldChangePercent = 0.45;
    double silverChangePercent = -0.12;

    try {
      try {
        final fxResponse = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD')).timeout(const Duration(seconds: 5));
        if (fxResponse.statusCode == 200) {
          final fxData = json.decode(fxResponse.body);
          if (fxData['rates'] != null && fxData['rates']['TRY'] != null) {
            tryRate = fxData['rates']['TRY'].toDouble();
          }
        }
      } catch (e) {
        print('FX Rate fetch error: $e');
      }

      try {
        final response = await http.get(
          Uri.parse('$_baseUrlValue/coins/markets?vs_currency=usd&ids=pax-gold,silver-tokenized-stock-defichain&sparkline=false'),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final goldData = data.firstWhere((e) => e['id'] == 'pax-gold', orElse: () => null);
          final silverData = data.firstWhere((e) => e['id'] == 'silver-tokenized-stock-defichain', orElse: () => null);

          if (goldData != null) {
            ounceGold = (goldData['current_price'] ?? 2750.0).toDouble();
            goldChangePercent = (goldData['price_change_percentage_24h'] ?? 0.45).toDouble();
          }
          if (silverData != null) {
            ounceSilver = (silverData['current_price'] ?? 32.50).toDouble();
            silverChangePercent = (silverData['price_change_percentage_24h'] ?? -0.12).toDouble();
          }
        }
      } catch (e) {
        print('CoinGecko fetch error: $e');
      }
    } catch (e) {
      print('Commodity logic error: $e');
    }

    final double gramGold = (ounceGold / 31.1034) * tryRate;
    final double gramSilver = (ounceSilver / 31.1034) * tryRate;

    final result = [
      MarketPrice(
        id: 'gram-altin',
        symbol: 'AU/TRY',
        name: 'Gram Altın',
        currentPrice: gramGold,
        priceChange24h: gramGold * (goldChangePercent / 100),
        priceChangePercentage24h: goldChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'gram-gumus',
        symbol: 'AG/TRY',
        name: 'Gram Gümüş',
        currentPrice: gramSilver,
        priceChange24h: gramSilver * (silverChangePercent / 100),
        priceChangePercentage24h: silverChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'altin-gumus-rasyosu',
        symbol: 'AU/AG',
        name: 'Altın/Gümüş Rasyosu',
        currentPrice: ounceSilver > 0 ? (ounceGold / ounceSilver) : 0,
        priceChange24h: 0,
        priceChangePercentage24h: goldChangePercent - silverChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'ons-altin',
        symbol: 'AU/USD',
        name: 'Ons Altın',
        currentPrice: ounceGold,
        priceChange24h: ounceGold * (goldChangePercent / 100),
        priceChangePercentage24h: goldChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'ons-gumus',
        symbol: 'AG/USD',
        name: 'Ons Gümüş',
        currentPrice: ounceSilver,
        priceChange24h: ounceSilver * (silverChangePercent / 100),
        priceChangePercentage24h: silverChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'ceyrek-altin',
        symbol: 'CEYREK',
        name: 'Çeyrek Altın',
        currentPrice: gramGold * 1.635,
        priceChange24h: (gramGold * 1.635) * (goldChangePercent / 100),
        priceChangePercentage24h: goldChangePercent,
        category: 'commodity',
      ),
    ];
    
    _updateCache(cacheKey, result);
    return result;
  }

  Future<List<MarketPrice>> fetchCurrencyRates() async {
    const cacheKey = 'currency_rates';
    if (_isCacheValid(cacheKey)) return _cache[cacheKey];

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'] ?? {};
        final double tryRate = (rates['TRY'] ?? 43.75).toDouble();
        final double eurRate = (rates['EUR'] ?? 0.90).toDouble();
        final double gbpRate = (rates['GBP'] ?? 0.77).toDouble();
        final double jpyRate = (rates['JPY'] ?? 145.0).toDouble();
        final double chfRate = (rates['CHF'] ?? 0.85).toDouble();

        final result = [
          MarketPrice(
            id: 'usd-try',
            symbol: 'USD/TRY',
            name: 'Amerikan Doları',
            currentPrice: tryRate,
            priceChange24h: 0.12,
            priceChangePercentage24h: 0.28,
            category: 'currency',
          ),
          MarketPrice(
            id: 'eur-try',
            symbol: 'EUR/TRY',
            name: 'Euro',
            currentPrice: (1 / eurRate) * tryRate,
            priceChange24h: 0.15,
            priceChangePercentage24h: 0.32,
            category: 'currency',
          ),
          MarketPrice(
            id: 'gbp-try',
            symbol: 'GBP/TRY',
            name: 'İngiliz Sterlini',
            currentPrice: (1 / gbpRate) * tryRate,
            priceChange24h: 0.18,
            priceChangePercentage24h: 0.35,
            category: 'currency',
          ),
          MarketPrice(
            id: 'jpy-try',
            symbol: 'JPY/TRY',
            name: 'Japon Yeni',
            currentPrice: (1 / jpyRate) * tryRate,
            priceChange24h: 0.01,
            priceChangePercentage24h: 0.05,
            category: 'currency',
          ),
          MarketPrice(
            id: 'chf-try',
            symbol: 'CHF/TRY',
            name: 'İsviçre Frangı',
            currentPrice: (1 / chfRate) * tryRate,
            priceChange24h: 0.03,
            priceChangePercentage24h: 0.10,
            category: 'currency',
          ),
        ];
        _updateCache(cacheKey, result);
        return result;
      }
      return _cache[cacheKey] ?? [];
    } catch (e) {
      print('Error fetching currency rates: $e');
      return _cache[cacheKey] ?? [];
    }
  }

  Future<List<MarketPrice>> fetchStockPrices() async {
    final stocks = [
      {'id': 'bist100', 'symbol': 'XU100', 'name': 'BIST 100', 'price': 14442.35},
      {'id': 'thyao', 'symbol': 'THYAO', 'name': 'Türk Hava Yolları', 'price': 342.50},
      {'id': 'garan', 'symbol': 'GARAN', 'name': 'Garanti Bankası', 'price': 118.30},
      {'id': 'eregl', 'symbol': 'EREGL', 'name': 'Erdemir', 'price': 52.10},
      {'id': 'asels', 'symbol': 'ASELS', 'name': 'Aselsan', 'price': 78.75},
      {'id': 'sise', 'symbol': 'SISE', 'name': 'Şişecam', 'price': 58.20},
      {'id': 'tupRS', 'symbol': 'TUPRS', 'name': 'Tüpraş', 'price': 185.40},
      {'id': 'kchol', 'symbol': 'KCHOL', 'name': 'Koç Holding', 'price': 245.80},
      {'id': 'bimas', 'symbol': 'BIMAS', 'name': 'BİM Birleşik Mağazalar', 'price': 485.00},
      {'id': 'isCTR', 'symbol': 'ISCTR', 'name': 'İş Bankası (C)', 'price': 15.40},
      {'id': 'akbnk', 'symbol': 'AKBNK', 'name': 'Akbank', 'price': 65.20},
      {'id': 'sahol', 'symbol': 'SAHOL', 'name': 'Sabancı Holding', 'price': 98.40},
      {'id': 'froto', 'symbol': 'FROTO', 'name': 'Ford Otosan', 'price': 1250.00},
    ];

    final random = Random();
    return stocks.map((s) {
      final changePercent = (random.nextDouble() * 3) - 1.2; 
      final currentPrice = (s['price'] as double);
      return MarketPrice(
        id: s['id'] as String,
        symbol: s['symbol'] as String,
        name: s['name'] as String,
        currentPrice: currentPrice,
        priceChange24h: currentPrice * (changePercent / 100),
        priceChangePercentage24h: changePercent,
        category: 'stock',
      );
    }).toList();
  }

  Future<Map<String, List<MarketPrice>>> fetchAllMarkets() async {
    final cryptoFuture = fetchCryptoPrices().catchError((_) => <MarketPrice>[]);
    final commodityFuture = fetchCommodityPrices().catchError((_) => <MarketPrice>[]);
    final currencyFuture = fetchCurrencyRates().catchError((_) => <MarketPrice>[]);
    final stockFuture = fetchStockPrices().catchError((_) => <MarketPrice>[]);

    final results = await Future.wait([
      cryptoFuture,
      commodityFuture,
      currencyFuture,
      stockFuture,
    ]);

    return {
      'crypto': results[0],
      'commodity': results[1],
      'currency': results[2],
      'stock': results[3],
    };
  }
}
