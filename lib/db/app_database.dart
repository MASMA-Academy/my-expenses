// lib/db/app_database.dart

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/transaction_item.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get _db async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = path.join(await getDatabasesPath(), 'myxpenses.db');

    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            income INTEGER NOT NULL,
            date TEXT NOT NULL,
            receipt BLOB
          )
        ''');

        await db.execute('''
          CREATE TABLE budget_limits (
            category TEXT PRIMARY KEY,
            budget_limit REAL NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN receipt BLOB',
          );
        }
      },
    );
  }

  // =========================================================
  // TRANSACTIONS
  // =========================================================

  Future<List<TransactionItem>> getTransactions() async {
    final db = await _db;

    final rows = await db.query('transactions', orderBy: 'date DESC');

    return rows.map(TransactionItem.fromMap).toList();
  }

  Future<TransactionItem> insertTransaction(TransactionItem item) async {
    final db = await _db;

    final id = await db.insert('transactions', item.toMap());

    return item.copyWith(id: id);
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final db = await _db;

    await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _db;

    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  // BUDGET LIMITS
  // =========================================================

  Future<Map<String, double>> getBudgetLimits() async {
    final db = await _db;

    final rows = await db.query('budget_limits');

    return {
      for (final row in rows)
        row['category'] as String: row['budget_limit'] as double,
    };
  }

  Future<void> setBudgetLimit(String category, double limit) async {
    final db = await _db;

    await db.insert(
      'budget_limits',
      {'category': category, 'budget_limit': limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
