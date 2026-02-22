import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import 'package:html/dom.dart';

void main() async {
  print("Start Extraction");
  final url = Uri.parse('https://halkarz.com/');
  final response = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
  
  if (response.statusCode == 200) {
    var document = parser.parse(response.body);
    final articles = document.querySelectorAll('article.index-list');
    
    List<Map<String, dynamic>> ipos = [];
    
    for (var article in articles) {
      final nameElement = article.querySelector('h3.il-halka-arz-sirket a');
      final symbolElement = article.querySelector('span.il-bist-kod');
      final dateElement = article.querySelector('time');
      final urlElement = article.querySelector('a');
      final statusBadge = article.querySelector('i.snc-badge');
      final isNewBadge = article.querySelector('div.il-new');
      
      String company = nameElement?.text.trim() ?? '';
      String symbol = symbolElement?.text.trim() ?? '';
      String date = dateElement?.text.trim() ?? '';
      String detailUrl = urlElement?.attributes['href'] ?? '';
      
      bool isCompleted = statusBadge != null && 
          (statusBadge.attributes['title']?.contains('Tamamlandı') ?? false);
      
      // Additional check for Cancelled or Delayed
      bool isWithdrawn = false;
      bool isPriced = isCompleted;
      
      if (!isPriced && date.isNotEmpty && !date.contains('Hazırlanıyor')) {
         // if it has a specific date it could be priced or upcoming
         isPriced = true; // Most dated ones are priced and ready
      }
      
      ipos.add({
        'company': company,
        'symbol': symbol,
        'date': date,
        'url': detailUrl,
        'isPriced': isPriced,
        'isCompleted': isCompleted
      });
    }

    print('Found ${ipos.length} ipos. Example 1:');
    if (ipos.isNotEmpty) {
      print(ipos[2]);
    }
  } else {
    print("Error ${response.statusCode}");
  }
}
