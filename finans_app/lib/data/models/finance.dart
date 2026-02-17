class Income {
  final int? id;
  final double amount;
  final String source;
  final DateTime date;
  final String? description;

  Income({
    this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.description,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      source: json['source'],
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'source': source,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}

class Expense {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}
