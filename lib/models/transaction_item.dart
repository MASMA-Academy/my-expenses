import 'dart:typed_data';

class TransactionItem {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final bool income;
  final DateTime date;
  final Uint8List? receipt;

  const TransactionItem({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.income,
    required this.date,
    this.receipt,
  });

  String get emoji {
    if (income) return '💰';

    switch (category) {
      case 'Food':
        return '🍔';
      case 'Transport':
        return '🚗';
      case 'Shopping':
        return '🛍️';
      case 'Bills':
        return '💡';
      default:
        return '💸';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'income': income ? 1 : 0,
      'date': date.toIso8601String(),
      'receipt': receipt,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: map['amount'] as double,
      income: (map['income'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
      receipt: map['receipt'] as Uint8List?,
    );
  }

  TransactionItem copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    bool? income,
    DateTime? date,
    Uint8List? receipt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      income: income ?? this.income,
      date: date ?? this.date,
      receipt: receipt ?? this.receipt,
    );
  }
}