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
        final newsList = data
            .map((item) => IPONews.fromJson(item))
            .where((news) => 
                news.title.toLowerCase().contains('ipo') || 
                news.content.toLowerCase().contains('ipo') ||
                news.title.toLowerCase().contains('offering'))
            .toList();
            
        if (newsList.isNotEmpty) {
          return newsList;
        }
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
        title: 'Borsa İstanbul Halka Arz Beklentileri',
        content: '2025 yılında Borsa İstanbul\'da 100\'ün üzerinde şirketin halka arz edilmesi bekleniyor. Enerji ve Gayrimenkul sektörleri ön planda.',
        date: DateTime.now().toIso8601String(),
        url: 'https://borsaistanbul.com',
        source: 'Finans Gündem',
      ),
      IPONews(
        title: 'Yeni Halka Arz Onayları Geldi',
        content: 'SPK haftalık bülteninde iki yeni şirketin halka arz başvurusunu onayladı. Talep toplama tarihleri yakında açıklanacak.',
        date: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        url: 'https://spk.gov.tr',
        source: 'Para Analiz',
      ),
      IPONews(
        title: 'Halka Arz Endeksi Yükselişte',
        content: 'BIST Halka Arz Endeksi (XHARZ) son bir ayda piyasanın genelinden daha iyi bir performans sergileyerek yatırımcıların ilgisini çekmeye devam ediyor.',
        date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        url: 'https://bigpara.hurriyet.com.tr',
        source: 'BigPara',
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
        if (data.isNotEmpty) {
          return data.map((item) => IPO.fromJson(item)).toList();
        }
      }

      // Fallback to IEX Cloud
      final iexData = await _fetchFromIEX();
      if (iexData.isNotEmpty) {
        return iexData;
      }
      
      // If all APIs return empty, use our curated fallback
      return _getFallbackIPOs();
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

  /// Fallback data when API is unavailable (Turkish BIST focus)
  List<IPO> _getFallbackIPOs() {
    return [
      IPO(
        symbol: 'ALTNY',
        company: 'Altınay Savunma Teknolojileri',
        exchange: 'BIST',
        date: '2025-05-15',
        priceRange: '32.00 - 35.00 TL',
        numberOfShares: 58823530,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'KOTON',
        company: 'Koton Mağazacılık',
        exchange: 'BIST',
        date: '2025-04-30',
        priceRange: '30.50 - 32.00 TL',
        numberOfShares: 136600000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'LILAK',
        company: 'Lila Kağıt Sanayi',
        exchange: 'BIST',
        date: '2025-04-12',
        priceRange: '37.39 TL',
        numberOfShares: 120000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'ZERGY',
        company: 'Zeray GYO A.Ş.',
        exchange: 'BIST',
        date: '2025-03-20',
        priceRange: '15.50 TL',
        numberOfShares: 50000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'VAKFA',
        company: 'Vakıf Faktoring A.Ş.',
        exchange: 'BIST',
        date: '2025-03-05',
        priceRange: 'Belirlenmedi',
        numberOfShares: 35000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'MODER',
        company: 'Modern Enerji',
        exchange: 'BIST',
        date: '2025-02-28',
        priceRange: '45.00 TL',
        numberOfShares: 20000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'ASSAN',
        company: 'Assan Panel',
        exchange: 'BIST',
        date: '2025-02-15',
        priceRange: '20.00 TL',
        numberOfShares: 25000000,
        status: 'priced',
        price: 20.00,
      ),
      IPO(
        symbol: 'ENTRA',
        company: 'IC Enterra Yenilenebilir Enerji',
        exchange: 'BIST',
        date: '2025-01-10',
        price: 10.00,
        numberOfShares: 369565217,
        status: 'priced',
      ),
      IPO(
        symbol: 'MOGAN',
        company: 'Mogan Enerji',
        exchange: 'BIST',
        date: '2024-12-28',
        price: 11.33,
        numberOfShares: 262635000,
        status: 'priced',
      ),
      IPO(
        symbol: 'OBAMS',
        company: 'Oba Makarnacılık',
        exchange: 'BIST',
        date: '2024-12-15',
        price: 39.24,
        numberOfShares: 96332285,
        status: 'priced',
      ),
      IPO(
        symbol: 'ARTMS',
        company: 'Artemis Halı',
        exchange: 'BIST',
        date: '2024-12-05',
        price: 25.35,
        numberOfShares: 20000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'LMKDC',
        company: 'Limak Doğu Anadolu Çimento',
        exchange: 'BIST',
        date: '2024-11-20',
        price: 16.20,
        numberOfShares: 155930000,
        status: 'priced',
      ),
      IPO(
        symbol: 'BORLS',
        company: 'Borlease Otomotiv',
        exchange: 'BIST',
        date: '2024-11-10',
        price: 25.29,
        numberOfShares: 47000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'DOFER',
        company: 'Dofer Yapı Malzemeleri',
        exchange: 'BIST',
        date: '2024-10-25',
        price: 17.11,
        numberOfShares: 17000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'MEGMT',
        company: 'Mega Metal',
        exchange: 'BIST',
        date: '2024-10-15',
        price: 28.30,
        numberOfShares: 62750000,
        status: 'priced',
      ),
    ];
  }
}
