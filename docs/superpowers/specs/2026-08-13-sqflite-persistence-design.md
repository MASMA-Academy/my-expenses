# sqflite Persistence — Design Spec

## Context

MyXpenses currently holds all data purely in memory: `_MainScreenState.transactions`
(`lib/main.dart`) is a `List<TransactionItem>` that starts empty and is lost on
every app restart. `BudgetScreen` similarly holds a hardcoded
`List<BudgetCategory>` with default spending limits that reset every launch —
only the in-session edits (via "Set Budget") change them, and those are lost
too.

The user asked whether this app persists data (it doesn't), discussed
Supabase vs. local storage, and chose local storage with `sqflite`. This spec
adds a local SQLite database so both transactions and budget limits survive
app restarts.

## Goals

- Persist `TransactionItem`s: every transaction added via `AddTransactionScreen`
  is written to a local SQLite database, and the full list is loaded from the
  database on app startup instead of starting empty.
- Persist `BudgetCategory` limits: `BudgetScreen`'s per-category `limit` is
  written to the database when the user saves it via "Set Budget", and loaded
  on `BudgetScreen` init to override the hardcoded defaults where a saved
  value exists.
- Single local database file, no networking, no accounts.

## Non-goals

- No edit/delete UI for individual transactions — matches the app's current
  functionality (only "add" exists). `TransactionItem` does not need an
  exposed `id`; the database's autoincrement primary key stays internal.
- No cross-device sync (that's the Supabase path the user explicitly did not
  choose).
- No support for Windows/Linux/web targets in this pass. `sqflite` (the
  package being used, per user's explicit choice) only works natively on
  Android/iOS/macOS. Desktop/web would need extra FFI packages
  (`sqflite_common_ffi`, `sqflite_common_ffi_web`) — out of scope. This
  project's Windows desktop build is already broken in the dev environment
  (missing Visual Studio toolchain) independent of this change; verification
  will use the available Android emulator (`Medium_Phone`) instead.
- No database migrations system beyond a single `version: 1` schema — there
  is no existing persisted data to migrate from.

## File layout

```
lib/
  db/
    app_database.dart      → new: AppDatabase singleton, schema, CRUD helpers
  models/
    transaction_item.dart  → add toMap()/fromMap() for DB (de)serialization
  screens/
    budget_screen.dart     → load persisted limits on init, save on "Set Budget"
  main.dart                → async-load transactions on startup, insert on add
```

## Schema

```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  income INTEGER NOT NULL,   -- 0 = expense, 1 = income
  date TEXT NOT NULL         -- ISO 8601, e.g. 2026-08-13T10:30:00.000
);

CREATE TABLE budget_limits (
  category TEXT PRIMARY KEY,
  budget_limit REAL NOT NULL
);
```

## `AppDatabase` (lib/db/app_database.dart)

A singleton (`AppDatabase.instance`) wrapping a single sqflite `Database`,
opened lazily on first use via `getDatabase()` (creates the file under the
platform's app-documents/database directory using `path_provider`-free
`getDatabasesPath()` from sqflite itself, joined via the `path` package).
`onCreate` runs the two `CREATE TABLE` statements above.

Methods:
- `Future<List<TransactionItem>> getTransactions()` — `SELECT * FROM
  transactions ORDER BY date DESC`, mapped via `TransactionItem.fromMap`.
- `Future<void> insertTransaction(TransactionItem item)` — `INSERT INTO
  transactions` using `item.toMap()` (no `id` key in the map — autoincrement
  fills it).
- `Future<Map<String, double>> getBudgetLimits()` — `SELECT * FROM
  budget_limits`, mapped into `{category: budget_limit}`.
- `Future<void> setBudgetLimit(String category, double limit)` — `INSERT OR
  REPLACE INTO budget_limits (category, budget_limit) VALUES (?, ?)`.

## `TransactionItem` changes

Add, alongside the existing constructor and `emoji` getter:

```dart
Map<String, dynamic> toMap() => {
  'title': title,
  'category': category,
  'amount': amount,
  'income': income ? 1 : 0,
  'date': date.toIso8601String(),
};

factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
  title: map['title'] as String,
  category: map['category'] as String,
  amount: map['amount'] as double,
  income: (map['income'] as int) == 1,
  date: DateTime.parse(map['date'] as String),
);
```

No `id` field is added to the class (see Non-goals).

## `main.dart` changes

`_MainScreenState`:
- `transactions` becomes non-final and starts as `[]`; add `bool _loading =
  true`.
- `initState()` calls an async `_loadTransactions()` that awaits
  `AppDatabase.instance.getTransactions()`, then `setState` assigns the
  result to `transactions` and sets `_loading = false`.
- `build()`: while `_loading`, return a `Scaffold` with a centered
  `CircularProgressIndicator` (same `scaffoldBackgroundColor`) instead of
  `getCurrentScreen()` + bottom nav — the rest of the shell (bottom nav, FAB)
  only renders once data is loaded.
- `openAddTransaction()`: after `Navigator.push` returns a non-null `result`,
  in addition to the existing `setState(() { transactions.add(result); ...
  })`, call `await AppDatabase.instance.insertTransaction(result)` (awaited
  before the `setState`, so a write failure doesn't leave the UI showing data
  that failed to persist — sqflite failures are exceptional/unexpected here
  so no special handling beyond letting the exception surface).

## `BudgetScreen` changes

- `initState()` additionally calls an async `_loadBudgetLimits()`: awaits
  `AppDatabase.instance.getBudgetLimits()`, then for each returned
  `(category, limit)` pair, finds the matching entry in `_categories` (by
  `title`) and `setState`s its `limit`. Categories with no saved row keep
  their hardcoded default.
- The "Set Budget" save `onPressed` handler becomes `() async { ... }`: after
  the existing `setState(() { category.limit = amount; })`, add `await
  AppDatabase.instance.setBudgetLimit(category.title, amount);` before
  `Navigator.pop(sheetContext)`.

## Error handling

sqflite calls are local file I/O — no network, no auth. No error handling is
added beyond letting exceptions propagate (consistent with the rest of the
app, which has no error-handling infrastructure). If `getDatabase()` throws
on startup, that's a genuine bug to see in the debug console, not a case to
paper over.

## Testing / verification

- `flutter analyze` must pass with no errors.
- Manual verification via the `run` skill, using the `Medium_Phone` Android
  emulator (the Windows desktop target doesn't build in this environment for
  unrelated reasons — see Non-goals):
  - Add a transaction, hot-restart the app (not hot reload), confirm it's
    still present on Dashboard/History/Report.
  - Set a budget limit for a category, hot-restart, confirm the limit
    persisted on the Budget screen.
- No automated tests added, consistent with the rest of the app's convention
  of manual-only verification.

## Dependencies to add

- `sqflite` (local SQLite database)
- `path` (joining the database file path — standard sqflite companion package)
