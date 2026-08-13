# sqflite Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist `TransactionItem`s and `BudgetScreen` category limits to a local SQLite database via `sqflite`, so both survive app restarts instead of resetting every launch.

**Architecture:** One new singleton, `AppDatabase` (`lib/db/app_database.dart`), wraps a single sqflite `Database` with two tables (`transactions`, `budget_limits`) and exposes plain CRUD methods. `TransactionItem` gets `toMap()`/`fromMap()` for (de)serialization. `main.dart` loads transactions asynchronously on startup and inserts on add; `BudgetScreen` loads limits on init and upserts on save.

**Tech Stack:** Flutter/Dart, `sqflite` (local SQLite), `path` (path joining — standard sqflite companion package).

## Global Constraints

- `sqflite` only supports Android/iOS/macOS natively — no Windows/Linux/web support in this pass (per spec's Non-goals). Verify on the `Medium_Phone` Android emulator, not the Windows desktop target (which doesn't build here for an unrelated, pre-existing reason: missing Visual Studio toolchain).
- No `id` field added to `TransactionItem` — no edit/delete UI exists for individual transactions, so the database's autoincrement key stays internal (per spec's Non-goals).
- No automated tests added — matches the rest of the app's manual-verification convention.
- Add dependencies via `flutter pub add`, not hand-edited version pins in `pubspec.yaml`.

---

### Task 1: Database layer and model serialization

**Files:**
- Modify: `pubspec.yaml` (via `flutter pub add`)
- Create: `lib/db/app_database.dart`
- Modify: `lib/models/transaction_item.dart`

**Interfaces:**
- Produces: `AppDatabase.instance` singleton with:
  - `Future<List<TransactionItem>> getTransactions()`
  - `Future<void> insertTransaction(TransactionItem item)`
  - `Future<Map<String, double>> getBudgetLimits()`
  - `Future<void> setBudgetLimit(String category, double limit)`
- Produces: `TransactionItem.toMap()` and `TransactionItem.fromMap(Map<String, dynamic>)`, used by `AppDatabase` and (in Task 2/3) by `main.dart`/`BudgetScreen`.

- [ ] **Step 1: Add the dependencies**

Run: `flutter pub add sqflite path`
Expected: `pubspec.yaml` gains `sqflite` and `path` entries under `dependencies`, and `flutter pub get` runs automatically as part of `pub add`.

- [ ] **Step 2: Add serialization to `TransactionItem`**

In `lib/models/transaction_item.dart`, add these two members inside the
`TransactionItem` class, after the existing `emoji` getter (before the
closing `}`):

```dart
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'income': income ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      title: map['title'] as String,
      category: map['category'] as String,
      amount: map['amount'] as double,
      income: (map['income'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
    );
  }
```

- [ ] **Step 3: Create the database layer**

Create `lib/db/app_database.dart`:

```dart
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            income INTEGER NOT NULL,
            date TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE budget_limits (
            category TEXT PRIMARY KEY,
            budget_limit REAL NOT NULL
          )
        ''');
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

  Future<void> insertTransaction(TransactionItem item) async {
    final db = await _db;

    await db.insert('transactions', item.toMap());
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
```

- [ ] **Step 4: Verify it analyzes cleanly**

Run: `flutter analyze lib/db/app_database.dart lib/models/transaction_item.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/db/app_database.dart lib/models/transaction_item.dart
git commit -m "Add sqflite database layer and TransactionItem (de)serialization"
```

---

### Task 2: Load and persist transactions in `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `AppDatabase.instance.getTransactions()` and
  `AppDatabase.instance.insertTransaction(TransactionItem)` from Task 1.

- [ ] **Step 1: Add the import**

In `lib/main.dart`, add alongside the existing imports (after the
`models/transaction_item.dart` import):

```dart
import 'db/app_database.dart';
```

- [ ] **Step 2: Add loading state and load transactions on init**

Replace:

```dart
  // ==============================
  // DATA
  // ==============================

  final List<TransactionItem> transactions = [];

  // ==============================
  // ADD TRANSACTION
  // ==============================
```

with:

```dart
  // ==============================
  // DATA
  // ==============================

  List<TransactionItem> transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final loaded = await AppDatabase.instance.getTransactions();

    setState(() {
      transactions = loaded;
      _loading = false;
    });
  }

  // ==============================
  // ADD TRANSACTION
  // ==============================
```

- [ ] **Step 3: Insert new transactions into the database**

Replace:

```dart
  Future<void> openAddTransaction() async {
    final result = await Navigator.push<TransactionItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        transactions.add(result);

        // Lepas save balik Dashboard
        currentIndex = 0;
      });
    }
  }
```

with:

```dart
  Future<void> openAddTransaction() async {
    final result = await Navigator.push<TransactionItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    if (result != null) {
      await AppDatabase.instance.insertTransaction(result);

      setState(() {
        transactions.add(result);

        // Lepas save balik Dashboard
        currentIndex = 0;
      });
    }
  }
```

- [ ] **Step 4: Show a loading state until data is ready**

Replace:

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getCurrentScreen(),
```

with:

```dart
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F6),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF277765),
          ),
        ),
      );
    }

    return Scaffold(
      body: getCurrentScreen(),
```

- [ ] **Step 5: Verify it analyzes cleanly**

Run: `flutter analyze`
Expected: only the pre-existing unrelated issues (`unused_import` for
`budget_screen.dart` — note: now used via case 4, so this specific warning
should already be gone — plus the pre-existing `deprecated_member_use`
warnings in `transaction_screen.dart` and the stale `test/widget_test.dart`
error). No new issues in `main.dart`.

- [ ] **Step 6: Manually verify persistence**

Use the `run` skill on the Android emulator:

```bash
flutter emulators --launch Medium_Phone
flutter run -d emulator-5554
```

- Add a transaction via the `+` button.
- Confirm it appears on Dashboard/History/Report.
- Hot-restart the app (press `R` in the `flutter run` terminal — a full
  restart, not `r` for hot reload, since hot reload preserves in-memory
  state regardless of persistence).
- Confirm the transaction is still present after restart (proves it was
  actually read back from the database, not just kept in memory).

- [ ] **Step 7: Commit**

```bash
git add lib/main.dart
git commit -m "Load transactions from the database on startup and persist new ones"
```

---

### Task 3: Load and persist budget limits in `BudgetScreen`

**Files:**
- Modify: `lib/screens/budget_screen.dart`

**Interfaces:**
- Consumes: `AppDatabase.instance.getBudgetLimits()` and
  `AppDatabase.instance.setBudgetLimit(String, double)` from Task 1.

- [ ] **Step 1: Add the import**

In `lib/screens/budget_screen.dart`, add alongside the existing imports:

```dart
import '../db/app_database.dart';
```

- [ ] **Step 2: Load persisted limits on init**

Replace:

```dart
  @override
  void initState() {
    super.initState();

    _displayMonth = DateTime.now();
  }
```

with:

```dart
  @override
  void initState() {
    super.initState();

    _displayMonth = DateTime.now();

    _loadBudgetLimits();
  }

  Future<void> _loadBudgetLimits() async {
    final limits = await AppDatabase.instance.getBudgetLimits();

    if (limits.isEmpty) return;

    setState(() {
      for (final category in _categories) {
        final savedLimit = limits[category.title];

        if (savedLimit != null) {
          category.limit = savedLimit;
        }
      }
    });
  }
```

- [ ] **Step 3: Persist the limit when "Set Budget" is saved**

Replace:

```dart
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              final amount = double.tryParse(
                                budgetController.text.trim(),
                              );

                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid budget amount.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              final category = _categories.firstWhere(
                                (item) =>
                                    item.title == selectedCategory,
                              );

                              setState(() {
                                category.limit = amount;
                              });

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    '$selectedCategory budget updated 💖',
                                  ),
                                ),
                              );
                            },
```

with:

```dart
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              final amount = double.tryParse(
                                budgetController.text.trim(),
                              );

                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid budget amount.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              final category = _categories.firstWhere(
                                (item) =>
                                    item.title == selectedCategory,
                              );

                              await AppDatabase.instance.setBudgetLimit(
                                category.title,
                                amount,
                              );

                              setState(() {
                                category.limit = amount;
                              });

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    '$selectedCategory budget updated 💖',
                                  ),
                                ),
                              );
                            },
```

- [ ] **Step 4: Verify it analyzes cleanly**

Run: `flutter analyze lib/screens/budget_screen.dart`
Expected: only the pre-existing `deprecated_member_use` (`withOpacity`)
warnings already present before this change. No new issues.

- [ ] **Step 5: Manually verify persistence**

With the app still running on the `Medium_Phone` emulator from Task 2:

- Go to the Budget tab, tap "Set Budget", set a category (e.g. Food) to a
  distinct value (e.g. 999), save.
- Confirm the category row updates immediately.
- Hot-restart the app (`R` in the `flutter run` terminal).
- Confirm the category still shows the saved limit (999), not the hardcoded
  default (700).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/budget_screen.dart
git commit -m "Load budget limits from the database on init and persist on save"
```
