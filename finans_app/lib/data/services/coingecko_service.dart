import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:finans_app/data/models/market_price.dart';

/// CoinGecko üzerinden kripto, emtia ve döviz verilerini çeker.
/// NOT: Hisse (borsa) verileri artık backend'den (MarketApiService) alınıyor.
class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const String _fxApiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  // ─────────────────────────────────────────────────────────
  // Önbellek Yardımcıları
  // ─────────────────────────────────────────────────────────

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

  T? _getCached<T>(String key) {
    if (_isCacheValid(key)) return _cache[key] as T?;
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // USD/TRY Kuru
  // ─────────────────────────────────────────────────────────

  Future<Map<String, double>> _fetchFxRates() async {
    const cacheKey = 'fx_rates';
    final cached = _getCached<Map<String, double>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await http
          .get(Uri.parse(_fxApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawRates = data['rates'] as Map<String, dynamic>? ?? {};
        final rates = rawRates.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        _updateCache(cacheKey, rates);
        return rates;
      }
    } catch (e) {
      debugPrint('FX Rates fetch error: $e');
    }

    // Önbellekte eski veri varsa onu kullan
    return _cache[cacheKey] as Map<String, double>? ?? {'TRY': 43.75};
  }

  // ─────────────────────────────────────────────────────────
  // Kripto Fiyatları (CoinGecko)
  // ─────────────────────────────────────────────────────────

  Future<List<MarketPrice>> fetchCryptoPrices() async {
    const cacheKey = 'crypto_prices';
    final cached = _getCached<List<MarketPrice>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await http
          .get(Uri.parse(
            '$_baseUrl/coins/markets'
            '?vs_currency=usd'
            '&order=market_cap_desc'
            '&per_page=50'
            '&page=1'
            '&sparkline=false',
          ))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data
            .where((item) => item != null)
            .map((item) => MarketPrice.fromCoinGecko(item, 'crypto'))
            .toList();

        _updateCache(cacheKey, result);
        return result;
      } else if (response.statusCode == 429) {
        debugPrint('CoinGecko rate limit: 429, önbellek döndürülüyor.');
      } else {
        debugPrint('CoinGecko error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('fetchCryptoPrices error: $e');
    }

    return _cache[cacheKey] as List<MarketPrice>? ?? [];
  }

  // ─────────────────────────────────────────────────────────
  // Emtia Fiyatları (CoinGecko PAXG + hesaplama)
  // ─────────────────────────────────────────────────────────

  Future<List<MarketPrice>> fetchCommodityPrices() async {
    const cacheKey = 'commodity_prices';
    final cached = _getCached<List<MarketPrice>>(cacheKey);
    if (cached != null) return cached;

    final fxRates = await _fetchFxRates();
    final double tryRate = fxRates['TRY'] ?? 43.75;

    double ounceGold = 2750.0;
    double ounceSilver = 32.50;
    double goldChangePercent = 0.0;
    double silverChangePercent = 0.0;

    try {
      // PAXG ≈ Ons Altın, XAUT de alternatif. Silver token: "tether-gold" vs
      final response = await http
          .get(Uri.parse(
            '$_baseUrl/coins/markets'
            '?vs_currency=usd'
            '&ids=pax-gold,tether-gold'
            '&sparkline=false',
          ))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final goldData = data.firstWhere(
          (e) => e['id'] == 'pax-gold' || e['id'] == 'tether-gold',
          orElse: () => null,
        );
        if (goldData != null) {
          ounceGold = (goldData['current_price'] as num?)?.toDouble() ?? ounceGold;
          goldChangePercent =
              (goldData['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint('Commodity CoinGecko fetch error: $e');
      // Önbellekte eski veri varsa döndür
      final old = _cache[cacheKey] as List<MarketPrice>?;
      if (old != null) return old;
    }

    final double gramGold = (ounceGold / 31.1034) * tryRate;
    final double gramSilver = (ounceSilver / 31.1034) * tryRate;

    final result = [
      MarketPrice(
        id: 'gram-altin',
        symbol: 'GRAM-ALTIN',
        name: 'Gram Altın',
        currentPrice: gramGold,
        priceChange24h: gramGold * (goldChangePercent / 100),
        priceChangePercentage24h: goldChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'gram-gumus',
        symbol: 'GRAM-GUMUS',
        name: 'Gram Gümüş',
        currentPrice: gramSilver,
        priceChange24h: gramSilver * (silverChangePercent / 100),
        priceChangePercentage24h: silverChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'ons-altin',
        symbol: 'GC=F',
        name: 'Ons Altın',
        currentPrice: ounceGold,
        priceChange24h: ounceGold * (goldChangePercent / 100),
        priceChangePercentage24h: goldChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'ons-gumus',
        symbol: 'SI=F',
        name: 'Ons Gümüş',
        currentPrice: ounceSilver,
        priceChange24h: ounceSilver * (silverChangePercent / 100),
        priceChangePercentage24h: silverChangePercent,
        category: 'commodity',
      ),
      MarketPrice(
        id: 'ceyrek-altin',
        symbol: 'CEYREK-ALTIN',
        name: 'Çeyrek Altın',
        currentPrice: gramGold * 1.75 * 0.916,
        priceChange24h: (gramGold * 1.75 * 0.916) * (goldChangePercent / 100),
        priceChangePercentage24h: goldChangePercent,
        category: 'commodity',
      ),
    ];

    _updateCache(cacheKey, result);
    return result;
  }

  // ─────────────────────────────────────────────────────────
  // Döviz Kurları (ExchangeRate API — GERÇEK değişim hesabı)
  // ─────────────────────────────────────────────────────────

  Future<List<MarketPrice>> fetchCurrencyRates() async {
    const cacheKey = 'currency_rates';
    const prevKey = 'currency_rates_prev';
    final cached = _getCached<List<MarketPrice>>(cacheKey);
    if (cached != null) return cached;

    try {
      // Güncel kur
      final response = await http
          .get(Uri.parse(_fxApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final rates = (data['rates'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble()));

        final double tryRate = rates['TRY'] ?? 43.75;
        final double eurRate = rates['EUR'] ?? 0.92;
        final double gbpRate = rates['GBP'] ?? 0.79;
        final double jpyRate = rates['JPY'] ?? 149.0;
        final double chfRate = rates['CHF'] ?? 0.89;

        // Hesapla: 1 birim yabancı para = kaç TL
        final usdTry  = tryRate;
        final eurTry  = (1 / eurRate) * tryRate;
        final gbpTry  = (1 / gbpRate) * tryRate;
        final jpyTry  = (1 / jpyRate) * tryRate;
        final chfTry  = (1 / chfRate) * tryRate;
        final eurUsd  = 1 / eurRate;

        // Önceki kur verisi önbellekte varsa yüzde değişimi hesapla
        final prev = _cache[prevKey] as Map<String, double>?;
        double chg(double cur, String k) {
          if (prev == null || prev[k] == null || prev[k] == 0) return 0.0;
          return ((cur - prev[k]!) / prev[k]!) * 100;
        }

        // Şimdiki değerleri yarın için önceki değer olarak sakla
        _cache[prevKey] = {
          'usdTry': usdTry,
          'eurTry': eurTry,
          'gbpTry': gbpTry,
          'jpyTry': jpyTry,
          'chfTry': chfTry,
          'eurUsd': eurUsd,
        };

        final result = [
          MarketPrice(
            id: 'usd-try',
            symbol: 'USDTRY=X',
            name: 'Amerikan Doları',
            currentPrice: usdTry,
            priceChange24h: prev != null ? (usdTry - (prev['usdTry'] ?? usdTry)) : 0.0,
            priceChangePercentage24h: chg(usdTry, 'usdTry'),
            category: 'currency',
          ),
          MarketPrice(
            id: 'eur-try',
            symbol: 'EURTRY=X',
            name: 'Euro',
            currentPrice: eurTry,
            priceChange24h: prev != null ? (eurTry - (prev['eurTry'] ?? eurTry)) : 0.0,
            priceChangePercentage24h: chg(eurTry, 'eurTry'),
            category: 'currency',
          ),
          MarketPrice(
            id: 'gbp-try',
            symbol: 'GBPTRY=X',
            name: 'İngiliz Sterlini',
            currentPrice: gbpTry,
            priceChange24h: prev != null ? (gbpTry - (prev['gbpTry'] ?? gbpTry)) : 0.0,
            priceChangePercentage24h: chg(gbpTry, 'gbpTry'),
            category: 'currency',
          ),
          MarketPrice(
            id: 'jpy-try',
            symbol: 'JPYTRY=X',
            name: 'Japon Yeni',
            currentPrice: jpyTry,
            priceChange24h: prev != null ? (jpyTry - (prev['jpyTry'] ?? jpyTry)) : 0.0,
            priceChangePercentage24h: chg(jpyTry, 'jpyTry'),
            category: 'currency',
          ),
          MarketPrice(
            id: 'chf-try',
            symbol: 'CHFTRY=X',
            name: 'İsviçre Frangı',
            currentPrice: chfTry,
            priceChange24h: prev != null ? (chfTry - (prev['chfTry'] ?? chfTry)) : 0.0,
            priceChangePercentage24h: chg(chfTry, 'chfTry'),
            category: 'currency',
          ),
          MarketPrice(
            id: 'eur-usd',
            symbol: 'EURUSD=X',
            name: 'Euro/Dolar',
            currentPrice: eurUsd,
            priceChange24h: prev != null ? (eurUsd - (prev['eurUsd'] ?? eurUsd)) : 0.0,
            priceChangePercentage24h: chg(eurUsd, 'eurUsd'),
            category: 'currency',
          ),
        ];

        _updateCache(cacheKey, result);
        return result;
      }
    } catch (e) {
      debugPrint('fetchCurrencyRates error: $e');
    }

    return _cache[cacheKey] as List<MarketPrice>? ?? [];
  }

  // ─────────────────────────────────────────────────────────
  // fetchAllMarkets (crypto + emtia + döviz)
  // Hisseler backend'den geliyor, burada yok.
  // ─────────────────────────────────────────────────────────

  Future<Map<String, List<MarketPrice>>> fetchAllMarkets() async {
    final results = await Future.wait([
      fetchCryptoPrices().catchError((_) => <MarketPrice>[]),
      fetchCommodityPrices().catchError((_) => <MarketPrice>[]),
      fetchCurrencyRates().catchError((_) => <MarketPrice>[]),
    ]);

    return {
      'crypto':    results[0],
      'commodity': results[1],
      'currency':  results[2],
    };
  }
}
