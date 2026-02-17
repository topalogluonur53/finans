class MarketPrice {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final String? image;
  final String category; // 'crypto', 'commodity', 'currency', 'stock'

  MarketPrice({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    this.image,
    required this.category,
  });

  factory MarketPrice.fromCoinGecko(Map<String, dynamic> json, String category) {
    return MarketPrice(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChange24h: (json['price_change_24h'] ?? 0).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] ?? 0).toDouble(),
      image: json['image'],
      category: category,
    );
  }

  bool get isPositive => priceChange24h >= 0;
}
