// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;
  final VoidCallback onOpenHistory;

  // =========================================================
  // CURRENT GREETING
  // =========================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning!';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon!';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good evening!';
    }

    return 'Good night!';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '🌸';
    }

    if (hour >= 12 && hour < 17) {
      return '☀️';
    }

    if (hour >= 17 && hour < 21) {
      return '🌷';
    }

    return '🌙';
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Let's start the day with smart spending 💚";
    }

    if (hour >= 12 && hour < 17) {
      return "Hope your day is going wonderfully ✨";
    }

    if (hour >= 17 && hour < 21) {
      return "Let's wrap up today beautifully 💕";
    }

    return "Rest well and recharge for tomorrow 🌙";
  }

  // =========================================================
  // CURRENT MONTH NAME
  // =========================================================

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

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
        .fold(
          0.0,
          (sum, item) => sum + item.amount,
        );
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

              Text(
                '${_getGreeting()} ${_getGreetingEmoji()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF292323),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _getGreetingMessage(),
                style: const TextStyle(
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

              Text(
                '${_monthName(DateTime.now().month)} '
                '${DateTime.now().year} Overview',
                style: const TextStyle(
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF277765).withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
          _buildPieChart(),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              children: [
                _buildCategoryRow(
                  emoji: '🍔',
                  color: const Color(0xFF7EBBA9),
                  title: 'Food',
                  amount: categoryTotal('Food'),
                ),

                const SizedBox(height: 10),

                _buildCategoryRow(
                  emoji: '🚗',
                  color: const Color(0xFFFFA6AA),
                  title: 'Transport',
                  amount: categoryTotal('Transport'),
                ),

                const SizedBox(height: 10),

                _buildCategoryRow(
                  emoji: '🛍️',
                  color: const Color(0xFFD9CCFF),
                  title: 'Shopping',
                  amount: categoryTotal('Shopping'),
                ),

                const SizedBox(height: 10),

                _buildCategoryRow(
                  emoji: '💡',
                  color: const Color(0xFFFFD89C),
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
  // SIMPLE PIE STYLE
  // =========================================================

  Widget _buildPieChart() {
  final food = categoryTotal('Food');
  final transport = categoryTotal('Transport');
  final shopping = categoryTotal('Shopping');
  final bills = categoryTotal('Bills');

  final total = food + transport + shopping + bills;

  if (total == 0) {
    return Container(
      width: 115,
      height: 115,
      decoration: const BoxDecoration(
        color: Color(0xFFF8ECEA),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '🌱\nNo data',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8B8583),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  return SizedBox(
    width: 120,
    height: 120,
    child: Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: -90,
            centerSpaceRadius: 36,
            sectionsSpace: 3,

            sections: [
              if (food > 0)
                PieChartSectionData(
                  value: food,
                  color: const Color(0xFF7EBBA9),
                  radius: 22,
                  showTitle: false,
                ),

              if (transport > 0)
                PieChartSectionData(
                  value: transport,
                  color: const Color(0xFFFFA6AA),
                  radius: 22,
                  showTitle: false,
                ),

              if (shopping > 0)
                PieChartSectionData(
                  value: shopping,
                  color: const Color(0xFFD9CCFF),
                  radius: 22,
                  showTitle: false,
                ),

              if (bills > 0)
                PieChartSectionData(
                  value: bills,
                  color: const Color(0xFFFFD89C),
                  radius: 22,
                  showTitle: false,
                ),
            ],
          ),
        ),

        Container(
          width: 65,
          height: 65,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9A8D88),
                ),
              ),

              const SizedBox(height: 2),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'RM ${totalExpense.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF403633),
                  ),
                ),
              ),

              const Text(
                '♡',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFF2A6B3),
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
    required String emoji,
    required Color color,
    required String title,
    required double amount,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(width: 8),

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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

      case 'Family':
        return const Color(0xFFFFE3D6);

      case 'Health':
        return const Color(0xFFFFDFE6);

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