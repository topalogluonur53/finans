class Asset {
  final int? id;
  final String type;
  final String name;
  final String? symbol;
  final double quantity;
  final double purchasePrice;
  final DateTime purchaseDate;
  final String? notes;
  final String? tag;

  Asset({
    this.id,
    required this.type,
    required this.name,
    this.symbol,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseDate,
    this.notes,
    this.tag,
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
      tag: json['tag'],
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
      'tag': tag,
    };
  }
}

enum AssetType {
  goldGram,
  goldQuarter,
  goldHalf,
  goldFull,
  silverGram,
  platinumGram,
  palladiumGram,
  cryptoBtc,
  cryptoEth,
  cryptoSol,
  cryptoBnb,
  cryptoXrp,
  currencyUsd,
  currencyEur,
  currencyGbp,
  currencyJpy,
  currencyChf,
  stock,
}

enum AssetCategory {
  commodity, // Emtia
  crypto, // Kripto
  currency, // Döviz
  stock, // Borsa
}

extension AssetCategoryExt on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.commodity:
        return 'Emtia';
      case AssetCategory.crypto:
        return 'Kripto Para';
      case AssetCategory.currency:
        return 'Döviz';
      case AssetCategory.stock:
        return 'Borsa';
    }
  }

  String get icon {
    switch (this) {
      case AssetCategory.commodity:
        return '🪙';
      case AssetCategory.crypto:
        return '₿';
      case AssetCategory.currency:
        return '💱';
      case AssetCategory.stock:
        return '📈';
    }
  }
}

extension AssetTypeExt on AssetType {
  String get label {
    switch (this) {
      case AssetType.goldGram:
        return 'Gram Altın';
      case AssetType.goldQuarter:
        return 'Çeyrek Altın';
      case AssetType.goldHalf:
        return 'Yarım Altın';
      case AssetType.goldFull:
        return 'Tam Altın';
      case AssetType.silverGram:
        return 'Gram Gümüş';
      case AssetType.platinumGram:
        return 'Gram Platin';
      case AssetType.palladiumGram:
        return 'Gram Paladyum';
      case AssetType.cryptoBtc:
        return 'Bitcoin (BTC)';
      case AssetType.cryptoEth:
        return 'Ethereum (ETH)';
      case AssetType.cryptoSol:
        return 'Solana (SOL)';
      case AssetType.cryptoBnb:
        return 'Binance Coin (BNB)';
      case AssetType.cryptoXrp:
        return 'Ripple (XRP)';
      case AssetType.currencyUsd:
        return 'Amerikan Doları (USD)';
      case AssetType.currencyEur:
        return 'Euro (EUR)';
      case AssetType.currencyGbp:
        return 'İngiliz Sterlini (GBP)';
      case AssetType.currencyJpy:
        return 'Japon Yeni (JPY)';
      case AssetType.currencyChf:
        return 'İsviçre Frangı (CHF)';
      case AssetType.stock:
        return 'Hisse Senedi';
    }
  }

  String get backendType {
    switch (this) {
      case AssetType.goldGram: return 'GOLD_GRAM';
      case AssetType.goldQuarter: return 'GOLD_QUARTER';
      case AssetType.goldHalf: return 'GOLD_HALF';
      case AssetType.goldFull: return 'GOLD_FULL';
      case AssetType.silverGram: return 'SILVER_GRAM';
      case AssetType.platinumGram: return 'PLATINUM_GRAM';
      case AssetType.palladiumGram: return 'PALLADIUM_GRAM';
      case AssetType.cryptoBtc: return 'CRYPTO_BTC';
      case AssetType.cryptoEth: return 'CRYPTO_ETH';
      case AssetType.cryptoSol: return 'CRYPTO_SOL';
      case AssetType.cryptoBnb: return 'CRYPTO_BNB';
      case AssetType.cryptoXrp: return 'CRYPTO_XRP';
      case AssetType.currencyUsd: return 'CURRENCY_USD';
      case AssetType.currencyEur: return 'CURRENCY_EUR';
      case AssetType.currencyGbp: return 'CURRENCY_GBP';
      case AssetType.currencyJpy: return 'CURRENCY_JPY';
      case AssetType.currencyChf: return 'CURRENCY_CHF';
      case AssetType.stock: return 'STOCK';
    }
  }

  String get symbol {
    switch (this) {
      case AssetType.goldGram:
        return 'GRAM-ALTIN';
      case AssetType.goldQuarter:
        return 'CEYREK-ALTIN';
      case AssetType.goldHalf:
        return 'YARIM-ALTIN';
      case AssetType.goldFull:
        return 'TAM-ALTIN';
      case AssetType.silverGram:
        return 'GRAM-GUMUS';
      case AssetType.platinumGram:
        return 'GRAM-PLATIN';
      case AssetType.palladiumGram:
        return 'GRAM-PALADYUM';
      case AssetType.cryptoBtc:
        return 'BTCUSDT';
      case AssetType.cryptoEth:
        return 'ETHUSDT';
      case AssetType.cryptoSol:
        return 'SOLUSDT';
      case AssetType.cryptoBnb:
        return 'BNBUSDT';
      case AssetType.cryptoXrp:
        return 'XRPUSDT';
      case AssetType.currencyUsd:
        return 'USDTRY=X';
      case AssetType.currencyEur:
        return 'EURTRY=X';
      case AssetType.currencyGbp:
        return 'GBPTRY=X';
      case AssetType.currencyJpy:
        return 'JPYTRY=X';
      case AssetType.currencyChf:
        return 'CHFTRY=X';
      case AssetType.stock:
        return '';
    }
  }

  // Multiplier to convert market unit to asset unit
  // If we use GRAM-ALTIN (TRY), multiplier is 1.0
  double get unitMultiplier {
    return 1.0;
  }

  bool get isUsdBased {
    final cat = category;
    // Binance data is in USDT
    return cat == AssetCategory.crypto;
  }

  AssetCategory get category {
    switch (this) {
      case AssetType.goldGram:
      case AssetType.goldQuarter:
      case AssetType.goldHalf:
      case AssetType.goldFull:
      case AssetType.silverGram:
      case AssetType.platinumGram:
      case AssetType.palladiumGram:
        return AssetCategory.commodity;
      case AssetType.cryptoBtc:
      case AssetType.cryptoEth:
      case AssetType.cryptoSol:
      case AssetType.cryptoBnb:
      case AssetType.cryptoXrp:
        return AssetCategory.crypto;
      case AssetType.currencyUsd:
      case AssetType.currencyEur:
      case AssetType.currencyGbp:
      case AssetType.currencyJpy:
      case AssetType.currencyChf:
        return AssetCategory.currency;
      case AssetType.stock:
        return AssetCategory.stock;
    }
  }

  static List<AssetType> byCategory(AssetCategory category) {
    return AssetType.values.where((type) => type.category == category).toList();
  }
}
