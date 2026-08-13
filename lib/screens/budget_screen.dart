import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class BudgetScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;

  const BudgetScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _displayMonth;

  /*
  Kita simpan LIMIT sahaja.

  SPENT akan dikira daripada transaction temporary.
  */
  final List<BudgetCategory> _categories = [
    BudgetCategory(
      title: 'Food',
      icon: Icons.fastfood,
      limit: 700,
      color: const Color(0xFF7BD389),
    ),
    BudgetCategory(
      title: 'Transport',
      icon: Icons.directions_car,
      limit: 500,
      color: const Color(0xFF7BD3D3),
    ),
    BudgetCategory(
      title: 'Shopping',
      icon: Icons.shopping_bag,
      limit: 800,
      color: const Color(0xFFFFC7C7),
    ),
    BudgetCategory(
      title: 'Bills',
      icon: Icons.receipt_long,
      limit: 600,
      color: const Color(0xFFFFD27A),
    ),
    BudgetCategory(
      title: 'Others',
      icon: Icons.more_horiz,
      limit: 400,
      color: const Color(0xFFD6C6FF),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _displayMonth = DateTime.now();
  }

  /*
  ========================================
  GET SPENT BY CATEGORY
  ========================================
  */

  double _getCategorySpent(String category) {
    return widget.transactions
        .where(
          (transaction) =>
              /*
              Expense sahaja
              */
              transaction.income == false &&

              /*
              Category mesti sama
              */
              transaction.category == category &&

              /*
              Bulan mesti sama
              */
              transaction.date.month == _displayMonth.month &&

              /*
              Tahun mesti sama
              */
              transaction.date.year == _displayMonth.year,
        )
        .fold(
          0.0,
          (total, transaction) => total + transaction.amount,
        );
  }

  /*
  ========================================
  TOTAL SPENT
  ========================================
  */

  double get _totalSpent {
    return widget.transactions
        .where(
          (transaction) =>
              transaction.income == false &&
              transaction.date.month == _displayMonth.month &&
              transaction.date.year == _displayMonth.year,
        )
        .fold(
          0.0,
          (total, transaction) => total + transaction.amount,
        );
  }

  /*
  ========================================
  TOTAL BUDGET LIMIT
  ========================================
  */

  double get _totalLimit {
    return _categories.fold(
      0.0,
      (total, category) => total + category.limit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F7),

      appBar: AppBar(
        title: const Text(
          'Budget',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFFF9F7),
        foregroundColor: Colors.black,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*
              MONTH SELECTOR
              */
              _buildMonthSelector(),

              const SizedBox(height: 12),

              /*
              MONTHLY BUDGET CARD
              */
              _buildMonthlyCard(media),

              const SizedBox(height: 24),

              const Text(
                'Budget by Category',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              /*
              CATEGORY LIST
              */
              ..._categories.map(
                (category) => _buildCategoryRow(category),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  ========================================
  MONTH SELECTOR
  ========================================
  */

  Widget _buildMonthSelector() {
    final monthText =
        '${_monthName(_displayMonth.month)} ${_displayMonth.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(
            Icons.chevron_left,
          ),
        ),

        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE8DFDC),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF277765),
                ),
              ],
            ),
          ),
        ),

        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(
            Icons.chevron_right,
          ),
        ),
      ],
    );
  }

  /*
  ========================================
  PREVIOUS MONTH
  ========================================
  */

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month - 1,
      );
    });
  }

  /*
  ========================================
  NEXT MONTH
  ========================================
  */

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + 1,
      );
    });
  }

  /*
  ========================================
  MONTHLY BUDGET CARD
  ========================================
  */

  Widget _buildMonthlyCard(Size media) {
    final percent = _totalLimit == 0
        ? 0.0
        : (_totalSpent / _totalLimit).clamp(
            0.0,
            1.0,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Budget',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              /*
              PIGGY IMAGE / ICON
              */
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '🐷',
                    style: TextStyle(
                      fontSize: 42,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*
                    TOTAL SPENT / LIMIT
                    */
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'RM ${_totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          TextSpan(
                            text:
                                ' / RM ${_totalLimit.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    /*
                    PROGRESS BAR
                    */
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFECE8E6),
                        valueColor:
                            const AlwaysStoppedAnimation(
                          Color(0xFF74B9A8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /*
                    PERCENTAGE
                    */
                    Text(
                      '${(percent * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF277765),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /*
          MESSAGE
          */
          Row(
            children: [
              Expanded(
                child: Text(
                  _budgetMessage(percent),
                  style: const TextStyle(
                    color: Color(0xFF6D6260),
                    fontSize: 13,
                  ),
                ),
              ),

              const Icon(
                Icons.favorite,
                color: Color(0xFF74B9A8),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /*
  ========================================
  CATEGORY ROW
  ========================================
  */

  Widget _buildCategoryRow(BudgetCategory category) {
    /*
    Inilah part penting.

    SPENT sekarang datang daripada
    temporary transactions.
    */
    final spent = _getCategorySpent(
      category.title,
    );

    final percent = category.limit == 0
        ? 0.0
        : (spent / category.limit).clamp(
            0.0,
            1.0,
          );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0E9E7),
        ),
      ),
      child: Row(
        children: [
          /*
          CATEGORY ICON
          */
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: category.color.withOpacity(
                0.20,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*
                TITLE + AMOUNT
                */
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    Text(
                      'RM ${spent.toStringAsFixed(2)} '
                      '/ RM ${category.limit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /*
                PROGRESS
                */
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: percent,
                    backgroundColor:
                        const Color(0xFFECE8E6),
                    valueColor:
                        AlwaysStoppedAnimation(
                      category.color,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                /*
                PERCENTAGE
                */
                Text(
                  '${(percent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
  ========================================
  BUDGET MESSAGE
  ========================================
  */

  String _budgetMessage(double percent) {
    if (percent >= 1) {
      return 'Budget limit reached! Be careful with your spending.';
    }

    if (percent >= 0.8) {
      return 'You have used more than 80% of your budget.';
    }

    if (percent >= 0.5) {
      return 'You are halfway through your monthly budget.';
    }

    return "You're doing great! Keep it up!";
  }

  /*
  ========================================
  MONTH NAME
  ========================================
  */

  String _monthName(int month) {
    const names = [
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

    return names[month - 1];
  }
}

/*
========================================
BUDGET CATEGORY MODEL
========================================
*/

class BudgetCategory {
  final String title;
  final IconData icon;

  /*
  spent dah dibuang sebab kita kira
  berdasarkan transactions
  */
  final double limit;

  final Color color;

  BudgetCategory({
    required this.title,
    required this.icon,
    required this.limit,
    required this.color,
  });
}