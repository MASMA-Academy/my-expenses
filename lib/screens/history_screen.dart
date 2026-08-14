import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/transaction_item.dart';
import '../utils/csv_export.dart';

class HistoryScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;

  final void Function(TransactionItem transaction) onEditTransaction;

  final void Function(TransactionItem transaction) onDeleteTransaction;

  final Future<void> Function() onReload;

  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onReload,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // =========================================================
  // SEARCH
  // =========================================================

  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // EXPORT
  // =========================================================

  Future<void> _exportToCsv() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Export isn't available on web yet."),
        ),
      );

      return;
    }

    final path = await exportTransactionsToCsv(widget.transactions);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $path')),
    );
  }

  // =========================================================
  // FILTER
  // =========================================================

  String selectedFilter = 'All';

  // =========================================================
  // SELECTED MONTH
  // =========================================================

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // =========================================================
  // MONTHS
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
    return '${months[selectedMonth.month - 1]} '
        '${selectedMonth.year}';
  }

  // =========================================================
  // TRANSACTIONS FOR MONTH
  // =========================================================

  List<TransactionItem> get monthTransactions {
    return widget.transactions.where((transaction) {
      return transaction.date.year == selectedMonth.year &&
          transaction.date.month == selectedMonth.month;
    }).toList();
  }

  // =========================================================
  // FILTERED TRANSACTIONS
  // =========================================================

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> result = List<TransactionItem>.from(
      monthTransactions,
    );

    if (selectedFilter == 'Income') {
      result = result.where((transaction) => transaction.income).toList();
    } else if (selectedFilter == 'Expense') {
      result = result.where((transaction) => !transaction.income).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();

      result = result
          .where(
            (transaction) => transaction.title.toLowerCase().contains(query),
          )
          .toList();
    }

    // latest first
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  // =========================================================
  // TOTAL INCOME
  // =========================================================

  double get totalIncome {
    return monthTransactions
        .where((transaction) => transaction.income)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // TOTAL EXPENSE
  // =========================================================

  double get totalExpense {
    return monthTransactions
        .where((transaction) => !transaction.income)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // BALANCE FOR MONTH
  // =========================================================

  double get monthBalance {
    return totalIncome - totalExpense;
  }

  // =========================================================
  // MONTH NAVIGATION
  // =========================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============================
              // HEADER
              // =============================

              _buildHeader(),

              const SizedBox(height: 8),

              const Text(
                'Your spending story, one '
                'transaction at a time ✨',
                style: TextStyle(fontSize: 12, color: Color(0xFF9A8D88)),
              ),

              const SizedBox(height: 24),

              // =============================
              // SEARCH
              // =============================
              _buildSearchField(),

              const SizedBox(height: 14),

              // =============================
              // FILTER
              // =============================
              _buildFilter(),

              const SizedBox(height: 18),

              // =============================
              // MONTH
              // =============================
              _buildMonthSelector(),

              const SizedBox(height: 20),

              // =============================
              // SUMMARY
              // =============================
              _buildSummary(),

              const SizedBox(height: 28),

              // =============================
              // TRANSACTION HEADER
              // =============================
              Row(
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF403633),
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Text('🧾', style: TextStyle(fontSize: 18)),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${transactions.length} '
                      '${transactions.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFA56570),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Text(
                selectedMonthLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9A8D88),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 14),

              // =============================
              // TRANSACTION LIST
              // =============================
              if (transactions.isEmpty)
                _buildEmptyState()
              else
                ...transactions.map(
                  (transaction) => _buildTransactionCard(transaction),
                ),

              const SizedBox(height: 12),
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
            color: Color(0xFF51423E),
          ),
        ),

        const Spacer(),

        IconButton(
          onPressed: _exportToCsv,
          icon: const Icon(
            Icons.file_download_outlined,
            color: Color(0xFF74B9A8),
          ),
        ),

        IconButton(
          onPressed: widget.onReload,
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF74B9A8)),
        ),

        Container(
          width: 43,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8ED),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6D7DC)),
          ),
          child: const Text('🧾', style: TextStyle(fontSize: 21)),
        ),
      ],
    );
  }

  // =========================================================
  // SEARCH FIELD
  // =========================================================

  Widget _buildSearchField() {
    return Container(
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
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: const TextStyle(color: Color(0xFF9A8D88), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9A8D88),
          ),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    searchController.clear();

                    setState(() {
                      searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF9A8D88),
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FILTER
  // =========================================================

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4E2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _filterButton(title: 'All', emoji: '✨'),
          _filterButton(title: 'Income', emoji: '💚'),
          _filterButton(title: 'Expense', emoji: '🌸'),
        ],
      ),
    );
  }

  Widget _filterButton({required String title, required String emoji}) {
    final bool selected = selectedFilter == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFD9DE) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE9AAB3).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),

              const SizedBox(width: 5),

              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF925760)
                      : const Color(0xFF746966),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MONTH SELECTOR
  // =========================================================

  Widget _buildMonthSelector() {
    return Row(
      children: [
        _monthButton(icon: Icons.chevron_left_rounded, onTap: previousMonth),

        const SizedBox(width: 9),

        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFF0DFDC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🗓️', style: TextStyle(fontSize: 18)),

                const SizedBox(width: 8),

                Flexible(
                  child: Text(
                    selectedMonthLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF544B48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 9),

        _monthButton(icon: Icons.chevron_right_rounded, onTap: nextMonth),
      ],
    );
  }

  Widget _monthButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E8),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF5D2D2)),
        ),
        child: Icon(icon, color: const Color(0xFFB56C6C), size: 25),
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummary() {
    return Column(
      children: [
        // Balance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDDF3EB), Color(0xFFF0FBF7)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFCDEAE0)),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('💰', style: TextStyle(fontSize: 22)),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Monthly Balance',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF55746A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                'RM ${monthBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: monthBalance >= 0
                      ? const Color(0xFF277765)
                      : const Color(0xFFA64E4E),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                emoji: '💚',
                title: 'Total Income',
                amount: totalIncome,
                background: const Color(0xFFE1F4EC),
                textColor: const Color(0xFF347B69),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                emoji: '🌸',
                title: 'Total Expenses',
                amount: totalExpense,
                background: const Color(0xFFFFE6E8),
                textColor: const Color(0xFFA64E4E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String emoji,
    required String title,
    required double amount,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 19)),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
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
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF5F2)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E6E3)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9ED),
              shape: BoxShape.circle,
            ),
            child: const Text('🌱', style: TextStyle(fontSize: 35)),
          ),

          const SizedBox(height: 13),

          Text(
            'No transactions in '
            '$selectedMonthLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F4643),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your wallet is having '
            'a peaceful month ✨',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9A8D88), fontSize: 12),
          ),

          const SizedBox(height: 17),

          ElevatedButton(
            onPressed: widget.onAddTransaction,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF77B6A5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌸', style: TextStyle(fontSize: 15)),
                SizedBox(width: 7),
                Text(
                  'Add Transaction',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRANSACTION CARD
  // =========================================================

  Widget _buildTransactionCard(TransactionItem transaction) {
    final categoryColor = getCategoryColor(transaction.category);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,

      confirmDismiss: (_) => _confirmDelete(transaction),

      onDismissed: (_) {
        widget.onDeleteTransaction(transaction);
      },

      // DELETE BACKGROUND
      background: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE47B7B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('🗑️', style: TextStyle(fontSize: 19)),

            SizedBox(width: 7),

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

      child: InkWell(
        onTap: () {
          widget.onEditTransaction(transaction);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: categoryColor.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // EMOJI
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: transaction.income
                      ? const Color(0xFFE1F4E9)
                      : categoryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  transaction.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),

              const SizedBox(width: 13),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF403633),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            transaction.category,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF908480),
                              fontSize: 11,
                            ),
                          ),
                        ),

                        const Text(
                          '  •  ',
                          style: TextStyle(
                            color: Color(0xFFC1B5B1),
                            fontSize: 10,
                          ),
                        ),

                        Text(
                          formatDate(transaction.date),
                          style: const TextStyle(
                            color: Color(0xFF74B9A8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (transaction.receipt != null) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 11,
                            color: Color(0xFF9A8D88),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // AMOUNT
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.income ? '+' : '-'} '
                    'RM ${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction.income
                          ? const Color(0xFF347B69)
                          : const Color(0xFFA64E4E),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    width: 29,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Color(0xFFB58C8C),
                    ),
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

  Future<bool> _confirmDelete(TransactionItem transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F6),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE3E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🥺', style: TextStyle(fontSize: 33)),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Delete transaction?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF403633),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Are you sure you want to delete '
                  '"${transaction.title}"?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B7C77),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF756865),
                          side: const BorderSide(color: Color(0xFFE6DAD7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Keep it 🌷'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFE47B7B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

    return '${date.day} '
        '${shortMonths[date.month - 1]} '
        '${date.year}';
  }
}
