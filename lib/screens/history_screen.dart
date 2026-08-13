import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class HistoryScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;
  final void Function(TransactionItem transaction) onEditTransaction;
  final void Function(TransactionItem transaction) onDeleteTransaction;

  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // =========================================================
  // FILTER
  // =========================================================

  String selectedFilter = 'All';

  // =========================================================
  // SELECTED MONTH
  // =========================================================

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // =========================================================
  // MONTH NAME
  // =========================================================

  static const List<String> months = [
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

  // =========================================================
  // SELECTED MONTH LABEL
  // =========================================================

  String get selectedMonthLabel {
    return '${months[selectedMonth.month - 1]} ${selectedMonth.year}';
  }

  // =========================================================
  // TRANSACTIONS FOR SELECTED MONTH
  // =========================================================

  List<TransactionItem> get monthTransactions {
    return widget.transactions.where(
      (transaction) {
        return transaction.date.year == selectedMonth.year &&
            transaction.date.month == selectedMonth.month;
      },
    ).toList();
  }

  // =========================================================
  // FILTERED TRANSACTIONS
  // =========================================================

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> result = List.from(
      monthTransactions,
    );

    if (selectedFilter == 'Income') {
      result = result
          .where(
            (transaction) => transaction.income,
          )
          .toList();
    } else if (selectedFilter == 'Expense') {
      result = result
          .where(
            (transaction) => !transaction.income,
          )
          .toList();
    }

    // Latest transaction first
    result.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return result;
  }

  // =========================================================
  // TOTAL INCOME FOR SELECTED MONTH
  // =========================================================

  double get totalIncome {
    return monthTransactions
        .where(
          (transaction) => transaction.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // =========================================================
  // TOTAL EXPENSE FOR SELECTED MONTH
  // =========================================================

  double get totalExpense {
    return monthTransactions
        .where(
          (transaction) => !transaction.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // =========================================================
  // PREVIOUS MONTH
  // =========================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  // =========================================================
  // NEXT MONTH
  // =========================================================

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

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
                    // ==============================
                    // HEADER
                    // ==============================

                    _buildHeader(),

                    const SizedBox(height: 25),

                    // ==============================
                    // ALL / INCOME / EXPENSE
                    // ==============================

                    _buildFilter(),

                    const SizedBox(height: 18),

                    // ==============================
                    // MONTH SELECTOR
                    // ==============================

                    _buildMonthSelector(),

                    const SizedBox(height: 22),

                    // ==============================
                    // SUMMARY
                    // ==============================

                    _buildSummary(),

                    const SizedBox(height: 28),

                    // ==============================
                    // TRANSACTION TITLE
                    // ==============================

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        Text(
                          '${transactions.length} item${transactions.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B8583),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==============================
                    // TRANSACTIONS
                    // ==============================

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
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

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

  // =========================================================
  // FILTER
  // =========================================================

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

  // =========================================================
  // MONTH SELECTOR
  // =========================================================

  Widget _buildMonthSelector() {
    return Container(
      height: 56,

      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

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
          // ==============================
          // PREVIOUS
          // ==============================

          IconButton(
            onPressed: previousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFF277765),
              size: 27,
            ),
          ),

          // ==============================
          // MONTH
          // ==============================

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Color(0xFF74B9A8),
                ),

                const SizedBox(width: 8),

                Flexible(
                  child: Text(
                    selectedMonthLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF51423E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==============================
          // NEXT
          // ==============================

          IconButton(
            onPressed: nextMonth,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF277765),
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

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

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(top: 10),

      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        children: [
          const Text(
            '🌱',
            style: TextStyle(
              fontSize: 42,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'No transactions in $selectedMonthLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Tap the + button to add a transaction.',
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

  // =========================================================
  // TRANSACTION CARD
  // =========================================================

  Widget _buildTransactionCard(
    TransactionItem transaction,
  ) {
    return Dismissible(
      key: ValueKey(transaction.id),

      direction: DismissDirection.endToStart,

      confirmDismiss: (_) =>
          _confirmDelete(transaction),

      onDismissed: (_) {
        widget.onDeleteTransaction(
          transaction,
        );
      },

      // ==============================
      // DELETE BACKGROUND
      // ==============================

      background: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
        ),

        alignment: Alignment.centerRight,

        decoration: BoxDecoration(
          color: const Color(0xFFE36C6C),
          borderRadius: BorderRadius.circular(18),
        ),

        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),

            SizedBox(width: 6),

            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      // ==============================
      // TRANSACTION
      // ==============================

      child: InkWell(
        onTap: () {
          widget.onEditTransaction(
            transaction,
          );
        },

        borderRadius: BorderRadius.circular(18),

        child: Container(
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
              // ==============================
              // EMOJI
              // ==============================

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

              // ==============================
              // DETAILS
              // ==============================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

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

              // ==============================
              // AMOUNT
              // ==============================

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,

                children: [
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

                  const SizedBox(height: 5),

                  const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: Color(0xFFB6B0AE),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DELETE CONFIRMATION
  // =========================================================

  Future<bool> _confirmDelete(
    TransactionItem transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete transaction?',
          ),

          content: Text(
            'This will permanently delete "${transaction.title}".',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFE36C6C),
                ),
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  // =========================================================
  // CATEGORY COLOR
  // =========================================================

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

      case 'Family':
        return const Color(0xFFDFF3EB);

      case 'Health':
        return const Color(0xFFFFDDE5);

      default:
        return const Color(0xFFFFECE9);
    }
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatDate(DateTime date) {
    const shortMonths = [
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

    return '${date.day} ${shortMonths[date.month - 1]} ${date.year}';
  }
}