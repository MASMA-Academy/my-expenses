# Edit & Delete Transactions — Design Spec

## Context

MyXpenses currently only supports *adding* transactions — `AddTransactionScreen`
returns a new `TransactionItem` via `Navigator.pop`, `main.dart` inserts it into
the sqflite database (added in [[2026-08-13-sqflite-persistence-design]]) and
appends it to the in-memory `transactions` list. There is no way to edit or
remove a transaction once saved. `TransactionItem` has no `id` field — it was
explicitly a non-goal of the persistence work, since no edit/delete UI existed
yet.

The user asked to add edit and delete. This spec adds both, scoped to the
`HistoryScreen` (the full transaction list), reusing the existing
`AddTransactionScreen` form for editing and a swipe-to-delete gesture with a
confirmation dialog for deleting.

## Goals

- `TransactionItem` gains a nullable `id: int?`, populated from the database's
  autoincrement primary key. `null` means "not yet persisted."
- `AppDatabase` gains `updateTransaction` and `deleteTransaction`;
  `insertTransaction` changes to return the inserted `TransactionItem`
  (with `id` populated) instead of `void`.
- `AddTransactionScreen` gains an optional `existing: TransactionItem?` param.
  When provided, the form pre-fills from it and acts as an edit form; the
  returned `TransactionItem` carries the same `id`.
- On `HistoryScreen`, tapping a transaction row opens it for editing; swiping
  a row left prompts a confirmation dialog and, if confirmed, deletes it.
- Edits and deletes apply to the single shared `transactions` list owned by
  `MainScreen`, so Dashboard/Report/Budget reflect them automatically (they
  already read the same list instance).

## Non-goals

- No edit/delete on Dashboard's "Recent Transactions" preview — it stays a
  read-only preview that links to History via "See All" (per user's explicit
  scope choice).
- No undo-after-delete affordance (e.g. a "Restore" snackbar action) — out of
  scope for this pass; the confirmation dialog is the only safety net.
- No batch/multi-select delete.
- No changes to `BudgetScreen`'s "Set Budget" flow — that's already an edit
  flow for budget limits, unrelated to this transaction-focused change.

## Model change

`lib/models/transaction_item.dart`:

```dart
class TransactionItem {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final bool income;
  final DateTime date;

  const TransactionItem({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.income,
    required this.date,
  });

  // emoji getter unchanged

  TransactionItem copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    bool? income,
    DateTime? date,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      income: income ?? this.income,
      date: date ?? this.date,
    );
  }

  // toMap() unchanged — does NOT include 'id' (autoincrement / WHERE-clause
  // concern, not a column to write)

  // fromMap() adds: id: map['id'] as int?,
}
```

Existing call sites that construct `TransactionItem(title: ..., category:
..., amount: ..., income: ..., date: ...)` without `id` keep compiling
unchanged (`id` defaults to `null`), which is exactly the "not yet persisted"
state a brand-new transaction from the add form is in.

## Database changes

`lib/db/app_database.dart`:

```dart
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
```

`getTransactions()` is unchanged except that `fromMap` now populates `id`
from each row.

## `AddTransactionScreen` changes

- New constructor param: `final TransactionItem? existing;` (default `null`).
- `initState()` (new — the widget currently has no `initState`): when
  `widget.existing != null`, sets `titleController.text`,
  `amountController.text` (via `toStringAsFixed(2)`), `isIncome`,
  `selectedCategory`, and `selectedDate` from it.
- AppBar title and save-button label switch between "Add Transaction"/"Save
  Transaction" and "Edit Transaction"/"Update Transaction" based on whether
  `widget.existing` is set.
- `saveTransaction()` builds the result with `id: widget.existing?.id`, so
  the caller can distinguish a new transaction (`id == null`) from an edited
  one (`id != null`) purely from the returned value.

## `main.dart` changes

- `openAddTransaction()` and a new `openEditTransaction(TransactionItem
  item)` both delegate to a shared private `_openTransactionForm({
  TransactionItem? existing})`:
  - Pushes `AddTransactionScreen(existing: existing)`, awaits a
    `TransactionItem?` result.
  - If `result == null` (cancelled), does nothing.
  - If `result.id == null` (new), calls `AppDatabase.instance
    .insertTransaction(result)`, appends the returned (id-populated) item to
    `transactions`, and — matching current behavior — sets `currentIndex =
    0` (jump to Dashboard).
  - If `result.id != null` (edited), calls `AppDatabase.instance
    .updateTransaction(result)`, replaces the matching entry in
    `transactions` (by `id`) with `result`, and does **not** change
    `currentIndex` (stays on History, where the edit was initiated).
- New `Future<void> deleteTransaction(TransactionItem item)`: calls
  `AppDatabase.instance.deleteTransaction(item.id!)` (only called from
  contexts where `item.id` is known non-null — a persisted, on-screen row
  always has one) then removes it from `transactions` by `id`.
- `HistoryScreen` is constructed with two new required callbacks:
  `onEditTransaction: openEditTransaction` and `onDeleteTransaction:
  deleteTransaction`.

## `HistoryScreen` changes

- New required constructor params: `final void Function(TransactionItem)
  onEditTransaction;` and `final void Function(TransactionItem)
  onDeleteTransaction;`.
- `_buildTransactionCard` wraps its existing `Container` in:
  - `Dismissible` (`key: ValueKey(transaction.id)`, `direction:
    DismissDirection.endToStart`, a red delete-icon background,
    `confirmDismiss` showing an `AlertDialog` ("Delete transaction?" / the
    transaction's title / Cancel / Delete), `onDismissed` calling
    `widget.onDeleteTransaction(transaction)`).
  - `InkWell`/`GestureDetector` `onTap: () =>
    widget.onEditTransaction(transaction)`.

## Error handling

Same posture as the rest of the app and the persistence spec: local sqflite
calls are not expected to fail under normal use, so no special error
handling is added beyond what already exists. The delete confirmation
dialog is the only safety net against unintended data loss.

## Testing / verification

- `flutter analyze` must pass with no new issues.
- Manual verification via the `run` skill:
  - Tap an existing transaction on History → form pre-fills correctly →
    change a field → Update → confirm the row reflects the change and
    Dashboard/Report/Budget totals update accordingly.
  - Swipe a row left → confirm the dialog appears → Cancel → row stays →
    swipe again → Delete → row disappears and totals update accordingly.
  - Hot-restart the app after both operations → confirm the changes
    persisted (proves the DB writes actually happened, not just in-memory
    state).
- No automated tests added, consistent with the rest of the app.

## Dependencies to add

None — `Dismissible` and `AlertDialog` are both built into Flutter's
Material library, already in use elsewhere in the app.
