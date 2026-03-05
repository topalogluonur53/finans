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
    return [];
  }

  // Alternative: IEX Cloud API

  /// Fetch IPO calendar directly from halkarz.com
  Future<List<IPO>> fetchIPOCalendar({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIPOs != null && _lastFetchTime != null) {
      return _cachedIPOs!;
    }

    try {
      final response = await http
          .get(
            Uri.parse('https://halkarz.com/'),
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'}
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
              ((statusBadge.attributes['title']?.contains('Tamamlandı') ?? false) ||
               (statusBadge.attributes['title']?.contains('Sonuçları') ?? false) ||
               (statusBadge.attributes['title']?.contains('İşlem') ?? false));
              
          bool isCompleted = hasTamamlandi;
          
          if (!isCompleted && date.isNotEmpty && !date.contains('Hazırlanıyor')) {
            final lowerDate = date.toLowerCase();
            final now = DateTime.now();
            final currentYear = now.year;
            
            // Check past years
            for (int y = 2020; y < currentYear; y++) {
               if (date.contains(y.toString())) {
                  isCompleted = true;
                  break;
               }
            }
            
            // For current year
            if (!isCompleted && date.contains(currentYear.toString())) {
               final monthNames = ['ocak', 'şubat', 'mart', 'nisan', 'mayıs', 'haziran', 'temmuz', 'ağustos', 'eylül', 'ekim', 'kasım', 'aralık'];
               final dateRegex = RegExp(r'(\d+)\s*(' + monthNames.join('|') + ')');
               final matches = dateRegex.allMatches(lowerDate);
               
               if (matches.isNotEmpty) {
                 final lastMatch = matches.last;
                 int foundMonth = monthNames.indexOf(lastMatch.group(2)!) + 1;
                 int lastDay = int.parse(lastMatch.group(1)!);
                 
                 if (foundMonth < now.month) {
                    isCompleted = true;
                 } else if (foundMonth == now.month) {
                    if (lastDay < now.day) {
                       isCompleted = true;
                    }
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
            scrapedIPOs.take(limit).map((ipo) => _fetchIPODetails(ipo)));

        // Combine detailed with the rest
        scrapedIPOs = [...detailedIPOs, ...scrapedIPOs.skip(limit)];

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
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'}
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
            String shareStr =
                valCell.text.replaceAll('Lot', '').replaceAll('.', '').trim();
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

  /// Fallback data when API is unavailable (Turkish BIST focus)
  List<IPO> _getFallbackIPOs() {
    return [];
  }
}
