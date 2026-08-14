import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../models/transaction_item.dart';

/// Writes all transactions to a CSV file in app-accessible device storage
/// and returns the saved file's path. Not supported on web (no real
/// filesystem) — callers should guard with `kIsWeb` before calling this.
Future<String> exportTransactionsToCsv(
  List<TransactionItem> transactions,
) async {
  final buffer = StringBuffer();

  buffer.writeln('Date,Title,Category,Type,Amount,Payment Method,Wallet,Note');

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

  final directory = Platform.isAndroid
      ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
      : await getApplicationDocumentsDirectory();

  final fileName =
      'myxpenses_export_${DateTime.now().millisecondsSinceEpoch}.csv';

  final file = File('${directory.path}/$fileName');

  await file.writeAsString(buffer.toString());

  return file.path;
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
