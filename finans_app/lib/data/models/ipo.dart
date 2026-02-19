class IPO {
  final String symbol;
  final String company;
  final String exchange;
  final String? date;
  final String? priceRange;
  final int? numberOfShares;
  final double? price;
  final String? status; // 'upcoming', 'priced', 'withdrawn'
  final String? url;

  IPO({
    required this.symbol,
    required this.company,
    required this.exchange,
    this.date,
    this.priceRange,
    this.numberOfShares,
    this.price,
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
    if (date != null) {
      final dt = DateTime.tryParse(date!);
      if (dt != null && dt.isAfter(DateTime.now())) return true;
    }
    return false;
  }
  
  bool get isPriced => status?.toLowerCase() == 'priced' || price != null;
  
  bool get isWithdrawn => status?.toLowerCase() == 'withdrawn';

  String get statusLabel {
    if (isWithdrawn) return 'İptal Edildi';
    if (isPriced) return 'Fiyatlandı';
    if (isUpcoming) return 'Yaklaşan';
    return 'Bilinmiyor';
  }

  String get displayDate {
    if (date == null) return 'Tarih Belirsiz';
    try {
      final dt = DateTime.parse(date!);
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return date!;
    }
  }
}
