import 'package:flutter/material.dart';

import 'models/transaction_item.dart';

import 'screens/transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/report_screen.dart';
import 'screens/budget_screen.dart';

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

  final List<TransactionItem> transactions = [];

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
      setState(() {
        transactions.add(result);

        // Lepas save balik Dashboard
        currentIndex = 0;
      });
    }
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
        );

      case 1:
        return ReportScreen(
          transactions: transactions,
        );

      case 3:
        return HistoryScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
        );

      case 4:
        return BudgetScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
        );

      default:
        return DashboardScreen(
          transactions: transactions,
          onAddTransaction: openAddTransaction,
          onOpenHistory: () {
            changePage(3);
          },
        );
    }
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getCurrentScreen(),

      // ==============================
      // BOTTOM MENU
      // ==============================

      bottomNavigationBar: Container(
        height: 85,

        decoration: const BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),

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
                icon: Icons.savings_outlined,
                activeIcon: Icons.savings_rounded,
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
            Icon(
              active ? activeIcon : icon,
              color: color,
              size: 24,
            ),

            const SizedBox(height: 4),

            Text(
              label,

              style: TextStyle(
                color: color,
                fontSize: 10,

                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}