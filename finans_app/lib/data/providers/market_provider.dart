import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finans_app/data/services/market_api_service.dart';
import 'package:finans_app/data/models/market_price.dart';

class MarketData {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final double? dayHigh;
  final double? dayLow;
  final double? openPrice;
  final String category;
  final bool isIndex;
  final String? parentSymbol;
  final String? imageUrl;

  MarketData({
    required this.symbol,
    required String name,
    required this.price,
    required this.changePercent,
    this.dayHigh,
    this.dayLow,
    this.openPrice,
    required this.category,
    this.isIndex = false,
    this.parentSymbol,
    this.imageUrl,
  }) : name = _prettyNames[symbol.toUpperCase()] ?? name;

  static const Map<String, String> _prettyNames = {
    'GC=F': 'Altın (Ons)',
    'SI=F': 'Gümüş (Ons)',
    'PL=F': 'Platin (Ons)',
    'PA=F': 'Paladyum (Ons)',
    'BZ=F': 'Brent Petrol',
    'CL=F': 'WTI Petrol',
    'NG=F': 'Doğalgaz',
    'HG=F': 'Bakır',
    'USDTRY=X': 'Dolar/TL',
    'EURTRY=X': 'Euro/TL',
    'EURUSD=X': 'Euro/Dolar',
    'GBPUSD=X': 'Sterlin/Dolar',
    'GBPTRY=X': 'Sterlin/TL',
    'JPYTRY=X': 'Yen/TL',
    'CHFTRY=X': 'İsviçre Frangı/TL',
    'XU100.IS': 'BIST 100',
    '^GSPC': 'S&P 500',
    '^IXIC': 'NASDAQ',
    '^DJI': 'Dow Jones',
    '^FTSE': 'FTSE 100',
    '^GDAXI': 'DAX Performance',
    'GRAM-ALTIN': 'Gram Altın',
    'GRAM-GUMUS': 'Gram Gümüş',
    'GRAM-PLATIN': 'Gram Platin',
    'GRAM-PALADYUM': 'Gram Paladyum',
    'CEYREK-ALTIN': 'Çeyrek Altın',
    'YARIM-ALTIN': 'Yarım Altın',
    'TAM-ALTIN': 'Tam Altın',
    'CUMHURIYET-ALTIN': 'Cumhuriyet Altını',
    '22-AYAR-BILEZIK': '22 Ayar Bilezik (gr)',
    'BTCUSDT': 'Bitcoin',
    'ETHUSDT': 'Ethereum',
    'BNBUSDT': 'Binance Coin',
    'SOLUSDT': 'Solana',
    'XRPUSDT': 'Ripple',
    'ADAUSDT': 'Cardano',
    'DOGEUSDT': 'Dogecoin',
    'AVAXUSDT': 'Avalanche',
    'DOTUSDT': 'Polkadot',
    'LINKUSDT': 'Chainlink',
  };
}

class MarketProvider extends ChangeNotifier {
  List<MarketData> _prices = [];
  bool _isLoading = false;
  Timer? _timer;
  double _usdTryRate = 32.50;
  final List<String> _favorites = ['BTCUSDT', 'USDTRY=X', 'GRAM-ALTIN'];
  DateTime? _lastUpdated;

  List<MarketData> get prices => _prices;
  bool get isLoading => _isLoading;
  double get usdTryRate => _usdTryRate;
  List<String> get favorites => _favorites;
  DateTime? get lastUpdated => _lastUpdated;

  void toggleFavorite(String symbol) {
    if (_favorites.contains(symbol)) {
      _favorites.remove(symbol);
    } else {
      _favorites.add(symbol);
    }
    notifyListeners();
  }

  bool isFavorite(String symbol) => _favorites.contains(symbol);

  List<MarketData> searchPrices(String query) {
    if (query.isEmpty) return _prices;
    final q = query.toLowerCase();
    return _prices
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.symbol.toLowerCase().contains(q))
        .toList();
  }

  void startPolling() {
    _fetchPrices();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchPrices(isBackground: true);
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> refreshManual() => _fetchPrices();

  final MarketApiService _service = MarketApiService();

  Future<void> _fetchPrices({bool isBackground = false}) async {
    debugPrint('DEBUG: _fetchPrices started');
    if (_isLoading && !isBackground) return;

    if (!isBackground) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final categorizedFuture =
          _service.fetchCategorizedMarkets().catchError((e) {
        debugPrint('Categorized Markets Error: $e');
        return <String, List<MarketPrice>>{};
      });

      final binanceFuture = _service.fetchBinancePrices().catchError((e) {
        debugPrint('Binance API Error: $e');
        return <MarketPrice>[];
      });

      final results = await Future.wait([categorizedFuture, binanceFuture]);

      final Map<String, List<MarketPrice>> categorizedData =
          results[0] as Map<String, List<MarketPrice>>;
      final List<MarketPrice> binanceData = results[1] as List<MarketPrice>;

      List<MarketData> allPrices = [];

      categorizedData.forEach((category, prices) {
        for (var p in prices) {
          allPrices.add(MarketData(
            symbol: p.symbol,
            name: p.name,
            price: p.currentPrice,
            changePercent: p.priceChangePercentage24h,
            dayHigh: p.dayHigh,
            dayLow: p.dayLow,
            openPrice: p.openPrice,
            category: category,
            isIndex: p.isIndex,
            parentSymbol: p.parentSymbol,
            imageUrl: p.imageUrl,
          ));

          if (p.symbol == 'USDTRY=X') {
            _usdTryRate = p.currentPrice;
          }
        }
      });

      for (var p in binanceData) {
        if (!allPrices.any((existing) => existing.symbol == p.symbol)) {
          allPrices.add(MarketData(
            symbol: p.symbol,
            name: p.name,
            price: p.currentPrice,
            changePercent: p.priceChangePercentage24h,
            dayHigh: p.dayHigh,
            dayLow: p.dayLow,
            category: 'crypto',
            imageUrl: p.imageUrl,
          ));
        }
      }

      if (allPrices.isNotEmpty) {
        _prices = allPrices;
        _lastUpdated = DateTime.now();
      }
    } catch (e, stack) {
      debugPrint('General Error in _fetchPrices: $e');
      debugPrint(stack.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getPrice(String symbol) {
    if (symbol.isEmpty) return 0.0;
    final search = symbol.toUpperCase();
    try {
      return _prices.firstWhere((p) => p.symbol.toUpperCase() == search).price;
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
