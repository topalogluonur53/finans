import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  try {
    print('Fetching...');
    final response = await http.get(
      Uri.parse('https://halkarz.com/'),
      headers: {'User-Agent': 'Mozilla/5.0'}
    );
    print('Status Code: \');
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      final articles = document.querySelectorAll('article.index-list');
      print('Found \ articles');
      for (var i = 0; i < articles.length && i < 2; i++) {
        final article = articles[i];
        final nameElement = article.querySelector('h3.il-halka-arz-sirket a');
        print('Company: \');
      }
    } else {
      print('Body: \...');
    }
  } catch (e) {
    print('Error: \');
  }
}
