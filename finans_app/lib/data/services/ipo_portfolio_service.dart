import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/data/models/ipo_portfolio_item.dart';

class IPOPortfolioService {
  static const String _storageKey = 'ipo_portfolio_items';

  Future<List<IPOPortfolioItem>> getPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? itemsString = prefs.getStringList(_storageKey);
    
    if (itemsString == null) {
      return [];
    }

    return itemsString
        .map((item) => IPOPortfolioItem.fromJson(item))
        .toList();
  }

  Future<void> savePortfolio(List<IPOPortfolioItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> itemsString =
        items.map((item) => item.toJson()).toList();
    await prefs.setStringList(_storageKey, itemsString);
  }

  Future<void> addParticipant(IPOPortfolioItem item) async {
    final items = await getPortfolio();
    
    // Check if already exists
    final index = items.indexWhere((i) => i.symbol == item.symbol);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    
    await savePortfolio(items);
  }
  
  Future<void> removeParticipant(String symbol) async {
    final items = await getPortfolio();
    items.removeWhere((item) => item.symbol == symbol);
    await savePortfolio(items);
  }
}
