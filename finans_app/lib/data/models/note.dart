class Note {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final int color;
  final bool isPinned;
  final List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.color,
    this.isPinned = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'color': color,
      'isPinned': isPinned,
      'tags': tags,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      color: json['color'] ?? 0xFFFFFFFF,
      isPinned: json['isPinned'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    int? color,
    bool? isPinned,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }
}
