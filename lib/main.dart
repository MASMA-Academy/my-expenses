import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'models/transaction_item.dart';
import 'db/app_database.dart';

import 'screens/transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/report_screen.dart';
import 'screens/budget_screen.dart';

void main() {
  // sqflite only talks to a real filesystem on Android/iOS/macOS.
  // On web it needs the IndexedDB-backed ffi factory instead.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF74B9A8)),
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
  // ==============================
  // INDEX
  // ==============================
  //
  // 0 = Dashboard
  // 1 = Report
  // 2 = Add Transaction
  // 3 = History
  // 4 = Budget

  int currentIndex = 0;

  // ==============================
  // DATA
  // ==============================

  List<TransactionItem> transactions = [];
  List<String> customCategoryNames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final loaded = await AppDatabase.instance.getTransactions();
    final customCategories = await AppDatabase.instance.getCustomCategories();

    if (!mounted) return;

    setState(() {
      transactions = loaded;
      customCategoryNames = customCategories
          .map((row) => row['title'] as String)
          .toList();
      _loading = false;
    });
  }

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
        builder: (context) => AddTransactionScreen(
          existing: existing,
          extraCategories: customCategoryNames,
        ),
      ),
    );

    if (result == null) return;

    if (result.id == null) {
      final inserted = await AppDatabase.instance.insertTransaction(result);

      if (!mounted) return;

      setState(() {
        transactions.add(inserted);

        // Lepas save balik Dashboard
        currentIndex = 0;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction saved ✅')));
    } else {
      await AppDatabase.instance.updateTransaction(result);

      if (!mounted) return;

      setState(() {
        final index = transactions.indexWhere((t) => t.id == result.id);

        if (index != -1) {
          transactions[index] = result;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction updated ✅')));
    }
  }

  Future<void> deleteTransaction(TransactionItem item) async {
    final id = item.id;
    if (id == null) return;

    await AppDatabase.instance.deleteTransaction(id);

    if (!mounted) return;

    setState(() {
      transactions.removeWhere((t) => t.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted 🗑️'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(item),
        ),
      ),
    );
  }

  Future<void> _undoDelete(TransactionItem item) async {
    final restored = await AppDatabase.instance.insertTransaction(
      TransactionItem(
        title: item.title,
        category: item.category,
        amount: item.amount,
        income: item.income,
        date: item.date,
        receipt: item.receipt,
        paymentMethod: item.paymentMethod,
        wallet: item.wallet,
        note: item.note,
      ),
    );

    if (!mounted) return;

    setState(() {
      transactions.add(restored);
    });
  }

  // ==============================
  // CHANGE PAGE
  // ==============================

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // ==============================
  // SCREEN
  // ==============================

  Widget getCurrentScreen() {
    switch (currentIndex) {
      case 0:
        return DashboardScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,

          // See All dekat Dashboard
          // terus buka History
          onOpenHistory: () {
            changePage(3);
          },
          onEditTransaction: openEditTransaction,
          onReload: _loadTransactions,
        );

      case 1:
        return ReportScreen(
          transactions: transactions,
          onReload: _loadTransactions,
        );

      case 3:
        return HistoryScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
          onEditTransaction: openEditTransaction,
          onDeleteTransaction: deleteTransaction,
          onReload: _loadTransactions,
        );

      case 4:
        return BudgetScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
          onReload: _loadTransactions,
        );

      default:
        return DashboardScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
          onOpenHistory: () {
            changePage(3);
          },
          onEditTransaction: openEditTransaction,
          onReload: _loadTransactions,
        );
    }
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF277765)),
        ),
      );
    }

    return Scaffold(
      body: getCurrentScreen(),

      // ==============================
      // BOTTOM MENU
      // ==============================
      bottomNavigationBar: Container(
        height: 85,

        decoration: const BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

          boxShadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),

        child: SafeArea(
          top: false,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              // ========================
              // HOME
              // ========================

              _navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),

              // ========================
              // REPORT
              // ========================
              _navItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Report',
                index: 1,
              ),

              // ========================
              // ADD
              // ========================
              GestureDetector(
                onTap: openAddTransaction,

                child: Container(
                  width: 58,
                  height: 58,

                  decoration: const BoxDecoration(
                    color: Color(0xFF277765),
                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),

              // ========================
              // HISTORY
              // ========================
              _navItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'History',
                index: 3,
              ),

              // ========================
              // BUDGET
              // ========================
              _navItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Budget',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================
  // NAV ITEM
  // ==============================

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool active = currentIndex == index;

    final Color color = active
        ? const Color(0xFF277765)
        : const Color(0xFFBBCBC5);

    return InkWell(
      onTap: () {
        changePage(index);
      },

      borderRadius: BorderRadius.circular(20),

      child: SizedBox(
        width: 60,
        height: 65,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(active ? activeIcon : icon, color: color, size: 24),

            const SizedBox(height: 4),

            Text(
              label,

              style: TextStyle(
                color: color,
                fontSize: 10,

                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
