import 'package:flutter_test/flutter_test.dart';
import 'package:myxpenses/models/transaction_item.dart';

void main() {
  group('TransactionItem', () {
    test('toMap/fromMap round-trip preserves all fields', () {
      final date = DateTime(2026, 8, 14, 10, 30);

      final original = TransactionItem(
        id: 42,
        title: 'Lunch',
        category: 'Food',
        amount: 15.5,
        income: false,
        date: date,
        paymentMethod: 'Card',
        wallet: 'Maybank',
        note: 'with friends',
      );

      final map = original.toMap();
      // toMap intentionally excludes id (autoincrement / WHERE concern) —
      // add it back the way AppDatabase.getTransactions() would.
      map['id'] = original.id;

      final restored = TransactionItem.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.amount, original.amount);
      expect(restored.income, original.income);
      expect(restored.date, original.date);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.wallet, original.wallet);
      expect(restored.note, original.note);
    });

    test(
      'fromMap defaults missing payment_method/wallet/note for pre-migration rows',
      () {
        final map = {
          'id': 1,
          'title': 'Old Row',
          'category': 'Others',
          'amount': 10.0,
          'income': 0,
          'date': DateTime(2026, 1, 1).toIso8601String(),
        };

        final item = TransactionItem.fromMap(map);

        expect(item.paymentMethod, 'Cash');
        expect(item.wallet, 'Cash');
        expect(item.note, '');
      },
    );

    test('copyWith only overrides provided fields', () {
      final original = TransactionItem(
        title: 'Original',
        category: 'Food',
        amount: 10,
        income: false,
        date: DateTime(2026, 1, 1),
      );

      final copy = original.copyWith(amount: 20, id: 5);

      expect(copy.id, 5);
      expect(copy.amount, 20);
      expect(copy.title, original.title);
      expect(copy.category, original.category);
      expect(copy.income, original.income);
      expect(copy.date, original.date);
    });

    test('emoji reflects income vs category', () {
      final income = TransactionItem(
        title: 'Salary',
        category: 'Salary',
        amount: 100,
        income: true,
        date: DateTime.now(),
      );

      final food = TransactionItem(
        title: 'Lunch',
        category: 'Food',
        amount: 10,
        income: false,
        date: DateTime.now(),
      );

      expect(income.emoji, '💰');
      expect(food.emoji, '🍔');
    });
  });
}
