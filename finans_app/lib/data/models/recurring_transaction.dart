/// Sabit (tekrarlayan) gelir veya gider modeli.
class RecurringTransaction {
  final int? id;
  final String type;       // 'INCOME' | 'EXPENSE'
  final String category;
  final double amount;
  final String period;     // 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY'
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;   // null → süresiz
  final bool isActive;

  const RecurringTransaction({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.period,
    this.description,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id:          json['id'],
      type:        json['type'],
      category:    json['category'],
      amount:      double.parse(json['amount'].toString()),
      period:      json['period'],
      description: json['description'],
      startDate:   DateTime.parse(json['start_date']),
      endDate:     json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive:    json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type':        type,
    'category':    category,
    'amount':      amount,
    'period':      period,
    'description': description,
    'start_date':  _fmt(startDate),
    'end_date':    endDate != null ? _fmt(endDate!) : null,
    'is_active':   isActive,
  };

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  /// Aylık eşdeğer tutar
  double get monthlyAmount {
    switch (period) {
      case 'DAILY':   return amount * 30;
      case 'WEEKLY':  return amount * 4.33;
      case 'MONTHLY': return amount;
      case 'YEARLY':  return amount / 12;
      default:        return amount;
    }
  }

  static String periodLabel(String p) {
    switch (p) {
      case 'DAILY':   return 'Günlük';
      case 'WEEKLY':  return 'Haftalık';
      case 'MONTHLY': return 'Aylık';
      case 'YEARLY':  return 'Yıllık';
      default:        return p;
    }
  }
}
