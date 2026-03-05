// ignore_for_file: avoid_print, unused_local_variable, prefer_const_declarations
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  try {
    print('Fetching...');
    final response = await http.get(Uri.parse('https://halkarz.com/'),
        headers: {'User-Agent': 'Mozilla/5.0'});
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      final articles = document.querySelectorAll('article.index-list').take(5);

      for (var article in articles) {
        final nameElement = article.querySelector('h3.il-halka-arz-sirket a');
        final symbolElement = article.querySelector('span.il-bist-kod');
        final dateElement = article.querySelector('time');
        final statusBadge = article.querySelector('i.snc-badge');

        String company = nameElement?.text.trim() ?? '';
        String date = dateElement?.text.trim() ?? '';

        if (company.isEmpty) continue;

        bool isCompleted = false;

        if (!isCompleted && date.isNotEmpty && !date.contains('Hazırlanıyor')) {
          final lowerDate = date.toLowerCase();
          final currentYear = 2026;

          for (int y = 2020; y < currentYear; y++) {
            if (date.contains(y.toString())) {
              isCompleted = true;
              break;
            }
          }

          if (!isCompleted && date.contains(currentYear.toString())) {
            final monthNames = [
              'ocak',
              'şubat',
              'mart',
              'nisan',
              'mayıs',
              'haziran',
              'temmuz',
              'ağustos',
              'eylül',
              'ekim',
              'kasım',
              'aralık'
            ];
            final dateRegex = RegExp('(\\d+)\\s*(${monthNames.join('|')})');
            final matches = dateRegex.allMatches(lowerDate);

            if (matches.isNotEmpty) {
              final lastMatch = matches.last;
              int foundMonth = monthNames.indexOf(lastMatch.group(2)!) + 1;
              int lastDay = int.parse(lastMatch.group(1)!);
            }
          }
        }
        print('Parsed $company successfully');
      }
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
