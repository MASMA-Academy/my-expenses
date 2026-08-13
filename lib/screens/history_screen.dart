import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class HistoryScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;

  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedFilter = 'All';

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> result;

    if (selectedFilter == 'Income') {
      result = widget.transactions
          .where(
            (transaction) => transaction.income,
          )
          .toList();
    } else if (selectedFilter == 'Expense') {
      result = widget.transactions
          .where(
            (transaction) => !transaction.income,
          )
          .toList();
    } else {
      result = List.from(
        widget.transactions,
      );
    }

    result.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return result;
  }

  double get totalIncome {
    return widget.transactions
        .where(
          (transaction) => transaction.income,
        )
        .fold(
          0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  double get totalExpense {
    return widget.transactions
        .where(
          (transaction) => !transaction.income,
        )
        .fold(
          0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 25),

                    _buildFilter(),

                    const SizedBox(height: 22),

                    _buildSummary(),

                    const SizedBox(height: 28),

                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (transactions.isEmpty)
                      _buildEmptyState()
                    else
                      ...transactions.map(
                        (transaction) =>
                            _buildTransactionCard(
                          transaction,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: widget.onAddTransaction,

      //   backgroundColor: const Color(0xFF277765),
      //   foregroundColor: Colors.white,

      //   elevation: 3,

      //   shape: const CircleBorder(),

      //   child: const Icon(
      //     Icons.add_rounded,
      //     size: 32,
      //   ),
      // ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Text(
          'MyXpenses',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF51423E),
          ),
        ),

        Spacer(),

        Icon(
          Icons.receipt_long_outlined,
          color: Color(0xFF74B9A8),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: const Color(0xFFECE2E0),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        children: [
          _filterButton('All'),
          _filterButton('Income'),
          _filterButton('Expense'),
        ],
      ),
    );
  }

  Widget _filterButton(String title) {
    final selected = selectedFilter == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = title;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ),

          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),

          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF74B9A8)
                : Colors.transparent,

            borderRadius: BorderRadius.circular(25),
          ),

          child: Text(
            title,

            textAlign: TextAlign.center,

            style: TextStyle(
              color: selected
                  ? const Color(0xFF174F43)
                  : const Color(0xFF6D6260),

              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Total Income',
            amount: totalIncome,
            background: const Color(0xFFDFF3EB),
            textColor: const Color(0xFF347B69),
            icon: Icons.arrow_downward_rounded,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _summaryCard(
            title: 'Total Expenses',
            amount: totalExpense,
            background: const Color(0xFFFFE5E5),
            textColor: const Color(0xFFA64E4E),
            icon: Icons.arrow_upward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required Color background,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 20,
          ),

          const SizedBox(height: 5),

          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            child: Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(top: 20),

      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),

      child: const Column(
        children: [
          Text(
            '🌱',
            style: TextStyle(
              fontSize: 42,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Tap the + button to add your first transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

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

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFFE8C8);

      case 'Transport':
        return const Color(0xFFFFE0E4);

      case 'Shopping':
        return const Color(0xFFE6E1FF);

      case 'Bills':
        return const Color(0xFFFFF4BF);

      default:
        return const Color(0xFFFFECE9);
    }
  }

  String formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}