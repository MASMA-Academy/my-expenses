# Edit & Delete Transactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user edit and delete transactions from the History screen, backed by the sqflite database added previously.

**Architecture:** `TransactionItem` gains a nullable `id` (populated from the database's autoincrement key). `AppDatabase` gains `updateTransaction`/`deleteTransaction`, and `insertTransaction` now returns the id-populated item. `AddTransactionScreen` becomes dual-purpose (add/edit) via an optional `existing` param, distinguishing the two cases on save purely by whether the returned item's `id` is set. `main.dart` branches on that to insert-vs-update, and owns a new `deleteTransaction` method. `HistoryScreen` gets tap-to-edit and swipe-to-delete (with a confirmation dialog).

**Tech Stack:** Flutter/Dart, `Dismissible`/`AlertDialog` (built-in Material widgets, no new dependencies).

## Global Constraints

- No new dependencies.
- No automated tests added — matches the rest of the app's manual-verification convention.
- Edit/delete apply to `HistoryScreen` only, not Dashboard's recent-transactions preview (per spec's Non-goals).

---

### Task 1: Model and database support for id, update, delete

**Files:**
- Modify: `lib/models/transaction_item.dart`
- Modify: `lib/db/app_database.dart`

**Interfaces:**
- Produces: `TransactionItem.id` (`int?`), `TransactionItem.copyWith(...)`.
- Produces: `AppDatabase.instance.insertTransaction(TransactionItem) ->
  Future<TransactionItem>` (changed return type — was `Future<void>`),
  `AppDatabase.instance.updateTransaction(TransactionItem) -> Future<void>`,
  `AppDatabase.instance.deleteTransaction(int id) -> Future<void>`.

- [ ] **Step 1: Add `id` and `copyWith` to `TransactionItem`**

In `lib/models/transaction_item.dart`, replace:

```dart
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
```

with:

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
```

Then replace:

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
}
```

with:

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
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: map['amount'] as double,
      income: (map['income'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
    );
  }

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
}
```

- [ ] **Step 2: Add update/delete to `AppDatabase`, change `insertTransaction`'s return type**

In `lib/db/app_database.dart`, replace:

```dart
  Future<void> insertTransaction(TransactionItem item) async {
    final db = await _db;

    await db.insert('transactions', item.toMap());
  }
```

with:

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

- [ ] **Step 3: Verify it analyzes cleanly**

Run: `flutter analyze lib/models/transaction_item.dart lib/db/app_database.dart`
Expected: `No issues found!`

Note: this step alone will NOT catch that `main.dart` still calls
`insertTransaction` expecting `void` — that's fixed in Task 3. A transient
type error in `main.dart` between Task 1 and Task 3 is expected and fine.

- [ ] **Step 4: Commit**

```bash
git add lib/models/transaction_item.dart lib/db/app_database.dart
git commit -m "Add id, copyWith to TransactionItem; add update/delete to AppDatabase"
```

---

### Task 2: `AddTransactionScreen` doubles as an edit form

**Files:**
- Modify: `lib/screens/transaction_screen.dart`

**Interfaces:**
- Consumes: `TransactionItem.id`, `TransactionItem.copyWith` are not
  directly used here, but the class now has `id` (Task 1).
- Produces: `AddTransactionScreen({super.key, TransactionItem? existing})`
  — when `existing` is provided, the widget pre-fills and returns a result
  carrying the same `id` on save. This is what Task 3's `main.dart` branches
  on.

- [ ] **Step 1: Add the `existing` constructor param**

In `lib/screens/transaction_screen.dart`, replace:

```dart
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}
```

with:

```dart
class AddTransactionScreen extends StatefulWidget {
  final TransactionItem? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}
```

- [ ] **Step 2: Pre-fill the form in `initState` when editing**

Replace:

```dart
  List<String> get currentCategories {
    return isIncome ? incomeCategories : expenseCategories;
  }

  @override
  void dispose() {
```

with:

```dart
  List<String> get currentCategories {
    return isIncome ? incomeCategories : expenseCategories;
  }

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      titleController.text = existing.title;
      amountController.text = existing.amount.toStringAsFixed(2);
      isIncome = existing.income;
      selectedCategory = existing.category;
      selectedDate = existing.date;
    }
  }

  @override
  void dispose() {
```

- [ ] **Step 3: Carry the existing id through on save**

Replace:

```dart
    final transaction = TransactionItem(
      title: title,
      category: selectedCategory,
      amount: amount,
      income: isIncome,
      date: selectedDate,

      // Kalau model TransactionItem kau belum ada field ni,
      // jangan masukkan dulu.
      //
      // paymentMethod: selectedPaymentMethod,
      // wallet: selectedWallet,
      // note: noteController.text.trim(),
    );
```

with:

```dart
    final transaction = TransactionItem(
      id: widget.existing?.id,
      title: title,
      category: selectedCategory,
      amount: amount,
      income: isIncome,
      date: selectedDate,

      // Kalau model TransactionItem kau belum ada field ni,
      // jangan masukkan dulu.
      //
      // paymentMethod: selectedPaymentMethod,
      // wallet: selectedWallet,
      // note: noteController.text.trim(),
    );
```

- [ ] **Step 4: Switch the AppBar title and save-button label by mode**

Replace:

```dart
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F7),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          'Add Transaction',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
```

with:

```dart
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F7),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          widget.existing != null ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
```

Replace:

```dart
                  child: const Text(
                    'Save Transaction',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
```

with:

```dart
                  child: Text(
                    widget.existing != null
                        ? 'Update Transaction'
                        : 'Save Transaction',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
```

- [ ] **Step 5: Verify it analyzes cleanly**

Run: `flutter analyze lib/screens/transaction_screen.dart`
Expected: only the pre-existing `deprecated_member_use` (`withOpacity`,
`value`) info-level notices already present before this change. No new
issues.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/transaction_screen.dart
git commit -m "Let AddTransactionScreen double as an edit form via an optional existing param"
```

---

### Task 3: Wire insert/update/delete through `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `AppDatabase.instance.insertTransaction` (now returns
  `Future<TransactionItem>`), `.updateTransaction`, `.deleteTransaction`
  (Task 1); `AddTransactionScreen(existing: ...)` (Task 2).
- Produces: `openEditTransaction(TransactionItem) -> Future<void>` and
  `deleteTransaction(TransactionItem) -> Future<void>` on `_MainScreenState`
  — Task 4's `HistoryScreen` callbacks point at these.

- [ ] **Step 1: Replace the add-transaction section with add/edit/delete**

Replace:

```dart
  // ==============================
  // ADD TRANSACTION
  // ==============================

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

with:

```dart
  // ==============================
  // ADD / EDIT / DELETE TRANSACTION
  // ==============================

  Future<void> openAddTransaction() async {
    await _openTransactionForm();
  }

  Future<void> openEditTransaction(TransactionItem item) async {
    await _openTransactionForm(existing: item);
  }

  Future<void> _openTransactionForm({TransactionItem? existing}) async {
    final result = await Navigator.push<TransactionItem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(existing: existing),
      ),
    );

    if (result == null) return;

    if (result.id == null) {
      final inserted = await AppDatabase.instance.insertTransaction(result);

      setState(() {
        transactions.add(inserted);

        // Lepas save balik Dashboard
        currentIndex = 0;
      });
    } else {
      await AppDatabase.instance.updateTransaction(result);

      setState(() {
        final index = transactions.indexWhere((t) => t.id == result.id);

        if (index != -1) {
          transactions[index] = result;
        }
      });
    }
  }

  Future<void> deleteTransaction(TransactionItem item) async {
    final id = item.id;
    if (id == null) return;

    await AppDatabase.instance.deleteTransaction(id);

    setState(() {
      transactions.removeWhere((t) => t.id == id);
    });
  }
```

- [ ] **Step 2: Pass the new callbacks to `HistoryScreen`**

Replace:

```dart
      case 3:
        return HistoryScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
        );
```

with:

```dart
      case 3:
        return HistoryScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
          onEditTransaction: openEditTransaction,
          onDeleteTransaction: deleteTransaction,
        );
```

- [ ] **Step 3: Verify it analyzes cleanly**

Run: `flutter analyze`
Expected: this will still show errors until Task 4 updates `HistoryScreen`'s
constructor to accept `onEditTransaction`/`onDeleteTransaction` — that's
expected at this point. Confirm the errors are specifically about
`HistoryScreen`'s constructor not recognizing the two new named arguments,
and nothing else new in `main.dart` itself.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "Wire transaction edit and delete through MainScreen"
```

---

### Task 4: Tap-to-edit and swipe-to-delete on `HistoryScreen`

**Files:**
- Modify: `lib/screens/history_screen.dart`

**Interfaces:**
- Consumes: `onEditTransaction`/`onDeleteTransaction` callbacks passed from
  `main.dart` (Task 3).

- [ ] **Step 1: Add the two callback params**

Replace:

```dart
class HistoryScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;

  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });
```

with:

```dart
class HistoryScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;
  final void Function(TransactionItem transaction) onEditTransaction;
  final void Function(TransactionItem transaction) onDeleteTransaction;

  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
  });
```

- [ ] **Step 2: Wrap each row in `Dismissible` + tap-to-edit, add the confirm dialog**

Replace:

```dart
  Widget _buildTransactionCard(
    TransactionItem transaction,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: transaction.income
                  ? const Color(0xFFE1F4E9)
                  : getCategoryColor(
                      transaction.category,
                    ),

              shape: BoxShape.circle,
            ),

            child: Text(
              transaction.emoji,

              style: const TextStyle(
                fontSize: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  transaction.title,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  transaction.category,

                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  formatDate(
                    transaction.date,
                  ),

                  style: const TextStyle(
                    color: Color(0xFF74B9A8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${transaction.income ? '+' : '-'} RM ${transaction.amount.toStringAsFixed(2)}',

            style: TextStyle(
              color: transaction.income
                  ? const Color(0xFF347B69)
                  : const Color(0xFFA64E4E),

              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
```

with:

```dart
  Widget _buildTransactionCard(
    TransactionItem transaction,
  ) {
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(transaction),
      onDismissed: (_) {
        widget.onDeleteTransaction(transaction);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE36C6C),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: () => widget.onEditTransaction(transaction),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: transaction.income
                      ? const Color(0xFFE1F4E9)
                      : getCategoryColor(
                          transaction.category,
                        ),

                  shape: BoxShape.circle,
                ),

                child: Text(
                  transaction.emoji,

                  style: const TextStyle(
                    fontSize: 22,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      transaction.title,

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      transaction.category,

                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      formatDate(
                        transaction.date,
                      ),

                      style: const TextStyle(
                        color: Color(0xFF74B9A8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${transaction.income ? '+' : '-'} RM ${transaction.amount.toStringAsFixed(2)}',

                style: TextStyle(
                  color: transaction.income
                      ? const Color(0xFF347B69)
                      : const Color(0xFFA64E4E),

                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(TransactionItem transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: Text(
            'This will permanently delete "${transaction.title}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFE36C6C)),
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }
```

- [ ] **Step 3: Verify it analyzes cleanly**

Run: `flutter analyze`
Expected: `No issues found!` for the four files touched in this plan (some
pre-existing, unrelated `deprecated_member_use` notices elsewhere in the
project are expected, as established in earlier work).

- [ ] **Step 4: Manually verify edit and delete**

Use the `run` skill (web, since that's the platform already confirmed
working with sqflite in this environment via `sqflite_common_ffi_web`):

- Go to History, tap an existing transaction → confirm the form opens
  pre-filled with its data and reads "Edit Transaction" → change the amount
  → tap "Update Transaction" → confirm the row updates immediately and
  Dashboard/Report/Budget totals reflect the change.
- Swipe a row left → confirm the delete confirmation dialog appears → tap
  Cancel → confirm the row is unchanged → swipe again → tap Delete → confirm
  the row disappears and totals update.
- Hot-restart the app → confirm both the edit and the delete persisted
  (the edited row still shows the new amount; the deleted row is still
  gone).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/history_screen.dart
git commit -m "Add tap-to-edit and swipe-to-delete to HistoryScreen"
```
