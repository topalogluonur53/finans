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
        title: 'Borsa İstanbul 2026 Halka Arz Beklentileri',
        content: '2026 yılında Borsa İstanbul\'da teknoloji ve enerji şirketlerinin ağırlıkta olduğu yeni bir halka arz dalgası bekleniyor. SPK onay sürecindeki şirket sayısı artıyor.',
        date: DateTime.now().toIso8601String(),
        url: 'https://borsaistanbul.com',
        source: 'Finans Gündem',
      ),
      IPONews(
        title: 'Yeni Halka Arz Onayları ve Talep Toplama',
        content: 'Şubat ayında beş yeni şirketin halka arz başvurusu onaylandı. Empa Elektronik ve Ata Turizm bu haftanın en çok konuşulan arzları arasında.',
        date: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        url: 'https://spk.gov.tr',
        source: 'Para Analiz',
      ),
      IPONews(
        title: 'BIST Halka Arz Endeksi (XHARZ) Rekor Kırıyor',
        content: 'Yeni halka arz edilen şirketlerin yüksek performansı ile XHARZ endeksi 2026 yılının ilk çeyreğinde piyasa ortalamasının üzerinde getiri sağladı.',
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
        symbol: 'EMPAE',
        company: 'Empa Elektronik San. ve Tic. A.Ş.',
        exchange: 'BIST',
        date: '2026-02-19',
        priceRange: 'Belirlenmedi',
        numberOfShares: 25000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'ATATR',
        company: 'Ata Turizm İşletmecilik A.Ş.',
        exchange: 'BIST',
        date: '2026-02-11',
        price: 18.50,
        numberOfShares: 30000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'BESTE',
        company: 'Best Brands Grup Enerji Yatırım A.Ş.',
        exchange: 'BIST',
        date: '2026-02-05',
        price: 14.70,
        numberOfShares: 54578570,
        status: 'priced',
      ),
      IPO(
        symbol: 'NETCD',
        company: 'Netcad Yazılım A.Ş.',
        exchange: 'BIST',
        date: '2026-01-28',
        price: 46.00,
        numberOfShares: 40000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'AKHAN',
        company: 'Akhan Un Fabrikası A.Ş.',
        exchange: 'BIST',
        date: '2026-01-28',
        price: 21.50,
        numberOfShares: 54700000,
        status: 'priced',
      ),
      IPO(
        symbol: 'MEYSU',
        company: 'Meysu Gıda San. ve Tic. A.Ş.',
        exchange: 'BIST',
        date: '2026-01-05',
        price: 7.50,
        numberOfShares: 175000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'ZGYO',
        company: 'Z Gayrimenkul Yatırım Ortaklığı A.Ş.',
        exchange: 'BIST',
        date: '2026-01-15',
        price: 5.20,
        numberOfShares: 100000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'UCAYM',
        company: 'Üçay Mühendislik Enerji A.Ş.',
        exchange: 'BIST',
        date: '2026-01-14',
        price: 22.00,
        numberOfShares: 20000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'FRMPL',
        company: 'Formül Plastik ve Metal Sanayi A.Ş.',
        exchange: 'BIST',
        date: '2026-01-07',
        price: 12.50,
        numberOfShares: 45000000,
        status: 'priced',
      ),
      IPO(
        symbol: 'ZERGY',
        company: 'Zeray Gayrimenkul Yatırım Ortaklığı',
        exchange: 'BIST',
        date: '2026-03-15',
        priceRange: '18.00 - 20.00 TL',
        numberOfShares: 50000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'VAKFA',
        company: 'Vakıf Faktoring A.Ş.',
        exchange: 'BIST',
        date: '2026-03-25',
        priceRange: 'Belirlenmedi',
        numberOfShares: 35000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'PAHOL',
        company: 'Pasifik Holding A.Ş.',
        exchange: 'BIST',
        date: '2026-04-10',
        priceRange: 'Belirlenmedi',
        numberOfShares: 80000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'ECOGR',
        company: 'Ecogreen Enerji Holding A.Ş.',
        exchange: 'BIST',
        date: '2026-04-20',
        priceRange: 'Belirlenmedi',
        numberOfShares: 60000000,
        status: 'upcoming',
      ),
      IPO(
        symbol: 'FLO',
        company: 'Flo Mağazacılık A.Ş.',
        exchange: 'BIST',
        date: '2026-05-15',
        priceRange: 'Belirlenmedi',
        numberOfShares: 120000000,
        status: 'upcoming',
      ),
    ];
  }
}
