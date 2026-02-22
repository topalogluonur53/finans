class IPO {
  final String symbol;
  final String company;
  final String exchange;
  final String? date;
  final double? price;
  final String? priceRange;
  final int? numberOfShares;
  final String? status;
  final String? url;

  IPO({
    required this.symbol,
    required this.company,
    required this.exchange,
    this.date,
    this.price,
    this.priceRange,
    this.numberOfShares,
    this.status,
    this.url,
  });

  factory IPO.fromJson(Map<String, dynamic> json) {
    return IPO(
      symbol: json['symbol'] ?? '',
      company: json['company'] ?? json['name'] ?? '',
      exchange: json['exchange'] ?? '',
      date: json['date'] ?? json['expectedDate'],
      priceRange: json['priceRange'],
      numberOfShares: json['numberOfShares'],
      price: json['price']?.toDouble(),
      status: json['status'],
      url: json['url'],
    );
  }

  bool get isUpcoming {
    if (status?.toLowerCase() == 'upcoming') return true;
    return false;
  }
  
  bool get isPriced => status?.toLowerCase() == 'priced';
  
  bool get isWithdrawn => status?.toLowerCase() == 'withdrawn';

  String get statusLabel {
    if (isWithdrawn) return 'İptal Edildi';
    if (isPriced) return 'Fiyatlandı';
    if (isUpcoming) return 'Yaklaşan';
    return 'Bilinmiyor';
  }

  String get displayPrice {
    if (price != null) {
      return '${(price! / 1).toStringAsFixed(2)} TL';
    }
    return 'Belirlenmedi';
  }

  String get displayDate {
    if (date != null && date!.isNotEmpty) {
      if (date!.contains('-') && date!.split('-').length == 3 && date!.length == 10) {
          // ISO format
          final parts = date!.split('-');
          return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
      return date!; // It's probably already Turkish format from halkarz
    }
    return 'Açıklanmadı';
  }
}
