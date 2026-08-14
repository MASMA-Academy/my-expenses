import 'dart:convert';

import 'package:file_saver/file_saver.dart';

import '../models/transaction_item.dart';

/// Saves all transactions as a CSV file into the device's Downloads folder
/// (on Android/iOS this goes through the OS save-file flow; on web it
/// triggers a browser download) and returns wherever the platform reports
/// it was saved.
Future<String> exportTransactionsToCsv(
  List<TransactionItem> transactions,
) async {
  final buffer = StringBuffer();

  buffer.writeln(
    'Date,Title,Category,Type,Amount,Payment Method,Wallet,Note',
  );

  for (final transaction in transactions) {
    buffer.writeln(
      [
        _formatDate(transaction.date),
        _csvField(transaction.title),
        _csvField(transaction.category),
        transaction.income ? 'Income' : 'Expense',
        transaction.amount.toStringAsFixed(2),
        _csvField(transaction.paymentMethod),
        _csvField(transaction.wallet),
        _csvField(transaction.note),
      ].join(','),
    );
  }

  final fileName = 'myxpenses_export_${DateTime.now().millisecondsSinceEpoch}';

  return FileSaver.instance.saveFile(
    name: fileName,
    bytes: utf8.encode(buffer.toString()),
    fileExtension: 'csv',
    mimeType: MimeType.csv,
  );
}

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }

  return value;
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
