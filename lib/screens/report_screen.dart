// lib/screens/report_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class ReportScreen extends StatefulWidget {
  final List<TransactionItem> transactions;

  const ReportScreen({
    super.key,
    required this.transactions,
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

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _knownCategories = [
    'Food', 'Transport', 'Shopping', 'Bills',
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
        return DateTime(start.year, start.month, start.day, 23, 59, 59)
            .add(const Duration(days: 6));

      case 'Year':
        return DateTime(referenceDate.year, 12, 31, 23, 59, 59);

      case 'Month':
      default:
        final nextMonth = DateTime(referenceDate.year, referenceDate.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
    }
  }

  String get _periodLabel {
    switch (selectedPeriod) {
      case 'Week':
        final start = _periodStart;
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${_months[start.month - 1]} ${start.day} - ${end.day}, ${end.year}';
        }
        return '${_months[start.month - 1]} ${start.day} - '
            '${_months[end.month - 1]} ${end.day}, ${end.year}';

      case 'Year':
        return '${referenceDate.year}';

      case 'Month':
      default:
        return '${_months[referenceDate.month - 1]} ${referenceDate.year}';
    }
  }

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
          referenceDate = DateTime(referenceDate.year, referenceDate.month - 1, 1);
          break;
      }
    });
  }

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
          referenceDate = DateTime(referenceDate.year, referenceDate.month + 1, 1);
          break;
      }
    });
  }

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
  // DATA
  // =========================================================

  List<TransactionItem> get _periodTransactions {
    final start = _periodStart;
    final end = _periodEnd;

    return widget.transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  double get _totalIncome => _periodTransactions
      .where((t) => t.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _periodTransactions
      .where((t) => !t.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _balance => _totalIncome - _totalExpense;

  Map<String, double> get _categoryBreakdown {
    final Map<String, double> totals = {
      for (final category in _knownCategories) category: 0.0,
      'Others': 0.0,
    };

    for (final t in _periodTransactions) {
      if (t.income) continue;
      final key = _knownCategories.contains(t.category) ? t.category : 'Others';
      totals[key] = (totals[key] ?? 0) + t.amount;
    }

    return totals;
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFF7EBBA9);
      case 'Transport':
        return const Color(0xFFFFA6AA);
      case 'Shopping':
        return const Color(0xFFD4C9BE);
      case 'Bills':
        return const Color(0xFFA8DDC5);
      default:
        return const Color(0xFFE4DEDB);
    }
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              _buildDateNavigator(),
              const SizedBox(height: 20),
              if (!hasData)
                _buildEmptyState()
              else ...[
                _buildCategoryCard(),
                const SizedBox(height: 20),
                _buildIncomeExpenseCard(),
                const SizedBox(height: 20),
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
    return const Center(
      child: Text(
        'Reports',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF292323),
        ),
      ),
    );
  }

  // =========================================================
  // PERIOD SELECTOR
  // =========================================================

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECE2E0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _periodButton('Week'),
          _periodButton('Month'),
          _periodButton('Year'),
        ],
      ),
    );
  }

  Widget _periodButton(String title) {
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF74B9A8) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF174F43) : const Color(0xFF6D6260),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DATE NAVIGATOR
  // =========================================================

  Widget _buildDateNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          IconButton(
            onPressed: _goPrevious,
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF277765)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _periodLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF292323),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF9A9390)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _goNext,
            icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF277765)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SHARED CARD SHELL
  // =========================================================

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF292323),
            ),
          ),
          const SizedBox(height: 16),
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
    final entries = breakdown.entries.where((e) => e.value > 0).toList();

    return _sectionCard(
      title: 'Spending by Category',
      child: Column(
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(170, 170),
                  painter: _DonutPainter(
                    data: breakdown,
                    colorFor: _categoryColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${_totalExpense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF292323),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: entries.map((entry) {
              final percent = _totalExpense == 0
                  ? 0.0
                  : (entry.value / _totalExpense * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _categoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF625C5A)),
                      ),
                    ),
                    Text(
                      'RM ${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF302C2B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9A9390)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INCOME VS EXPENSE CARD
  // =========================================================

  Widget _buildIncomeExpenseCard() {
    final maxValue = math.max(_totalIncome, math.max(_totalExpense, 1.0));
    const maxBarHeight = 110.0;

    return _sectionCard(
      title: 'Income vs Expense',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _incomeExpenseBar(
            emoji: '📈',
            label: 'Income',
            amount: _totalIncome,
            barHeight: maxBarHeight * (_totalIncome / maxValue),
            barColor: const Color(0xFF7EBBA9),
            labelColor: const Color(0xFF347B69),
          ),
          _incomeExpenseBar(
            emoji: '📉',
            label: 'Expense',
            amount: _totalExpense,
            barHeight: maxBarHeight * (_totalExpense / maxValue),
            barColor: const Color(0xFFFFA6AA),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 10),
        Container(
          width: 56,
          height: barHeight < 8.0 ? 8.0 : barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: labelColor),
        ),
        const SizedBox(height: 3),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
        ),
      ],
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _buildSummaryCard() {
    return _sectionCard(
      title: 'This $selectedPeriod Summary',
      child: Row(
        children: [
          Expanded(
            child: _summaryChip(
              label: 'Income',
              amount: _totalIncome,
              background: const Color(0xFFF4ECEA),
              textColor: const Color(0xFF277765),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryChip(
              label: 'Expense',
              amount: _totalExpense,
              background: const Color(0xFFFFE5E5),
              textColor: const Color(0xFFA64E4E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryChip(
              label: 'Balance',
              amount: _balance,
              background: const Color(0xFFDFF3EB),
              textColor: const Color(0xFF277765),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required double amount,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
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
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text('🌱', style: TextStyle(fontSize: 42)),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            'Add a transaction to see your report here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
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
    final total = data.values.fold(0.0, (sum, v) => sum + v);
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (total <= 0) {
      paint.color = const Color(0xFFF4E5E3);
      canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 2 * math.pi, false, paint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (final entry in data.entries) {
      if (entry.value <= 0) continue;
      final sweep = (entry.value / total) * 2 * math.pi;
      paint.color = colorFor(entry.key);
      canvas.drawArc(rect.deflate(strokeWidth / 2), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.data.toString() != data.toString() ||
        oldDelegate.colorFor != colorFor;
  }
}
