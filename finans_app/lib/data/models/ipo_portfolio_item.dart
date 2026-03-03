import 'dart:convert';

class IPOPortfolioItem {
  final String symbol;
  final String company;
  final int quantity;
  final double costPrice;
  final double currentPrice;
  final bool isSold;
  final double? soldPrice;

  IPOPortfolioItem({
    required this.symbol,
    required this.company,
    required this.quantity,
    required this.costPrice,
    required this.currentPrice,
    this.isSold = false,
    this.soldPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'company': company,
      'quantity': quantity,
      'costPrice': costPrice,
      'currentPrice': currentPrice,
      'isSold': isSold,
      'soldPrice': soldPrice,
    };
  }

  factory IPOPortfolioItem.fromMap(Map<String, dynamic> map) {
    return IPOPortfolioItem(
      symbol: map['symbol'] ?? '',
      company: map['company'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      currentPrice: map['currentPrice']?.toDouble() ?? 0.0,
      isSold: map['isSold'] ?? false,
      soldPrice: map['soldPrice']?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory IPOPortfolioItem.fromJson(String source) =>
      IPOPortfolioItem.fromMap(json.decode(source));

  double get totalCost => quantity * costPrice;
  
  double get currentValue {
    if (isSold && soldPrice != null) {
      return quantity * soldPrice!;
    }
    return quantity * currentPrice;
  }

  double get profitLoss => currentValue - totalCost;

  double get profitLossPercentage {
    if (totalCost == 0) return 0;
    return (profitLoss / totalCost) * 100;
  }
}
