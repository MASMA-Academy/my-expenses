class TransactionItem {
  final String title;
  final String category;
  final double amount;
  final bool income;
  final DateTime date;

  const TransactionItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.income,
    required this.date,
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
}