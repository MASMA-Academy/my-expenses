# Transaction Receipt Attachments — Design Spec

## Context

MyXpenses persists transactions via sqflite (mobile: native plugin; web:
`sqflite_common_ffi_web`, added in [[2026-08-13-sqflite-persistence-design]])
and supports add/edit/delete
([[2026-08-13-edit-delete-transactions-design]]). The user asked whether a
receipt file can be attached per transaction, and chose to support this on
both mobile and web.

## Goals

- Let the user attach one photo (receipt) per transaction, taken with the
  camera or picked from the gallery, when adding or editing it.
- Store the photo as raw bytes in a new `receipt BLOB` column on the
  `transactions` table — the same column and code path works on both mobile
  (`sqflite`) and web (`sqflite_common_ffi_web`), since both map BLOB columns
  to Dart `Uint8List`. No file paths, no `path_provider`, no platform
  branching for storage.
- Show a thumbnail of the attached receipt in the transaction form, with a
  way to remove it.
- Show a small indicator on `HistoryScreen` rows that have a receipt
  attached.

## Non-goals

- No full-screen zoom/lightbox viewer for the receipt — the thumbnail in the
  edit form is enough for this pass.
- Only one receipt per transaction, not multiple.
- No custom image resizing/compression pipeline — `image_picker`'s built-in
  `imageQuality` parameter (JPEG re-encode quality, no extra code) is used as
  a cheap mitigation for DB bloat, but there's no dedicated resize step
  beyond that.

## Dependency

- `image_picker` — works on Android/iOS/web without extra setup files
  (unlike sqflite's web story, which needed generated wasm/worker assets).

## Schema migration

`transactions` gains a nullable `receipt BLOB` column. Since the table
already exists at `version: 1` in installs that have already run the app
(this sandbox's Chrome IndexedDB, any emulator runs), this requires bumping
the database version and adding `onUpgrade`, not just changing `onCreate`:

```dart
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
      await db.execute('ALTER TABLE transactions ADD COLUMN receipt BLOB');
    }
  },
);
```

`insertTransaction`/`updateTransaction`/`getTransactions` in `AppDatabase`
are otherwise unchanged — `item.toMap()`/`TransactionItem.fromMap` now
include the `receipt` key, which flows through automatically.

## Model change

`lib/models/transaction_item.dart`: add `final Uint8List? receipt;` (needs
`import 'dart:typed_data';`), included in the constructor (optional,
defaults to `null`), `toMap()` (`'receipt': receipt`), `fromMap()`
(`receipt: map['receipt'] as Uint8List?`), and `copyWith()`.

## `AddTransactionScreen` changes

- New state: `Uint8List? receiptBytes;`, initialized from
  `widget.existing?.receipt` in the existing `initState()` (added in the
  edit-mode work).
- New method `pickReceipt()`: shows a small bottom sheet with "Take Photo"
  (`ImageSource.camera`) / "Choose from Gallery" (`ImageSource.gallery`),
  then `ImagePicker().pickImage(source: ..., imageQuality: 80)`, reads bytes
  via `picked.readAsBytes()`, and `setState`s `receiptBytes`.
- New "Receipt (optional)" section in the form, placed after the existing
  "Note" field and before the save button: a placeholder tappable card when
  `receiptBytes == null` ("Add Receipt Photo"), or a thumbnail
  (`Image.memory(receiptBytes!)`) with a small circular "×" button
  (top-right, via `Stack`/`Positioned`) that clears it back to `null`.
- `saveTransaction()`'s constructed `TransactionItem` includes
  `receipt: receiptBytes`.

## `HistoryScreen` change

In `_buildTransactionCard`, the date `Text` becomes a `Row` that also shows
a small `Icons.attach_file_rounded` icon (12px, muted color) next to the
date when `transaction.receipt != null`.

## Platform configuration

Required for the camera/gallery picker to actually function — not optional
polish:

- `android/app/src/main/AndroidManifest.xml`: add `<uses-permission
  android:name="android.permission.CAMERA"/>`.
- `ios/Runner/Info.plist`: add `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription` string entries (iOS blocks/crashes camera
  and photo library access without these).

## Error handling

If the user cancels the picker (no photo selected), `pickImage` returns
`null` and nothing changes — already handled by the early return in
`pickReceipt()`. No other error handling is added, consistent with the rest
of the app's posture on local, low-risk I/O.

## Testing / verification

- `flutter analyze` must pass with no new issues.
- Manual verification via the `run` skill, on web (the platform already
  confirmed working with sqflite in this environment) — the camera option
  may not be exercisable on a desktop browser without a webcam, so the
  gallery/file-picker path is the primary one to verify here; Android manual
  verification (both camera and gallery, plus the permission prompt) is
  left to the user's own device/emulator given this sandbox's emulator has
  been unreliable:
  - Add a transaction with a receipt photo attached via "Choose from
    Gallery" → save → confirm it appears in History with the attachment
    icon.
  - Tap that transaction to edit → confirm the receipt thumbnail shows →
    remove it → save → confirm the icon disappears from the History row.
  - Hot-restart the app → confirm the receipt (or its removal) persisted.
- No automated tests added, consistent with the rest of the app.
