import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:finans_app/data/models/market_price.dart';

class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  // Fetch cryptocurrency prices
  Future<List<MarketPrice>> fetchCryptoPrices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false'),
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

  // Fetch commodity prices (Gold, Silver, Platinum, Palladium)
  Future<List<MarketPrice>> fetchCommodityPrices() async {
    try {
      // 1. Get USD/TRY rate first (we need it for calculations)
      // 1. Get USD/TRY rate first
      double tryRate = 43.75; // 2026 level
      try {
        final fxResponse = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
        if (fxResponse.statusCode == 200) {
          final fxData = json.decode(fxResponse.body);
          tryRate = (fxData['rates']['TRY'] ?? 43.75).toDouble();
        }
      } catch (_) {}

      // 2. Fetch Ounce prices from CoinGecko
      final response = await http.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&ids=pax-gold,tether-gold,silver-tokenized-stock-defichain,platinum-tokenized-stock-defichain,palladium-tokenized-stock-defichain&sparkline=false'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final ounceGold = data.firstWhere((e) => e['id'] == 'pax-gold' || e['id'] == 'tether-gold')['current_price'].toDouble();
        
        double ounceSilver = 60.0; // 2026 estimate
        try {
          ounceSilver = data.firstWhere((e) => e['id'] == 'silver-tokenized-stock-defichain')['current_price'].toDouble();
        } catch (_) {}

        double ouncePlatinum = 1500.0;
        try {
          ouncePlatinum = data.firstWhere((e) => e['id'] == 'platinum-tokenized-stock-defichain')['current_price'].toDouble();
        } catch (_) {}

        double ouncePalladium = 1400.0;
        try {
          ouncePalladium = data.firstWhere((e) => e['id'] == 'palladium-tokenized-stock-defichain')['current_price'].toDouble();
        } catch (_) {}

        // 2026 Prices usually incorporate local premium/spread
        final double gramGold = (ounceGold / 31.1034768) * tryRate * 1.05; // Added local premium
        final double gramSilver = (ounceSilver / 31.1034768) * tryRate;
        final double gramPlatinum = (ouncePlatinum / 31.1034768) * tryRate;
        final double gramPalladium = (ouncePalladium / 31.1034768) * tryRate;

        // Return the list of Turkish commodity prices
        return [
          MarketPrice(
            id: 'altin-gumus-rasyosu',
            symbol: 'XAU/XAG',
            name: 'Altın/Gümüş Rasyosu',
            currentPrice: ounceGold / ounceSilver,
            priceChange24h: (ounceGold / ounceSilver) * 0.002,
            priceChangePercentage24h: 0.2,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'gram-altin',
            symbol: 'GA',
            name: 'Gram Altın',
            currentPrice: gramGold,
            priceChange24h: gramGold * 0.005,
            priceChangePercentage24h: 0.5,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'ceyrek-altin',
            symbol: 'CEYREK',
            name: 'Çeyrek Altın',
            currentPrice: gramGold * 1.606,
            priceChange24h: (gramGold * 1.606) * 0.005,
            priceChangePercentage24h: 0.5,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'yarim-altin',
            symbol: 'YARIM',
            name: 'Yarım Altın',
            currentPrice: gramGold * 3.212,
            priceChange24h: (gramGold * 3.212) * 0.005,
            priceChangePercentage24h: 0.5,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'tam-altin',
            symbol: 'TAM',
            name: 'Tam Altın',
            currentPrice: gramGold * 6.424,
            priceChange24h: (gramGold * 6.424) * 0.005,
            priceChangePercentage24h: 0.5,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'cumhuriyet-altini',
            symbol: 'CUMHURIYET',
            name: 'Cumhuriyet Altını',
            currentPrice: gramGold * 7.21,
            priceChange24h: (gramGold * 7.21) * 0.005,
            priceChangePercentage24h: 0.5,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'ons-altin',
            symbol: 'XAU/USD',
            name: 'Ons Altın',
            currentPrice: ounceGold,
            priceChange24h: ounceGold * 0.005,
            priceChangePercentage24h: 0.5,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'gumus-gram',
            symbol: 'XAG/TRY',
            name: 'Gümüş (Gram)',
            currentPrice: gramSilver,
            priceChange24h: gramSilver * 0.008,
            priceChangePercentage24h: 0.8,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'ons-gumus',
            symbol: 'XAG/USD',
            name: 'Ons Gümüş',
            currentPrice: ounceSilver,
            priceChange24h: ounceSilver * 0.008,
            priceChangePercentage24h: 0.8,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'platin-gram',
            symbol: 'XPT/TRY',
            name: 'Platin (Gram)',
            currentPrice: gramPlatinum,
            priceChange24h: gramPlatinum * 0.003,
            priceChangePercentage24h: 0.3,
            category: 'commodity',
          ),
          MarketPrice(
            id: 'paladyum-gram',
            symbol: 'XPD/TRY',
            name: 'Paladyum (Gram)',
            currentPrice: gramPalladium,
            priceChange24h: gramPalladium * 0.004,
            priceChangePercentage24h: 0.4,
            category: 'commodity',
          ),
        ];
      }
      return [];
    } catch (e) {
      print('Error fetching commodity prices: $e');
      return [];
    }
  }

  // Fetch major currency exchange rates (USD/TRY, EUR/TRY, etc.)
  Future<List<MarketPrice>> fetchCurrencyRates() async {
    try {
      // Using a free exchange rate API for better TRY support
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'];
        final double tryRate = (rates['TRY'] ?? 43.75).toDouble();
        final double eurRate = (rates['EUR'] ?? 0.90).toDouble();
        final double gbpRate = (rates['GBP'] ?? 0.77).toDouble();
        final double jpyRate = (rates['JPY'] ?? 145.0).toDouble();
        final double chfRate = (rates['CHF'] ?? 0.85).toDouble();

        return [
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
      }
      
      // Fallback to CoinGecko stablecoins if FX API fails
      final cgResponse = await http.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&ids=tether,usd-coin,dai,euro-coin&sparkline=false'),
      );
      if (cgResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(cgResponse.body);
        return data.map((item) => MarketPrice.fromCoinGecko(item, 'currency')).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching currency rates: $e');
      return [];
    }
  }

  // Fetch BIST Stock prices (Simulated for demonstration)
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
      {'id': 'toaso', 'symbol': 'TOASO', 'name': 'Tofaş', 'price': 285.00},
      {'id': 'arclk', 'symbol': 'ARCLK', 'name': 'Arçelik', 'price': 175.50},
    ];

    final random = Random();
    return stocks.map((s) {
      final changePercent = (random.nextDouble() * 3) - 1.2; // Realistic range
      final currentPrice = (s['price'] as double) * (1 + changePercent / 100);
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

  // Fetch all market data
  Future<Map<String, List<MarketPrice>>> fetchAllMarkets() async {
    final results = await Future.wait([
      fetchCryptoPrices(),
      fetchCommodityPrices(),
      fetchCurrencyRates(),
      fetchStockPrices(),
    ]);

    return {
      'crypto': results[0],
      'commodity': results[1],
      'currency': results[2],
      'stock': results[3],
    };
  }

  // Simple price lookup for specific symbols
  Future<double?> getPrice(String symbol) async {
    try {
      final cryptoId = _symbolToCoinGeckoId(symbol);
      if (cryptoId == null) {
        // Check if it's a simulated stock
        if (symbol == 'THYAO') return 285.50;
        if (symbol == 'USD/TRY') {
           final rates = await fetchCurrencyRates();
           return rates.firstWhere((e) => e.symbol == 'USD/TRY').currentPrice;
        }
        return null;
      }

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
