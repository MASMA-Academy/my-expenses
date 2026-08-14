// lib/screens/report_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class ReportScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final Future<void> Function() onReload;

  const ReportScreen({
    super.key,
    required this.transactions,
    required this.onReload,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // =========================================================
  // STATE
  // =========================================================

  String selectedPeriod = 'Month';

  DateTime referenceDate = DateTime.now();

  static const List<String> _shortMonths = [
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

  static const List<String> _fullMonths = [
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

  static const List<String> _knownCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Family',
    'Health',
  ];

  // =========================================================
  // PERIOD RANGE
  // =========================================================

  DateTime get _periodStart {
    switch (selectedPeriod) {
      case 'Week':
        final monday = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1),
        );

        return DateTime(monday.year, monday.month, monday.day);

      case 'Year':
        return DateTime(referenceDate.year, 1, 1);

      case 'Month':
      default:
        return DateTime(referenceDate.year, referenceDate.month, 1);
    }
  }

  DateTime get _periodEnd {
    switch (selectedPeriod) {
      case 'Week':
        final start = _periodStart;

        return DateTime(
          start.year,
          start.month,
          start.day,
          23,
          59,
          59,
        ).add(const Duration(days: 6));

      case 'Year':
        return DateTime(referenceDate.year, 12, 31, 23, 59, 59);

      case 'Month':
      default:
        final nextMonth = DateTime(
          referenceDate.year,
          referenceDate.month + 1,
          1,
        );

        return nextMonth.subtract(const Duration(seconds: 1));
    }
  }

  // =========================================================
  // PERIOD LABEL
  // =========================================================

  String get _periodLabel {
    switch (selectedPeriod) {
      case 'Week':
        final start = _periodStart;

        final end = start.add(const Duration(days: 6));

        if (start.month == end.month) {
          return '${_shortMonths[start.month - 1]} '
              '${start.day} - ${end.day}, '
              '${end.year}';
        }

        return '${_shortMonths[start.month - 1]} '
            '${start.day} - '
            '${_shortMonths[end.month - 1]} '
            '${end.day}, ${end.year}';

      case 'Year':
        return '${referenceDate.year}';

      case 'Month':
      default:
        return '${_fullMonths[referenceDate.month - 1]} '
            '${referenceDate.year}';
    }
  }

  // =========================================================
  // PREVIOUS
  // =========================================================

  void _goPrevious() {
    setState(() {
      switch (selectedPeriod) {
        case 'Week':
          referenceDate = referenceDate.subtract(const Duration(days: 7));
          break;

        case 'Year':
          referenceDate = DateTime(
            referenceDate.year - 1,
            referenceDate.month,
            referenceDate.day,
          );
          break;

        case 'Month':
        default:
          referenceDate = DateTime(
            referenceDate.year,
            referenceDate.month - 1,
            1,
          );
          break;
      }
    });
  }

  // =========================================================
  // NEXT
  // =========================================================

  void _goNext() {
    setState(() {
      switch (selectedPeriod) {
        case 'Week':
          referenceDate = referenceDate.add(const Duration(days: 7));
          break;

        case 'Year':
          referenceDate = DateTime(
            referenceDate.year + 1,
            referenceDate.month,
            referenceDate.day,
          );
          break;

        case 'Month':
        default:
          referenceDate = DateTime(
            referenceDate.year,
            referenceDate.month + 1,
            1,
          );
          break;
      }
    });
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: referenceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        referenceDate = picked;
      });
    }
  }

  // =========================================================
  // PERIOD TRANSACTIONS
  // =========================================================

  List<TransactionItem> get _periodTransactions {
    final start = _periodStart;
    final end = _periodEnd;

    final result = widget.transactions
        .where(
          (transaction) =>
              !transaction.date.isBefore(start) &&
              !transaction.date.isAfter(end),
        )
        .toList();

    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  // =========================================================
  // TOTAL INCOME
  // =========================================================

  double get _totalIncome {
    return _periodTransactions
        .where((transaction) => transaction.income)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // TOTAL EXPENSE
  // =========================================================

  double get _totalExpense {
    return _periodTransactions
        .where((transaction) => !transaction.income)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // BALANCE
  // =========================================================

  double get _balance {
    return _totalIncome - _totalExpense;
  }

  // =========================================================
  // CATEGORY BREAKDOWN
  // =========================================================

  Map<String, double> get _categoryBreakdown {
    final Map<String, double> totals = {
      for (final category in _knownCategories) category: 0.0,
      'Others': 0.0,
    };

    for (final transaction in _periodTransactions) {
      if (transaction.income) {
        continue;
      }

      final key = _knownCategories.contains(transaction.category)
          ? transaction.category
          : 'Others';

      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }

    return totals;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final hasData = _periodTransactions.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============================================
              // HEADER
              // =============================================

              _buildHeader(),

              const SizedBox(height: 8),

              const Text(
                'See where your money goes ✨',
                style: TextStyle(fontSize: 12, color: Color(0xFF9A8D88)),
              ),

              const SizedBox(height: 24),

              // =============================================
              // PERIOD SELECTOR
              // =============================================
              _buildPeriodSelector(),

              const SizedBox(height: 18),

              // =============================================
              // DATE NAVIGATOR
              // =============================================
              _buildDateNavigator(),

              const SizedBox(height: 22),

              if (!hasData)
                _buildEmptyState()
              else ...[
                // =========================================
                // OVERVIEW
                // =========================================

                _buildOverviewCard(),

                const SizedBox(height: 18),

                // =========================================
                // CATEGORY
                // =========================================
                _buildCategoryCard(),

                const SizedBox(height: 18),

                // =========================================
                // INCOME VS EXPENSE
                // =========================================
                _buildIncomeExpenseCard(),

                const SizedBox(height: 18),

                // =========================================
                // SUMMARY
                // =========================================
                _buildSummaryCard(),
              ],
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
          onPressed: widget.onReload,
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF347B69)),
        ),

        Container(
          width: 43,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE1F4EC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCDEAE0)),
          ),
          child: const Text('📊', style: TextStyle(fontSize: 21)),
        ),
      ],
    );
  }

  // =========================================================
  // PERIOD SELECTOR
  // =========================================================

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4E2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _periodButton(title: 'Week', emoji: '🌱'),
          _periodButton(title: 'Month', emoji: '🌸'),
          _periodButton(title: 'Year', emoji: '✨'),
        ],
      ),
    );
  }

  Widget _periodButton({required String title, required String emoji}) {
    final selected = selectedPeriod == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = title;
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
  // DATE NAVIGATOR
  // =========================================================

  Widget _buildDateNavigator() {
    return Row(
      children: [
        _dateArrowButton(icon: Icons.chevron_left_rounded, onTap: _goPrevious),

        const SizedBox(width: 9),

        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
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
                      _periodLabel,
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
        ),

        const SizedBox(width: 9),

        _dateArrowButton(icon: Icons.chevron_right_rounded, onTap: _goNext),
      ],
    );
  }

  Widget _dateArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
  // OVERVIEW CARD
  // =========================================================

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFFAF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF2E3DF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9B4AF).withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF403633),
                ),
              ),

              const SizedBox(width: 6),

              const Text('💖', style: TextStyle(fontSize: 17)),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selectedPeriod,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF96736D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _overviewMiniCard(
                  emoji: '💚',
                  title: 'Income',
                  amount: _totalIncome,
                  background: const Color(0xFFDFF3EB),
                  textColor: const Color(0xFF347B69),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _overviewMiniCard(
                  emoji: '🌸',
                  title: 'Expense',
                  amount: _totalExpense,
                  background: const Color(0xFFFFE5E7),
                  textColor: const Color(0xFFA64E4E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 21)),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF716763),
                    ),
                  ),
                ),

                Text(
                  'RM ${_balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _balance >= 0
                        ? const Color(0xFF277765)
                        : const Color(0xFFA64E4E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewMiniCard({
    required String emoji,
    required String title,
    required double amount,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),

          const SizedBox(height: 5),

          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SHARED CARD
  // =========================================================

  Widget _sectionCard({
    required String title,
    required String emoji,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E6E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF403633),
                ),
              ),

              const SizedBox(width: 6),

              Text(emoji, style: const TextStyle(fontSize: 17)),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  // =========================================================
  // CATEGORY CARD
  // =========================================================

  Widget _buildCategoryCard() {
    final breakdown = _categoryBreakdown;

    final entries = breakdown.entries
        .where((entry) => entry.value > 0)
        .toList();

    entries.sort((a, b) => b.value.compareTo(a.value));

    return _sectionCard(
      title: 'Spending by Category',
      emoji: '🌷',
      child: Column(
        children: [
          SizedBox(
            width: 175,
            height: 175,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(175, 175),
                  painter: _DonutPainter(
                    data: breakdown,
                    colorFor: _categoryColor,
                  ),
                ),

                Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
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

                      const SizedBox(height: 3),

                      FittedBox(
                        child: Text(
                          'RM ${_totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF403633),
                          ),
                        ),
                      ),

                      const Text(
                        '♡',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF2A6B3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ...entries.map((entry) {
            final percent = _totalExpense == 0
                ? 0.0
                : entry.value / _totalExpense * 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: _categoryColor(entry.key).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _categoryColor(entry.key).withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      _categoryEmoji(entry.key),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF625C5A),
                      ),
                    ),
                  ),

                  Text(
                    'RM ${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF302C2B),
                    ),
                  ),

                  const SizedBox(width: 9),

                  Container(
                    width: 47,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D817D),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================
  // INCOME VS EXPENSE
  // =========================================================

  Widget _buildIncomeExpenseCard() {
    final maxValue = math.max(_totalIncome, math.max(_totalExpense, 1.0));

    const maxBarHeight = 115.0;

    return _sectionCard(
      title: 'Income vs Expense',
      emoji: '💸',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _incomeExpenseBar(
            emoji: '💚',
            label: 'Income',
            amount: _totalIncome,
            barHeight: maxBarHeight * (_totalIncome / maxValue),
            barColor: const Color(0xFF8FD2BE),
            labelColor: const Color(0xFF347B69),
          ),

          _incomeExpenseBar(
            emoji: '🌸',
            label: 'Expense',
            amount: _totalExpense,
            barHeight: maxBarHeight * (_totalExpense / maxValue),
            barColor: const Color(0xFFFFB6BC),
            labelColor: const Color(0xFFA64E4E),
          ),
        ],
      ),
    );
  }

  Widget _incomeExpenseBar({
    required String emoji,
    required String label,
    required double amount,
    required double barHeight,
    required Color barColor,
    required Color labelColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),

          const SizedBox(height: 12),

          Container(
            width: 62,
            height: barHeight < 10 ? 10 : barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
                bottom: Radius.circular(5),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            child: Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8D817D)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _buildSummaryCard() {
    return _sectionCard(
      title: '$selectedPeriod Summary',
      emoji: '✨',
      child: Column(
        children: [
          _summaryRow(
            emoji: '💚',
            label: 'Income',
            amount: _totalIncome,
            background: const Color(0xFFE2F4ED),
            textColor: const Color(0xFF347B69),
          ),

          const SizedBox(height: 9),

          _summaryRow(
            emoji: '🌸',
            label: 'Expense',
            amount: _totalExpense,
            background: const Color(0xFFFFE7E9),
            textColor: const Color(0xFFA64E4E),
          ),

          const SizedBox(height: 9),

          _summaryRow(
            emoji: _balance >= 0 ? '🌱' : '🥺',
            label: 'Balance',
            amount: _balance,
            background: _balance >= 0
                ? const Color(0xFFE7F6F0)
                : const Color(0xFFFFECEC),
            textColor: _balance >= 0
                ? const Color(0xFF277765)
                : const Color(0xFFA64E4E),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String emoji,
    required String label,
    required double amount,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),

          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
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
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF5F2)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFF1E6E3)),
      ),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9ED),
              shape: BoxShape.circle,
            ),
            child: const Text('🌱', style: TextStyle(fontSize: 37)),
          ),

          const SizedBox(height: 14),

          const Text(
            'No report data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F4643),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'No transactions found for $_periodLabel.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9A8D88)),
          ),

          const SizedBox(height: 5),

          const Text(
            'Your financial story will appear here ✨',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFFB09F9A)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CATEGORY COLOR
  // =========================================================

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFF8ED8A5);

      case 'Transport':
        return const Color(0xFFFFB4BB);

      case 'Shopping':
        return const Color(0xFFD8CCFF);

      case 'Bills':
        return const Color(0xFFFFD887);

      case 'Family':
        return const Color(0xFFFFCDBD);

      case 'Health':
        return const Color(0xFFFFAFC1);

      default:
        return const Color(0xFFDCD5EE);
    }
  }

  // =========================================================
  // CATEGORY EMOJI
  // =========================================================

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Food':
        return '🍔';

      case 'Transport':
        return '🚗';

      case 'Shopping':
        return '🛍️';

      case 'Bills':
        return '💡';

      case 'Family':
        return '🏡';

      case 'Health':
        return '💖';

      default:
        return '✨';
    }
  }
}

// =========================================================
// DONUT PAINTER
// =========================================================

class _DonutPainter extends CustomPainter {
  final Map<String, double> data;

  final Color Function(String category) colorFor;

  _DonutPainter({required this.data, required this.colorFor});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    final rect = Offset.zero & size;

    final strokeWidth = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      paint.color = const Color(0xFFF4E5E3);

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        0,
        2 * math.pi,
        false,
        paint,
      );

      return;
    }

    double startAngle = -math.pi / 2;

    const gap = 0.035;

    for (final entry in data.entries) {
      if (entry.value <= 0) {
        continue;
      }

      final fullSweep = (entry.value / total) * 2 * math.pi;

      final sweep = math.max(0.0, fullSweep - gap);

      paint.color = colorFor(entry.key);

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.data.toString() != data.toString();
  }
}
