
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final int color;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'color': color,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      color: json['color'] ?? 0xFFFFFFFF,
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    int? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      color: color ?? this.color,
    );
  }
}
