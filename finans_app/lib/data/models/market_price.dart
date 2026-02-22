class MarketPrice {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final double? openPrice;
  final double? dayHigh;
  final double? dayLow;
  final int? volume;
  final bool isIndex;
  final String? parentSymbol;
  final String category; // 'commodity', 'stock', 'currency', 'crypto'
  final String? imageUrl;

  MarketPrice({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    this.openPrice,
    this.dayHigh,
    this.dayLow,
    this.volume,
    this.isIndex = false,
    this.parentSymbol,
    required this.category,
    this.imageUrl,
  });

  static const Map<String, String> _prettyNames = {
    'GC=F': 'Altın (Ons)',
    'SI=F': 'Gümüş (Ons)',
    'PL=F': 'Platin (Ons)',
    'PA=F': 'Paladyum (Ons)',
    'BZ=F': 'Brent Petrol',
    'CL=F': 'WTI Petrol',
    'NG=F': 'Doğalgaz',
    'HG=F': 'Bakır',
    'USDTRY=X': 'Dolar/TL',
    'EURTRY=X': 'Euro/TL',
    'EURUSD=X': 'Euro/Dolar',
    'GBPUSD=X': 'Sterlin/Dolar',
    'GBPTRY=X': 'Sterlin/TL',
    'JPYTRY=X': 'Yen/TL',
    'XU100.IS': 'BIST 100',
    '^GSPC': 'S&P 500',
    '^IXIC': 'NASDAQ',
    '^DJI': 'Dow Jones',
    '^FTSE': 'FTSE 100',
    '^GDAXI': 'DAX Performance',
    'GRAM-ALTIN': 'Gram Altın',
    'GRAM-GUMUS': 'Gram Gümüş',
    'GRAM-PLATIN': 'Gram Platin',
    'GRAM-PALADYUM': 'Gram Paladyum',
    'CEYREK-ALTIN': 'Çeyrek Altın',
    'YARIM-ALTIN': 'Yarım Altın',
    'TAM-ALTIN': 'Tam Altın',
    'CUMHURIYET-ALTIN': 'Cumhuriyet Altını',
    '22-AYAR-BILEZIK': '22 Ayar Bilezik (gr)',
  };

  factory MarketPrice.fromJson(Map<String, dynamic> json, String category) {
    final symbol = json['symbol']?.toString() ?? '';
    String name = json['name']?.toString() ?? '';

    // If name is empty, null, or same as symbol, try to find a pretty name
    if (name.isEmpty || name == 'null' || name == symbol) {
      name = _prettyNames[symbol.toUpperCase()] ??
          (name == 'null' || name.isEmpty ? symbol : name);
    }

    return MarketPrice(
      id: json['id']?.toString() ?? symbol,
      symbol: symbol,
      name: name,
      currentPrice: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      priceChange24h:
          double.tryParse(json['price_change_24h']?.toString() ?? '0') ?? 0.0,
      priceChangePercentage24h:
          double.tryParse(json['change_percent_24h']?.toString() ?? '0') ?? 0.0,
      openPrice: json['open_price'] != null
          ? double.tryParse(json['open_price'].toString())
          : null,
      dayHigh: json['day_high'] != null
          ? double.tryParse(json['day_high'].toString())
          : null,
      dayLow: json['day_low'] != null
          ? double.tryParse(json['day_low'].toString())
          : null,
      volume: json['volume'] != null
          ? int.tryParse(json['volume'].toString())
          : null,
      isIndex: json['is_index'] == true,
      parentSymbol: json['parent_symbol'],
      category: category,
      imageUrl: json['image_url'],
    );
  }

  factory MarketPrice.fromCoinGecko(
      Map<String, dynamic> json, String category) {
    return MarketPrice(
      id: json['id']?.toString() ?? '',
      symbol: (json['symbol']?.toString() ?? '').toUpperCase(),
      name: json['name']?.toString() ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      dayHigh: (json['high_24h'] as num?)?.toDouble(),
      dayLow: (json['low_24h'] as num?)?.toDouble(),
      volume: (json['total_volume'] as num?)?.toInt(),
      category: category,
      imageUrl: json['image']?.toString(),
    );
  }

  bool get isPositive => priceChange24h >= 0;
}
