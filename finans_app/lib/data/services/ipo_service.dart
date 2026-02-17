import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:finans_app/data/models/ipo.dart';
import 'package:finans_app/data/models/ipo_news.dart';

class IPOService {
  // Financial Modeling Prep API - Free tier: 250 requests/day
  static const String _apiKey = 'demo'; // Replace with your API key
  static const String _baseUrl = 'https://financialmodelingprep.com/api/v3';

  /// Fetch IPO and stock market news
  Future<List<IPONews>> fetchIPONews() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stock_news?limit=50&apikey=$_apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Filter news for IPO keywords to make it relevant
        return data
            .map((item) => IPONews.fromJson(item))
            .where((news) => 
                news.title.toLowerCase().contains('ipo') || 
                news.content.toLowerCase().contains('ipo') ||
                news.title.toLowerCase().contains('offering'))
            .toList();
      }
      return _getFallbackNews();
    } catch (e) {
      print('Error fetching IPO news: $e');
      return _getFallbackNews();
    }
  }

  List<IPONews> _getFallbackNews() {
    return [
      IPONews(
        title: 'Borsada Yeni Halka Arz Rüzgarı',
        content: 'Teknoloji sektöründen dev bir şirket halka arz hazırlıklarına başladı. Detaylar yakında...',
        date: DateTime.now().toIso8601String(),
        url: 'https://google.com',
        source: 'Finans Haber',
      ),
      IPONews(
        title: 'Halka Arz Sonuçları Açıklandı',
        content: 'Geçen hafta talep toplayan enerji şirketinin halka arz sonuçları belli oldu.',
        date: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        url: 'https://google.com',
        source: 'Borsa Gündem',
      ),
    ];
  }

  // Alternative: IEX Cloud API
  static const String _iexToken = 'pk_demo'; // Replace with your token from iexcloud.io
  static const String _iexBaseUrl = 'https://cloud.iexapis.com/stable';

  /// Fetch IPO calendar (upcoming and recent IPOs)
  Future<List<IPO>> fetchIPOCalendar() async {
    try {
      // Try Financial Modeling Prep first
      final response = await http.get(
        Uri.parse('$_baseUrl/ipo_calendar?from=${_getDateString(-30)}&to=${_getDateString(90)}&apikey=$_apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => IPO.fromJson(item)).toList();
      }

      // Fallback to IEX Cloud
      return await _fetchFromIEX();
    } catch (e) {
      print('Error fetching IPO calendar: $e');
      // Return fallback data
      return _getFallbackIPOs();
    }
  }

  Future<List<IPO>> _fetchFromIEX() async {
    try {
      final response = await http.get(
        Uri.parse('$_iexBaseUrl/stock/market/upcoming-ipos?token=$_iexToken'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawIPOs = data['rawData'] ?? [];
        return rawIPOs.map((item) => IPO.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching from IEX: $e');
      return [];
    }
  }

  /// Fetch upcoming IPOs only
  Future<List<IPO>> fetchUpcomingIPOs() async {
    final allIPOs = await fetchIPOCalendar();
    return allIPOs.where((ipo) => ipo.isUpcoming).toList();
  }

  /// Fetch recent IPOs (last 30 days)
  Future<List<IPO>> fetchRecentIPOs() async {
    final allIPOs = await fetchIPOCalendar();
    return allIPOs.where((ipo) => !ipo.isUpcoming && !ipo.isWithdrawn).toList();
  }

  String _getDateString(int daysOffset) {
    final date = DateTime.now().add(Duration(days: daysOffset));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fallback data when API is unavailable (demo mode)
  List<IPO> _getFallbackIPOs() {
    return [
      IPO(
        symbol: 'DEMO1',
        company: 'Demo Tech Inc.',
        exchange: 'NASDAQ',
        date: DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        priceRange: '\$18-\$20',
        numberOfShares: 10000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'DEMO2',
        company: 'Future AI Corp',
        exchange: 'NYSE',
        date: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        priceRange: '\$25-\$28',
        numberOfShares: 15000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'DEMO3',
        company: 'Green Energy Solutions',
        exchange: 'NASDAQ',
        date: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        price: 22.50,
        numberOfShares: 8000000,
        status: 'priced',
      ),
    ];
  }
}
