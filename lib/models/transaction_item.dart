import 'dart:typed_data';

class TransactionItem {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final bool income;
  final DateTime date;
  final Uint8List? receipt;
  final String paymentMethod;
  final String wallet;
  final String note;

  const TransactionItem({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.income,
    required this.date,
    this.receipt,
    this.paymentMethod = 'Cash',
    this.wallet = 'Cash',
    this.note = '',
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
      'payment_method': paymentMethod,
      'wallet': wallet,
      'note': note,
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
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      wallet: (map['wallet'] as String?) ?? 'Cash',
      note: (map['note'] as String?) ?? '',
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
    String? paymentMethod,
    String? wallet,
    String? note,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      income: income ?? this.income,
      date: date ?? this.date,
      receipt: receipt ?? this.receipt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      wallet: wallet ?? this.wallet,
      note: note ?? this.note,
    );
  }
}
