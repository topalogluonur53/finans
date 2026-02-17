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
  SILVER_GRAM,
  CRYPTO_BTC,
  CRYPTO_ETH,
  CRYPTO_SOL,
  CURRENCY_USD,
  CURRENCY_EUR,
  STOCK,
}

enum AssetCategory {
  COMMODITY,  // Emtia
  CRYPTO,     // Kripto
  CURRENCY,   // Döviz
  STOCK,      // Borsa
}

extension AssetCategoryExt on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.COMMODITY: return 'Emtia';
      case AssetCategory.CRYPTO: return 'Kripto Para';
      case AssetCategory.CURRENCY: return 'Döviz';
      case AssetCategory.STOCK: return 'Borsa';
    }
  }
  
  String get icon {
    switch (this) {
      case AssetCategory.COMMODITY: return '🪙';
      case AssetCategory.CRYPTO: return '₿';
      case AssetCategory.CURRENCY: return '💱';
      case AssetCategory.STOCK: return '📈';
    }
  }
}

extension AssetTypeExt on AssetType {
  String get label {
    switch (this) {
      case AssetType.GOLD_GRAM: return 'Gram Altın';
      case AssetType.GOLD_QUARTER: return 'Çeyrek Altın';
      case AssetType.GOLD_HALF: return 'Yarım Altın';
      case AssetType.GOLD_FULL: return 'Tam Altın';
      case AssetType.SILVER_GRAM: return 'Gram Gümüş';
      case AssetType.CRYPTO_BTC: return 'Bitcoin (BTC)';
      case AssetType.CRYPTO_ETH: return 'Ethereum (ETH)';
      case AssetType.CRYPTO_SOL: return 'Solana (SOL)';
      case AssetType.CURRENCY_USD: return 'Amerikan Doları (USD)';
      case AssetType.CURRENCY_EUR: return 'Euro (EUR)';
      case AssetType.STOCK: return 'Hisse Senedi';
    }
  }
  
  String get symbol {
    switch (this) {
      case AssetType.GOLD_GRAM:
      case AssetType.GOLD_QUARTER:
      case AssetType.GOLD_HALF:
      case AssetType.GOLD_FULL:
        return 'GOLD';
      case AssetType.SILVER_GRAM: return 'SILVER';
      case AssetType.CRYPTO_BTC: return 'BTC';
      case AssetType.CRYPTO_ETH: return 'ETH';
      case AssetType.CRYPTO_SOL: return 'SOL';
      case AssetType.CURRENCY_USD: return 'USD';
      case AssetType.CURRENCY_EUR: return 'EUR';
      case AssetType.STOCK: return '';
    }
  }
  
  AssetCategory get category {
    switch (this) {
      case AssetType.GOLD_GRAM:
      case AssetType.GOLD_QUARTER:
      case AssetType.GOLD_HALF:
      case AssetType.GOLD_FULL:
      case AssetType.SILVER_GRAM:
        return AssetCategory.COMMODITY;
      case AssetType.CRYPTO_BTC:
      case AssetType.CRYPTO_ETH:
      case AssetType.CRYPTO_SOL:
        return AssetCategory.CRYPTO;
      case AssetType.CURRENCY_USD:
      case AssetType.CURRENCY_EUR:
        return AssetCategory.CURRENCY;
      case AssetType.STOCK:
        return AssetCategory.STOCK;
    }
  }
  
  static List<AssetType> byCategory(AssetCategory category) {
    return AssetType.values.where((type) => type.category == category).toList();
  }
}
