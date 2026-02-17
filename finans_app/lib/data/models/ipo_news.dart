class IPONews {
  final String title;
  final String content;
  final String date;
  final String url;
  final String? image;
  final String source;

  IPONews({
    required this.title,
    required this.content,
    required this.date,
    required this.url,
    this.image,
    required this.source,
  });

  factory IPONews.fromJson(Map<String, dynamic> json) {
    return IPONews(
      title: json['title'] ?? '',
      content: json['text'] ?? json['content'] ?? '',
      date: json['publishedDate'] ?? json['date'] ?? '',
      url: json['url'] ?? '',
      image: json['image'],
      source: json['site'] ?? json['source'] ?? 'Finans Haber',
    );
  }

  String get displayDate {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }
}
