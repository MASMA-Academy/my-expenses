import 'package:flutter/material.dart';

import 'models/transaction_item.dart';
import 'screens/transaction_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const MyXpensesApp());
}

class MyXpensesApp extends StatelessWidget {
  const MyXpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyXpenses',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF74B9A8),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<TransactionItem> transactions = [];

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HistoryScreen(
      transactions: transactions,
      onAddTransaction: openAddTransaction,
    );
  }
}