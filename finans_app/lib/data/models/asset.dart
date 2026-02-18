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
  PLATINUM_GRAM,
  PALLADIUM_GRAM,
  CRYPTO_BTC,
  CRYPTO_ETH,
  CRYPTO_SOL,
  CRYPTO_BNB,
  CRYPTO_XRP,
  CURRENCY_USD,
  CURRENCY_EUR,
  CURRENCY_GBP,
  CURRENCY_JPY,
  CURRENCY_CHF,
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
      case AssetType.PLATINUM_GRAM: return 'Gram Platin';
      case AssetType.PALLADIUM_GRAM: return 'Gram Paladyum';
      case AssetType.CRYPTO_BTC: return 'Bitcoin (BTC)';
      case AssetType.CRYPTO_ETH: return 'Ethereum (ETH)';
      case AssetType.CRYPTO_SOL: return 'Solana (SOL)';
      case AssetType.CRYPTO_BNB: return 'Binance Coin (BNB)';
      case AssetType.CRYPTO_XRP: return 'Ripple (XRP)';
      case AssetType.CURRENCY_USD: return 'Amerikan Doları (USD)';
      case AssetType.CURRENCY_EUR: return 'Euro (EUR)';
      case AssetType.CURRENCY_GBP: return 'İngiliz Sterlini (GBP)';
      case AssetType.CURRENCY_JPY: return 'Japon Yeni (JPY)';
      case AssetType.CURRENCY_CHF: return 'İsviçre Frangı (CHF)';
      case AssetType.STOCK: return 'Hisse Senedi';
    }
  }
  
  String get symbol {
    switch (this) {
      case AssetType.GOLD_GRAM:
      case AssetType.GOLD_QUARTER:
      case AssetType.GOLD_HALF:
      case AssetType.GOLD_FULL:
        return 'PAXG'; // Tokenized Gold
      case AssetType.SILVER_GRAM: return 'SILVER';
      case AssetType.PLATINUM_GRAM: return 'PLATINUM';
      case AssetType.PALLADIUM_GRAM: return 'PALLADIUM';
      case AssetType.CRYPTO_BTC: return 'BTC';
      case AssetType.CRYPTO_ETH: return 'ETH';
      case AssetType.CRYPTO_SOL: return 'SOL';
      case AssetType.CRYPTO_BNB: return 'BNB';
      case AssetType.CRYPTO_XRP: return 'XRP';
      case AssetType.CURRENCY_USD: return 'USD/TRY';
      case AssetType.CURRENCY_EUR: return 'EUR/TRY';
      case AssetType.CURRENCY_GBP: return 'GBP/TRY';
      case AssetType.CURRENCY_JPY: return 'JPY/TRY';
      case AssetType.CURRENCY_CHF: return 'CHF/TRY';
      case AssetType.STOCK: return '';
    }
  }

  // Multiplier to convert market unit to asset unit
  // e.g. PAXG is per ounce, we want per gram: 1/31.1035
  double get unitMultiplier {
    switch (this) {
      case AssetType.GOLD_GRAM: return 1.0 / 31.1035;
      case AssetType.GOLD_QUARTER: return 1.75 / 31.1035; // approx gram weight? No, let's keep it simple for now or research. 
      // Actually per gram is better.
      case AssetType.GOLD_HALF: return 3.5 / 31.1035;
      case AssetType.GOLD_FULL: return 7.0 / 31.1035;
      case AssetType.SILVER_GRAM: return 1.0 / 31.1035;
      default: return 1.0;
    }
  }

  bool get isUsdBased {
    final cat = category;
    return cat == AssetCategory.CRYPTO || cat == AssetCategory.COMMODITY;
  }
  
  AssetCategory get category {
    switch (this) {
      case AssetType.GOLD_GRAM:
      case AssetType.GOLD_QUARTER:
      case AssetType.GOLD_HALF:
      case AssetType.GOLD_FULL:
      case AssetType.SILVER_GRAM:
      case AssetType.PLATINUM_GRAM:
      case AssetType.PALLADIUM_GRAM:
        return AssetCategory.COMMODITY;
      case AssetType.CRYPTO_BTC:
      case AssetType.CRYPTO_ETH:
      case AssetType.CRYPTO_SOL:
      case AssetType.CRYPTO_BNB:
      case AssetType.CRYPTO_XRP:
        return AssetCategory.CRYPTO;
      case AssetType.CURRENCY_USD:
      case AssetType.CURRENCY_EUR:
      case AssetType.CURRENCY_GBP:
      case AssetType.CURRENCY_JPY:
      case AssetType.CURRENCY_CHF:
        return AssetCategory.CURRENCY;
      case AssetType.STOCK:
        return AssetCategory.STOCK;
    }
  }
  
  static List<AssetType> byCategory(AssetCategory category) {
    return AssetType.values.where((type) => type.category == category).toList();
  }
}
