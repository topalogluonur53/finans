import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finans_app/data/services/market_api_service.dart';
import 'package:finans_app/data/services/coingecko_service.dart';
import 'package:finans_app/data/models/market_price.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MarketData Model
// ─────────────────────────────────────────────────────────────────────────────

class MarketData {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final double? priceChange24h;
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
    this.priceChange24h,
    this.dayHigh,
    this.dayLow,
    this.openPrice,
    required this.category,
    this.isIndex = false,
    this.parentSymbol,
    this.imageUrl,
  }) : name = _prettyNames[symbol.toUpperCase()] ?? name;

  static const Map<String, String> _prettyNames = {
    'GC=F':             'Altın (Ons)',
    'SI=F':             'Gümüş (Ons)',
    'PL=F':             'Platin (Ons)',
    'PA=F':             'Paladyum (Ons)',
    'BZ=F':             'Brent Petrol',
    'CL=F':             'WTI Petrol',
    'NG=F':             'Doğalgaz',
    'HG=F':             'Bakır',
    'USDTRY=X':         'Dolar/TL',
    'EURTRY=X':         'Euro/TL',
    'EURUSD=X':         'Euro/Dolar',
    'GBPUSD=X':         'Sterlin/Dolar',
    'GBPTRY=X':         'Sterlin/TL',
    'JPYTRY=X':         'Yen/TL',
    'CHFTRY=X':         'İsviçre Frangı/TL',
    'XU100.IS':         'BIST 100',
    'XU050.IS':         'BIST 50',
    'XU030.IS':         'BIST 30',
    'XUTUM.IS':         'BIST Tüm',
    'XBANK.IS':         'BIST Banka',
    'XUSIN.IS':         'BIST Sınai',
    'XHIZM.IS':         'BIST Hizmetler',
    'XTKJS.IS':         'BIST Teknoloji',
    'XGMYO.IS':         'BIST GMYO',
    'XHOLD.IS':         'BIST Holding ve Yatırım',
    '^GSPC':            'S&P 500',
    '^IXIC':            'NASDAQ',
    '^DJI':             'Dow Jones',
    '^FTSE':            'FTSE 100',
    '^GDAXI':           'DAX Performance',
    'GRAM-ALTIN':       'Gram Altın',
    'GRAM-GUMUS':       'Gram Gümüş',
    'GRAM-PLATIN':      'Gram Platin',
    'GRAM-PALADYUM':    'Gram Paladyum',
    'CEYREK-ALTIN':     'Çeyrek Altın',
    'YARIM-ALTIN':      'Yarım Altın',
    'TAM-ALTIN':        'Tam Altın',
    'CUMHURIYET-ALTIN': 'Cumhuriyet Altını',
    '22-AYAR-BILEZIK':  '22 Ayar Bilezik (gr)',
    'XAUXAG':           'Altın/Gümüş Rasyosu',
    'BTCUSDT':          'Bitcoin',
    'ETHUSDT':          'Ethereum',
    'BNBUSDT':          'Binance Coin',
    'SOLUSDT':          'Solana',
    'XRPUSDT':          'Ripple',
    'ADAUSDT':          'Cardano',
    'DOGEUSDT':         'Dogecoin',
    'AVAXUSDT':         'Avalanche',
    'DOTUSDT':          'Polkadot',
    'LINKUSDT':         'Chainlink',
  };

  /// MarketPrice modeli → MarketData
  factory MarketData.fromMarketPrice(MarketPrice p, {String? overrideCategory}) {
    return MarketData(
      symbol:       p.symbol,
      name:         p.name,
      price:        p.currentPrice,
      changePercent: p.priceChangePercentage24h,
      priceChange24h: p.priceChange24h,
      dayHigh:      p.dayHigh,
      dayLow:       p.dayLow,
      openPrice:    p.openPrice,
      category:     overrideCategory ?? p.category,
      isIndex:      p.isIndex,
      parentSymbol: p.parentSymbol,
      imageUrl:     p.imageUrl,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MarketProvider
// ─────────────────────────────────────────────────────────────────────────────

class MarketProvider extends ChangeNotifier {
  // Servisler
  final MarketApiService _backendService = MarketApiService();
  final CoinGeckoService _geckoService   = CoinGeckoService();

  // Durum
  List<MarketData> _prices = [];
  bool _isLoading = false;
  String? _lastError;
  DateTime? _lastUpdated;
  double _usdTryRate = 43.75;

  // Favoriler
  final List<String> _favorites = ['BTCUSDT', 'USDTRY=X', 'GRAM-ALTIN'];

  // Zamanlayıcı
  Timer? _timer;

  // ── Getterlar ─────────────────────────────────────────────────────────────
  List<MarketData> get prices      => _prices;
  bool             get isLoading   => _isLoading;
  String?          get lastError   => _lastError;
  DateTime?        get lastUpdated => _lastUpdated;
  double           get usdTryRate  => _usdTryRate;
  List<String>     get favorites   => _favorites;

  // ── Favoriler ─────────────────────────────────────────────────────────────
  void toggleFavorite(String symbol) {
    if (_favorites.contains(symbol)) {
      _favorites.remove(symbol);
    } else {
      _favorites.add(symbol);
    }
    notifyListeners();
  }

  bool isFavorite(String symbol) => _favorites.contains(symbol);

  // ── Arama ─────────────────────────────────────────────────────────────────
  List<MarketData> searchPrices(String query) {
    if (query.isEmpty) return _prices;
    final q = query.toLowerCase();
    return _prices
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.symbol.toLowerCase().contains(q))
        .toList();
  }

  // ── Polling ───────────────────────────────────────────────────────────────
  void startPolling() {
    _fetchPrices();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchPrices(isBackground: true);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshManual() => _fetchPrices();

  // ── Ana veri çekme mantığı ────────────────────────────────────────────────

  Future<void> _fetchPrices({bool isBackground = false}) async {
    if (_isLoading && !isBackground) return;

    if (!isBackground) {
      _isLoading = true;
      _lastError = null;
      notifyListeners();
    }

    try {
      // Paralel olarak backend ve Binance'den veri çekiyoruz
      final results = await Future.wait([
        _backendService.fetchCategorizedMarkets().catchError((e) {
          debugPrint('Backend fetchCategorizedMarkets error: $e');
          return <String, List<MarketPrice>>{};
        }),
        _backendService.fetchBinancePrices().catchError((e) {
          debugPrint('Binance fetchBinancePrices error: $e');
          return <MarketPrice>[];
        }),
      ]);

      final backendData = results[0] as Map<String, List<MarketPrice>>;
      final binanceData = results[1] as List<MarketPrice>;

      // Backend verisi tamamen boşsa CoinGecko fallback
      final bool backendEmpty = backendData.values.every((l) => l.isEmpty);

      Map<String, List<MarketPrice>> geckoData = {};
      if (backendEmpty) {
        debugPrint('Backend boş döndü, CoinGecko fallback başlatılıyor...');
        geckoData = await _geckoService.fetchAllMarkets().catchError((e) {
          debugPrint('CoinGecko fallback error: $e');
          return <String, List<MarketPrice>>{};
        });
      }

      // ── Veri birleştirme ──────────────────────────────────────────────────
      final Map<String, MarketData> merged = {};

      // 1) Backend verisi (öncelikli — gerçek Yahoo Finance verisi)
      backendData.forEach((category, priceList) {
        for (final p in priceList) {
          if (p.currentPrice > 0) {
            merged[p.symbol] = MarketData.fromMarketPrice(p, overrideCategory: category);

            // USD/TRY kurunu güncelle
            if (p.symbol == 'USDTRY=X' && p.currentPrice > 0) {
              _usdTryRate = p.currentPrice;
            }
          }
        }
      });

      // 2) Binance kripto verisi (ikincil)
      for (final p in binanceData) {
        if (!merged.containsKey(p.symbol) && p.currentPrice > 0) {
          merged[p.symbol] = MarketData.fromMarketPrice(p, overrideCategory: 'crypto');
        }
      }

      // 3) CoinGecko fallback (backend boşsa)
      if (backendEmpty) {
        geckoData.forEach((category, priceList) {
          for (final p in priceList) {
            if (!merged.containsKey(p.symbol) && p.currentPrice > 0) {
              merged[p.symbol] = MarketData.fromMarketPrice(p, overrideCategory: category);
            }
          }
        });
      }

      // ── Listeyi güncelle (sadece veri varsa) ─────────────────────────────
      if (merged.isNotEmpty) {
        _prices = merged.values.toList();
        _lastUpdated = DateTime.now();
        _lastError = null;
        debugPrint('MarketProvider: ${_prices.length} sembol yüklendi.');
      } else {
        // Hiçbir kaynaktan veri gelmedi — önceki veri korunuyor
        debugPrint('MarketProvider: Tüm kaynaklar boş döndü, önceki veri korunuyor.');
        if (_prices.isEmpty) {
          _lastError = 'Veri alınamadı. İnternet bağlantınızı kontrol edin.';
        }
      }
    } catch (e, stack) {
      debugPrint('MarketProvider genel hata: $e');
      debugPrint(stack.toString());
      if (_prices.isEmpty) {
        _lastError = 'Piyasa verisi yüklenirken hata: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Yardımcı Methodlar ────────────────────────────────────────────────────

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

  List<MarketData> getByCategory(String category) {
    return _prices.where((p) => p.category == category).toList();
  }
}
