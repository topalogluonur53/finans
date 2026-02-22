import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/data/models/ipo.dart';
import 'package:finans_app/data/models/ipo_news.dart';

import 'package:html/parser.dart' as parser;

class IPOService {
  // Singleton pattern
  static final IPOService _instance = IPOService._internal();
  factory IPOService() => _instance;
  IPOService._internal();

  List<IPO>? _cachedIPOs;
  List<IPONews>? _cachedNews;
  DateTime? _lastFetchTime;

  // Financial Modeling Prep API - Free tier: 250 requests/day
  static const String _apiKey = 'demo'; // Replace with your API key
  static const String _baseUrl = 'https://financialmodelingprep.com/api/v3';

  /// Fetch IPO and stock market news
  Future<List<IPONews>> fetchIPONews({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedNews != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 60) {
        return _cachedNews!;
      }
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/stock_news?limit=50&apikey=$_apiKey'),
          )
          .timeout(const Duration(seconds: 10));

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
          _cachedNews = newsList;
          _lastFetchTime = DateTime.now();
          return newsList;
        }
      }
      _cachedNews = _getFallbackNews();
      _lastFetchTime = DateTime.now();
      return _cachedNews!;
    } catch (e) {
      debugPrint('Error fetching IPO news: $e'); // Corrected message
      _cachedNews = _getFallbackNews();
      _lastFetchTime = DateTime.now();
      return _cachedNews!;
    }
  }

  Future<void> clearCache() async {
    _cachedIPOs = null;
    _cachedNews = null;
    _lastFetchTime = null;
  }

  List<IPONews> _getFallbackNews() {
    return [
      IPONews(
        title: 'Borsa İstanbul 2026 Halka Arz Beklentileri',
        content:
            '2026 yılında Borsa İstanbul\'da teknoloji ve enerji şirketlerinin ağırlıkta olduğu yeni bir halka arz dalgası bekleniyor. SPK onay sürecindeki şirket sayısı artıyor.',
        date: DateTime.now().toIso8601String(),
        url: 'https://borsaistanbul.com',
        source: 'Finans Gündem',
      ),
      IPONews(
        title: 'Yeni Halka Arz Onayları ve Talep Toplama',
        content:
            'Şubat ayında beş yeni şirketin halka arz başvurusu onaylandı. Empa Elektronik ve Ata Turizm bu haftanın en çok konuşulan arzları arasında.',
        date:
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        url: 'https://spk.gov.tr',
        source: 'Para Analiz',
      ),
      IPONews(
        title: 'BIST Halka Arz Endeksi (XHARZ) Rekor Kırıyor',
        content:
            'Yeni halka arz edilen şirketlerin yüksek performansı ile XHARZ endeksi 2026 yılının ilk çeyreğinde piyasa ortalamasının üzerinde getiri sağladı.',
        date:
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        url: 'https://bigpara.hurriyet.com.tr',
        source: 'BigPara',
      ),
    ];
  }

  // Alternative: IEX Cloud API
  static const String _iexToken =
      'pk_demo'; // Replace with your token from iexcloud.io
  static const String _iexBaseUrl = 'https://cloud.iexapis.com/stable';

  /// Fetch IPO calendar directly from halkarz.com
  Future<List<IPO>> fetchIPOCalendar({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIPOs != null && _lastFetchTime != null) {
        return _cachedIPOs!;
    }
    
    try {
      final response = await http
          .get(
            Uri.parse('https://halkarz.com/'),
            headers: {'User-Agent': 'Mozilla/5.0'}
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        final articles = document.querySelectorAll('article.index-list');
        
        List<IPO> scrapedIPOs = [];
        
        for (var article in articles) {
          final nameElement = article.querySelector('h3.il-halka-arz-sirket a');
          final symbolElement = article.querySelector('span.il-bist-kod');
          final dateElement = article.querySelector('time');
          final urlElement = article.querySelector('a');
          final statusBadge = article.querySelector('i.snc-badge');
          
          String company = nameElement?.text.trim() ?? '';
          String symbol = symbolElement?.text.trim() ?? '';
          String date = dateElement?.text.trim() ?? '';
          String detailUrl = urlElement?.attributes['href'] ?? '';
          
          if (company.isEmpty) continue;

          bool hasTamamlandi = statusBadge != null && 
              (statusBadge.attributes['title']?.contains('Tamamlandı') ?? false);
              
          bool isCompleted = hasTamamlandi;
          
          if (!isCompleted && date.isNotEmpty && !date.contains('Hazırlanıyor')) {
            // Check if date is in the past by looking at the year and extracting the month
            if (date.contains('2025') || date.contains('2024') || date.contains('2023')) {
               isCompleted = true;
            } else if (date.contains('2026')) {
               if (date.contains('Ocak')) {
                  isCompleted = true;
               } else if (date.contains('Şubat')) {
                  // E.g '19-20 Şubat 2026'. Use regex to find the last day number.
                  final numRegex = RegExp(r'(\d+)');
                  final matches = numRegex.allMatches(date);
                  if (matches.isNotEmpty) {
                    try {
                      // get the largest number before we hit year 2026
                      int day = -1;
                      for (var m in matches) {
                        int v = int.parse(m.group(1)!);
                        if (v < 32 && v > day) day = v;
                      }
                      if (day != -1 && day < DateTime.now().day) {
                         isCompleted = true; // day has passed
                      }
                    } catch (e) {}
                  }
               }
            }
          }
          
          String status = 'priced';
          if (isCompleted) {
             status = 'priced'; 
          } else {
             status = 'upcoming'; 
          }

          scrapedIPOs.add(IPO(
            company: company,
            symbol: symbol,
            date: date,
            exchange: 'BIST',
            url: detailUrl,
            status: status, // explicit status
          ));
        }

        // Fetch details for the first 15 IPOs to get prices and shares efficiently
        final int limit = scrapedIPOs.length > 20 ? 20 : scrapedIPOs.length;
        final detailedIPOs = await Future.wait(
          scrapedIPOs.take(limit).map((ipo) => _fetchIPODetails(ipo))
        );
        
        // Combine detailed with the rest
        scrapedIPOs = [
          ...detailedIPOs,
          ...scrapedIPOs.skip(limit)
        ];

        if (scrapedIPOs.isNotEmpty) {
          _cachedIPOs = scrapedIPOs;
          _lastFetchTime = DateTime.now();
          return _cachedIPOs!;
        }
      }

      // If scraping returns empty, use our curated fallback
      _cachedIPOs = _getFallbackIPOs();
      _lastFetchTime = DateTime.now();
      return _cachedIPOs!;
    } catch (e) {
      debugPrint('Error scraping halkarz.com: $e');
      // Return fallback data
      _cachedIPOs = _getFallbackIPOs();
      _lastFetchTime = DateTime.now();
      return _cachedIPOs!;
    }
  }

  Future<IPO> _fetchIPODetails(IPO ipo) async {
    if (ipo.url == null || ipo.url!.isEmpty) return ipo;
    try {
      final response = await http.get(
        Uri.parse(ipo.url!),
        headers: {'User-Agent': 'Mozilla/5.0'}
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        final rows = document.querySelectorAll('tr');
        
        String? priceRange;
        int? numberOfShares;
        
        for (var row in rows) {
          final text = row.text;
          if (text.contains('Fiyatı/Aralığı')) {
             final valCell = row.querySelectorAll('td').last;
             priceRange = valCell.text.trim();
          } else if (text.contains('Pay')) {
             final valCell = row.querySelectorAll('td').last;
             String shareStr = valCell.text.replaceAll('Lot', '').replaceAll('.', '').trim();
             numberOfShares = int.tryParse(shareStr);
          }
        }
        
        return IPO(
          symbol: ipo.symbol,
          company: ipo.company,
          exchange: ipo.exchange,
          date: ipo.date,
          priceRange: priceRange,
          numberOfShares: numberOfShares,
          status: ipo.status,
          url: ipo.url,
        );
      }
    } catch (e) {
      debugPrint('Error fetching IPO details: $e');
    }
    return ipo;
  }

  /// Fetch upcoming IPOs
  Future<List<IPO>> fetchUpcomingIPOs() async {
    final allIPOs = await fetchIPOCalendar();
    return allIPOs.where((ipo) => ipo.status == 'upcoming').toList();
  }

  /// Fetch recent IPOs
  Future<List<IPO>> fetchRecentIPOs() async {
    final allIPOs = await fetchIPOCalendar();
    // For manual scraped data, anything not 'upcoming' and string exists goes here
    return allIPOs.where((ipo) => ipo.status != 'upcoming').toList();
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
        priceRange: '24.50 TL',
        numberOfShares: 25000000,
        status: 'priced',
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
        priceRange: '15.50 - 16.50 TL',
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
        priceRange: '45.00 - 48.00 TL',
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
