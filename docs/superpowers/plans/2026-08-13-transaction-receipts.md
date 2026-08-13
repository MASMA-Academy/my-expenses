# Transaction Receipt Attachments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user attach a receipt photo to a transaction (camera or gallery), stored as bytes so the same code path works on mobile and web.

**Architecture:** `receipt BLOB` column added to `transactions` via a version-2 schema migration. `TransactionItem` gains a nullable `Uint8List? receipt`. `AddTransactionScreen` gets an `image_picker`-backed picker UI with a thumbnail/remove affordance. `HistoryScreen` shows a small attachment icon on rows that have one. Android/iOS platform config is updated so the picker actually functions.

**Tech Stack:** Flutter/Dart, `image_picker` (new dependency).

## Global Constraints

- No new dependencies beyond `image_picker`.
- No automated tests added — matches the rest of the app's manual-verification convention.
- No full-screen receipt viewer, no multi-receipt support, no custom resize pipeline beyond `image_picker`'s own `imageQuality` (per spec's Non-goals).

---

### Task 1: Schema migration and model field

**Files:**
- Modify: `pubspec.yaml` (via `flutter pub add`)
- Modify: `lib/models/transaction_item.dart`
- Modify: `lib/db/app_database.dart`

**Interfaces:**
- Produces: `TransactionItem.receipt` (`Uint8List?`), included in `toMap`/`fromMap`/`copyWith`.
- Produces: `transactions` table has a `receipt BLOB` column from database version 2 onward, via `onCreate` (fresh installs) and `onUpgrade` (existing installs from version 1).

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add image_picker`

- [ ] **Step 2: Add `receipt` to `TransactionItem`**

In `lib/models/transaction_item.dart`, replace:

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

with:

```dart
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

with:

```dart
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
```

- [ ] **Step 3: Migrate the database schema**

In `lib/db/app_database.dart`, replace:

```dart
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
```

with:

```dart
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
```

- [ ] **Step 4: Verify it analyzes cleanly**

Run: `flutter analyze lib/models/transaction_item.dart lib/db/app_database.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/models/transaction_item.dart lib/db/app_database.dart
git commit -m "Add receipt column (v2 migration) and TransactionItem.receipt"
```

---

### Task 2: Platform permissions for camera/photo access

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Add the Android camera permission**

In `android/app/src/main/AndroidManifest.xml`, replace:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
```

with:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA"/>
    <application
```

- [ ] **Step 2: Add the iOS usage descriptions**

In `ios/Runner/Info.plist`, replace:

```xml
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
```

with:

```xml
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>NSCameraUsageDescription</key>
	<string>MyXpenses uses the camera to let you attach receipt photos to transactions.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>MyXpenses accesses your photo library to let you attach receipt photos to transactions.</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
```

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "Add camera/photo library permissions for receipt attachments"
```

---

### Task 3: Receipt picker UI in `AddTransactionScreen`

**Files:**
- Modify: `lib/screens/transaction_screen.dart`

**Interfaces:**
- Consumes: `TransactionItem.receipt` (Task 1), `image_picker`'s `ImagePicker`/`ImageSource`/`XFile` (Task 1's dependency).

- [ ] **Step 1: Add imports**

Replace:

```dart
import 'package:flutter/material.dart';

import '../models/transaction_item.dart';
```

with:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/transaction_item.dart';
```

- [ ] **Step 2: Add the `receiptBytes` state field**

Replace:

```dart
  DateTime selectedDate = DateTime.now();

  final List<String> expenseCategories = [
```

with:

```dart
  DateTime selectedDate = DateTime.now();
  Uint8List? receiptBytes;

  final List<String> expenseCategories = [
```

- [ ] **Step 3: Pre-fill from an existing transaction's receipt**

Replace:

```dart
    if (existing != null) {
      titleController.text = existing.title;
      amountController.text = existing.amount.toStringAsFixed(2);
      isIncome = existing.income;
      selectedCategory = existing.category;
      selectedDate = existing.date;
    }
  }
```

with:

```dart
    if (existing != null) {
      titleController.text = existing.title;
      amountController.text = existing.amount.toStringAsFixed(2);
      isIncome = existing.income;
      selectedCategory = existing.category;
      selectedDate = existing.date;
      receiptBytes = existing.receipt;
    }
  }
```

- [ ] **Step 4: Add `pickReceipt`/`removeReceipt`**

Replace:

```dart
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void saveTransaction() {
```

with:

```dart
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      receiptBytes = bytes;
    });
  }

  void removeReceipt() {
    setState(() {
      receiptBytes = null;
    });
  }

  void saveTransaction() {
```

- [ ] **Step 5: Include the receipt bytes on save**

Replace:

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

with:

```dart
    final transaction = TransactionItem(
      id: widget.existing?.id,
      title: title,
      category: selectedCategory,
      amount: amount,
      income: isIncome,
      date: selectedDate,
      receipt: receiptBytes,

      // Kalau model TransactionItem kau belum ada field ni,
      // jangan masukkan dulu.
      //
      // paymentMethod: selectedPaymentMethod,
      // wallet: selectedWallet,
      // note: noteController.text.trim(),
    );
```

- [ ] **Step 6: Add the Receipt section to the form**

Replace:

```dart
              label('Note (optional)'),

              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: inputDecoration(
                  hint: 'Add a note...',
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: saveTransaction,
```

with:

```dart
              label('Note (optional)'),

              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: inputDecoration(
                  hint: 'Add a note...',
                ),
              ),

              const SizedBox(height: 22),

              label('Receipt (optional)'),

              if (receiptBytes == null)
                InkWell(
                  onTap: pickReceipt,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE1D8D5),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF277765),
                        ),
                        SizedBox(height: 8),
                        Text('Add Receipt Photo'),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        receiptBytes!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: removeReceipt,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: saveTransaction,
```

- [ ] **Step 7: Verify it analyzes cleanly**

Run: `flutter analyze lib/screens/transaction_screen.dart`
Expected: only the pre-existing `deprecated_member_use` info-level notices already present before this change. No new issues.

- [ ] **Step 8: Commit**

```bash
git add lib/screens/transaction_screen.dart
git commit -m "Add receipt photo picker to the transaction form"
```

---

### Task 4: Receipt indicator on `HistoryScreen`

**Files:**
- Modify: `lib/screens/history_screen.dart`

**Interfaces:**
- Consumes: `TransactionItem.receipt` (Task 1).

- [ ] **Step 1: Show an attachment icon next to the date when a receipt is present**

In `lib/screens/history_screen.dart`, inside `_buildTransactionCard`, replace the date `Text` (currently the last child of the details `Column`, right before that `Column`'s closing) with a `Row` containing the date and a conditional icon. Match the exact surrounding indentation already in the file (this section uses deep, generously-spaced nesting) — read the file immediately before editing to copy the precise current text, since the file has been reformatted since this plan was written. The change is:

Before (conceptually):

```dart
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
```

After (conceptually):

```dart
                    Row(
                      children: [
                        Text(
                          formatDate(
                            transaction.date,
                          ),

                          style: const TextStyle(
                            color: Color(0xFF74B9A8),
                            fontSize: 11,
                          ),
                        ),

                        if (transaction.receipt != null) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 12,
                            color: Color(0xFF9A9390),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
```

- [ ] **Step 2: Verify it analyzes cleanly**

Run: `flutter analyze`
Expected: only the same pre-existing, unrelated issues seen throughout this project's history (deprecated `withOpacity`/`value` notices, the stale `test/widget_test.dart` error). No new issues.

- [ ] **Step 3: Manually verify receipts end-to-end**

Use the `run` skill on web (the platform already confirmed working with sqflite in this environment):

- Add a transaction, attach a receipt via "Choose from Gallery" (camera may not be exercisable on a desktop browser without a webcam — that's fine, gallery/file-picker covers the same storage path), save.
- Confirm the History row shows the attachment icon.
- Tap the row to edit → confirm the thumbnail displays → remove it → save → confirm the icon disappears from the row.
- Hot-restart the app → confirm both the attached and the removed state persisted.
- Android camera/gallery/permission-prompt behavior is left to the user's own device/emulator, given this sandbox's emulator has been unreliable.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/history_screen.dart
git commit -m "Show a receipt-attached indicator on HistoryScreen rows"
```
