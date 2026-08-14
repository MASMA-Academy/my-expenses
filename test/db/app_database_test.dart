import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myxpenses/db/app_database.dart';
import 'package:myxpenses/models/transaction_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppDatabase transactions', () {
    test(
      'insert then getTransactions returns it with a generated id',
      () async {
        final unique = 'Test Insert ${DateTime.now().microsecondsSinceEpoch}';

        final inserted = await AppDatabase.instance.insertTransaction(
          TransactionItem(
            title: unique,
            category: 'Food',
            amount: 12.5,
            income: false,
            date: DateTime(2026, 8, 1),
          ),
        );

        expect(inserted.id, isNotNull);

        final all = await AppDatabase.instance.getTransactions();
        final found = all.firstWhere((t) => t.title == unique);

        expect(found.amount, 12.5);
        expect(found.category, 'Food');

        await AppDatabase.instance.deleteTransaction(inserted.id!);
      },
    );

    test('updateTransaction changes the stored row', () async {
      final unique = 'Test Update ${DateTime.now().microsecondsSinceEpoch}';

      final inserted = await AppDatabase.instance.insertTransaction(
        TransactionItem(
          title: unique,
          category: 'Food',
          amount: 5,
          income: false,
          date: DateTime(2026, 8, 1),
        ),
      );

      await AppDatabase.instance.updateTransaction(
        inserted.copyWith(amount: 50),
      );

      final all = await AppDatabase.instance.getTransactions();
      final found = all.firstWhere((t) => t.id == inserted.id);

      expect(found.amount, 50);

      await AppDatabase.instance.deleteTransaction(inserted.id!);
    });

    test('deleteTransaction removes the row', () async {
      final unique = 'Test Delete ${DateTime.now().microsecondsSinceEpoch}';

      final inserted = await AppDatabase.instance.insertTransaction(
        TransactionItem(
          title: unique,
          category: 'Food',
          amount: 5,
          income: false,
          date: DateTime(2026, 8, 1),
        ),
      );

      await AppDatabase.instance.deleteTransaction(inserted.id!);

      final all = await AppDatabase.instance.getTransactions();

      expect(all.any((t) => t.id == inserted.id), isFalse);
    });
  });

  group('AppDatabase budget limits', () {
    test('setBudgetLimit then getBudgetLimits reflects it', () async {
      final category = 'TestBudget${DateTime.now().microsecondsSinceEpoch}';

      await AppDatabase.instance.setBudgetLimit(category, 250);

      final limits = await AppDatabase.instance.getBudgetLimits();

      expect(limits[category], 250);
    });

    test(
      'setBudgetLimit overwrites a previous limit for the same category',
      () async {
        final category = 'TestBudget2${DateTime.now().microsecondsSinceEpoch}';

        await AppDatabase.instance.setBudgetLimit(category, 100);
        await AppDatabase.instance.setBudgetLimit(category, 300);

        final limits = await AppDatabase.instance.getBudgetLimits();

        expect(limits[category], 300);
      },
    );
  });

  group('AppDatabase custom categories', () {
    test('addCustomCategory then getCustomCategories reflects it', () async {
      final title = 'TestCat${DateTime.now().microsecondsSinceEpoch}';

      await AppDatabase.instance.addCustomCategory(
        title: title,
        emoji: '✨',
        color: 0xFFFFFFFF,
      );

      final rows = await AppDatabase.instance.getCustomCategories();
      final found = rows.firstWhere((row) => row['title'] == title);

      expect(found['emoji'], '✨');
      expect(found['color'], 0xFFFFFFFF);
    });
  });
}
