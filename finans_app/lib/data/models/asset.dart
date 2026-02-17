class Asset {
  final int? id;
  final String type;
  final String name;
  final String? symbol;
  final double quantity;
  final double purchasePrice;
  final DateTime purchaseDate;
  final String? notes;

  Asset({
    this.id,
    required this.type,
    required this.name,
    this.symbol,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseDate,
    this.notes,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      symbol: json['symbol'],
      quantity: double.parse(json['quantity'].toString()),
      purchasePrice: double.parse(json['purchase_price'].toString()),
      purchaseDate: DateTime.parse(json['purchase_date']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'symbol': symbol,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate.toIso8601String(),
      'notes': notes,
    };
  }
}

enum AssetType {
  GOLD_GRAM,
  GOLD_QUARTER,
  GOLD_HALF,
  GOLD_FULL,
  CRYPTO_BTC,
  CRYPTO_ETH,
  CRYPTO_SOL,
  CURRENCY_USD,
  CURRENCY_EUR,
  STOCK,
  SILVER_GRAM,
}

extension AssetTypeExt on AssetType {
  String get label {
    switch (this) {
      case AssetType.GOLD_GRAM: return 'Gram Altın';
      case AssetType.GOLD_QUARTER: return 'Çeyrek Altın';
      case AssetType.CRYPTO_BTC: return 'Bitcoin';
      case AssetType.CURRENCY_USD: return 'Dolar';
      default: return name;
    }
  }
}
