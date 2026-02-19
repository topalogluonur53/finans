import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finans_app/data/services/market_api_service.dart';

class MarketData {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final String category;
  final bool isIndex;
  final String? parentSymbol;

  MarketData({
    required this.symbol, 
    required String name,
    required this.price, 
    required this.changePercent, 
    required this.category,
    this.isIndex = false,
    this.parentSymbol,
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
  };
}

class MarketProvider extends ChangeNotifier {
  List<MarketData> _prices = [];
  bool _isLoading = false;
  Timer? _timer;
  double _usdTryRate = 32.50; 
  List<String> _favorites = ['BTC', 'USD/TRY', 'AU/TRY'];

  List<MarketData> get prices => _prices;
  bool get isLoading => _isLoading;
  double get usdTryRate => _usdTryRate;
  List<String> get favorites => _favorites;

  void toggleFavorite(String symbol) {
    if (_favorites.contains(symbol)) {
      _favorites.remove(symbol);
    } else {
      _favorites.add(symbol);
    }
    notifyListeners();
  }

  bool isFavorite(String symbol) => _favorites.contains(symbol);

  void startPolling() {
    _fetchPrices();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchPrices(isBackground: true);
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  final MarketApiService _service = MarketApiService();

  Future<void> _fetchPrices({bool isBackground = false}) async {
    if (_isLoading && !isBackground) return; 
    
    if (!isBackground) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final data = await _service.fetchCategorizedMarkets();
      List<MarketData> allPrices = [];
      
      data.forEach((category, prices) {
        for (var p in prices) {
          allPrices.add(MarketData(
            symbol: p.symbol,
            name: p.name,
            price: p.currentPrice,
            changePercent: p.priceChangePercentage24h,
            category: category,
            isIndex: p.isIndex,
            parentSymbol: p.parentSymbol,
          ));
          
          if (p.symbol == 'USD/TRY' || p.symbol == 'USDTRY=X') {
             _usdTryRate = p.currentPrice;
          }
        }
      });

      _prices = allPrices;
    } catch (e) {
      print('Error fetching prices from backend: $e');
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
