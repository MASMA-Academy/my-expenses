// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../models/transaction_item.dart';

class DashboardScreen extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;
  final VoidCallback onOpenHistory;

  const DashboardScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onOpenHistory,
  });

  // =========================================================
  // CALCULATION
  // =========================================================

  double get totalIncome {
    return transactions
        .where((item) => item.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return transactions
        .where((item) => !item.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balance => totalIncome - totalExpense;

  double categoryTotal(String category) {
    return transactions
        .where(
          (item) => !item.income && item.category == category,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final recentTransactions =
        transactions.reversed.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================

              _buildHeader(),

              const SizedBox(height: 20),

              // =================================================
              // GREETING
              // =================================================

              const Text(
                'Good morning! 💖',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF292323),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Let's make today count 💚",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B8583),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // BALANCE CARD
              // =================================================

              _buildBalanceCard(),

              const SizedBox(height: 28),

              // =================================================
              // OVERVIEW TITLE
              // =================================================

              const Text(
                'August 2026 Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF292323),
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // OVERVIEW CARD
              // =================================================

              _buildOverviewCard(),

              const SizedBox(height: 28),

              // =================================================
              // RECENT HEADER
              // =================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF292323),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: onOpenHistory,
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF277765),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =================================================
              // RECENT TRANSACTIONS
              // =================================================

              if (recentTransactions.isEmpty)
                _buildEmptyState()
              else
                ...recentTransactions.map(
                  (item) => _buildTransactionCard(item),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'MyXpenses',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF277765),
          ),
        ),

        const Spacer(),

        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFF4ECEA),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF277765),
            size: 24,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BALANCE
  // =========================================================

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: const Color(0xFF7EBBA9),
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF205E52),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'RM ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Color(0xFF064D43),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _buildBalanceMiniCard(
                  title: 'Income',
                  amount: totalIncome,
                  income: true,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildBalanceMiniCard(
                  title: 'Expenses',
                  amount: totalExpense,
                  income: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceMiniCard({
    required String title,
    required double amount,
    required bool income,
  }) {
    final Color color = income
        ? const Color(0xFF347B69)
        : const Color(0xFFA75A5A);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: income
                  ? const Color(0xFFC9F2E5)
                  : const Color(0xFFFFDCDD),
              shape: BoxShape.circle,
            ),

            child: Icon(
              income
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 19,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OVERVIEW
  // =========================================================

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // Simple chart
          _buildPieChart(),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              children: [
                _buildCategoryRow(
                  color: const Color(0xFF7EBBA9),
                  title: 'Food',
                  amount: categoryTotal('Food'),
                ),

                const SizedBox(height: 10),

                _buildCategoryRow(
                  color: const Color(0xFFFFA6AA),
                  title: 'Transport',
                  amount: categoryTotal('Transport'),
                ),

                const SizedBox(height: 10),

                _buildCategoryRow(
                  color: const Color(0xFFFFD7D7),
                  title: 'Shopping',
                  amount: categoryTotal('Shopping'),
                ),

                const SizedBox(height: 10),

                _buildCategoryRow(
                  color: const Color(0xFFD4D0C8),
                  title: 'Bills',
                  amount: categoryTotal('Bills'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SIMPLE DONUT / PIE STYLE
  // =========================================================

  Widget _buildPieChart() {
    return SizedBox(
      width: 110,
      height: 110,

      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 105,
            height: 105,

            child: CircularProgressIndicator(
              value: totalExpense == 0 ? 0 : 1,
              strokeWidth: 26,
              backgroundColor: const Color(0xFFF4E5E3),
              color: const Color(0xFF7EBBA9),
            ),
          ),

          Container(
            width: 58,
            height: 58,

            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),

            alignment: Alignment.center,

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

                Text(
                  'RM ${totalExpense.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4B4543),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CATEGORY
  // =========================================================

  Widget _buildCategoryRow({
    required Color color,
    required String title,
    required double amount,
  }) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,

          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF625C5A),
            ),
          ),
        ),

        Text(
          'RM ${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF302C2B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TRANSACTION
  // =========================================================

  Widget _buildTransactionCard(
    TransactionItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),

      child: Row(
        children: [
          // Emoji
          Container(
            width: 46,
            height: 46,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: item.income
                  ? const Color(0xFFE1F4E9)
                  : _categoryBackground(item.category),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              item.emoji,
              style: const TextStyle(
                fontSize: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF292525),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.income ? '+' : '-'} RM ${item.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: item.income
                      ? const Color(0xFF347B69)
                      : const Color(0xFFA75A5A),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                _isToday(item.date)
                    ? 'Today'
                    : _formatDate(item.date),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.chevron_right_rounded,
            size: 21,
            color: Color(0xFF888888),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          const Text(
            '🌱',
            style: TextStyle(
              fontSize: 38,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Start tracking your expenses today.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: onAddTransaction,

            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF277765),
              foregroundColor: Colors.white,
            ),

            icon: const Icon(
              Icons.add_rounded,
            ),

            label: const Text(
              'Add Transaction',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  Color _categoryBackground(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFFE7DD);

      case 'Transport':
        return const Color(0xFFFFE1E4);

      case 'Shopping':
        return const Color(0xFFE9E2FF);

      case 'Bills':
        return const Color(0xFFFFF1C9);

      default:
        return const Color(0xFFFFECE9);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }
}