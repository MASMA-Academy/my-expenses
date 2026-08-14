import 'package:flutter/material.dart';

import '../models/transaction_item.dart';
import '../db/app_database.dart';

class BudgetScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final VoidCallback onAddTransaction;
  final Future<void> Function() onReload;

  const BudgetScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onReload,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _displayMonth;

  String? _expandedCategory;

  final List<BudgetCategory> _categories = [
    BudgetCategory(
      title: 'Food',
      emoji: '🍔',
      limit: 700,
      color: const Color(0xFF8ED8A5),
    ),
    BudgetCategory(
      title: 'Transport',
      emoji: '🚗',
      limit: 500,
      color: const Color(0xFF8ED8D8),
    ),
    BudgetCategory(
      title: 'Shopping',
      emoji: '🛍️',
      limit: 800,
      color: const Color(0xFFF4B9C3),
    ),
    BudgetCategory(
      title: 'Bills',
      emoji: '💡',
      limit: 600,
      color: const Color(0xFFFFD27A),
    ),
    BudgetCategory(
      title: 'Family',
      emoji: '🏡',
      limit: 500,
      color: const Color(0xFFFFB9A7),
    ),
    BudgetCategory(
      title: 'Health',
      emoji: '💖',
      limit: 400,
      color: const Color(0xFFFF9FB0),
    ),
    BudgetCategory(
      title: 'Others',
      emoji: '✨',
      limit: 400,
      color: const Color(0xFFD6C6FF),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _displayMonth = DateTime.now();

    _loadCustomCategories();
    _loadBudgetLimits();
  }

  // =========================================================
  // LOAD CUSTOM CATEGORIES
  // =========================================================

  Future<void> _loadCustomCategories() async {
    final rows = await AppDatabase.instance.getCustomCategories();

    if (rows.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      for (final row in rows) {
        final title = row['title'] as String;

        final alreadyExists = _categories.any(
          (category) => category.title == title,
        );

        if (alreadyExists) {
          continue;
        }

        _categories.add(
          BudgetCategory(
            title: title,
            emoji: row['emoji'] as String,
            limit: 300,
            color: Color(row['color'] as int),
          ),
        );
      }
    });

    // Overlay saved limits onto the newly-added categories too.
    await _loadBudgetLimits();
  }

  // =========================================================
  // LOAD SAVED BUDGET
  // =========================================================

  Future<void> _loadBudgetLimits() async {
    final limits = await AppDatabase.instance.getBudgetLimits();

    if (limits.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      for (final category in _categories) {
        final savedLimit = limits[category.title];

        if (savedLimit != null) {
          category.limit = savedLimit;
        }
      }
    });
  }

  Future<void> _handleReload() async {
    await widget.onReload();
    await _loadCustomCategories();
    await _loadBudgetLimits();
  }

  // =========================================================
  // ADD CUSTOM CATEGORY
  // =========================================================

  static const List<String> _emojiChoices = [
    '✨',
    '🎮',
    '📚',
    '🐾',
    '🎁',
    '🚕',
    '🍿',
    '💻',
  ];

  static const List<Color> _colorChoices = [
    Color(0xFF8ED8A5),
    Color(0xFF8ED8D8),
    Color(0xFFF4B9C3),
    Color(0xFFFFD27A),
    Color(0xFFFFB9A7),
    Color(0xFFB9A7FF),
    Color(0xFFA7D2FF),
    Color(0xFFD6C6FF),
  ];

  void _showAddCategorySheet() {
    final nameController = TextEditingController();
    String selectedEmoji = _emojiChoices.first;
    Color selectedColor = _colorChoices.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4D4D1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Center(
                          child: Text(
                            'New Category',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF403633),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F4643),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Pets',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Icon',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F4643),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _emojiChoices.map((emoji) {
                            final selected = emoji == selectedEmoji;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedEmoji = emoji;
                                });
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFFFE0E0)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFE47B7B)
                                        : const Color(0xFFF1E6E3),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F4643),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _colorChoices.map((color) {
                            final selected = color == selectedColor;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF403633)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = nameController.text.trim();

                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a category name.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              final alreadyExists = _categories.any(
                                (category) =>
                                    category.title.toLowerCase() ==
                                    title.toLowerCase(),
                              );

                              if (alreadyExists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'That category already exists.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              await AppDatabase.instance.addCustomCategory(
                                title: title,
                                emoji: selectedEmoji,
                                color: selectedColor.toARGB32(),
                              );

                              if (!mounted) return;

                              setState(() {
                                _categories.add(
                                  BudgetCategory(
                                    title: title,
                                    emoji: selectedEmoji,
                                    limit: 300,
                                    color: selectedColor,
                                  ),
                                );
                              });

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('$title category added ✨'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF277765),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Add Category ✨',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // SPENT BY CATEGORY
  // =========================================================

  double _getCategorySpent(String category) {
    return widget.transactions
        .where(
          (transaction) =>
              !transaction.income &&
              transaction.category == category &&
              transaction.date.month == _displayMonth.month &&
              transaction.date.year == _displayMonth.year,
        )
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // TRANSACTIONS BY CATEGORY + MONTH
  // =========================================================

  List<TransactionItem> _getCategoryTransactions(String category) {
    final list = widget.transactions
        .where(
          (transaction) =>
              !transaction.income &&
              transaction.category == category &&
              transaction.date.month == _displayMonth.month &&
              transaction.date.year == _displayMonth.year,
        )
        .toList();

    list.sort((a, b) => b.date.compareTo(a.date));

    return list;
  }

  // =========================================================
  // TOTAL SPENT
  // =========================================================

  double get _totalSpent {
    return widget.transactions
        .where(
          (transaction) =>
              !transaction.income &&
              transaction.date.month == _displayMonth.month &&
              transaction.date.year == _displayMonth.year,
        )
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // =========================================================
  // TOTAL BUDGET LIMIT
  // =========================================================

  double get _totalLimit {
    return _categories.fold(0.0, (total, category) => total + category.limit);
  }

  // =========================================================
  // SORT CATEGORY
  // =========================================================

  List<BudgetCategory> get _sortedCategories {
    final list = List<BudgetCategory>.from(_categories);

    list.sort((a, b) {
      final aPercent = a.limit == 0
          ? 0.0
          : _getCategorySpent(a.title) / a.limit;

      final bPercent = b.limit == 0
          ? 0.0
          : _getCategorySpent(b.title) / b.limit;

      return bPercent.compareTo(aPercent);
    });

    return list;
  }

  // =========================================================
  // MONTH NAVIGATION
  // =========================================================

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);

      _expandedCategory = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);

      _expandedCategory = null;
    });
  }

  // =========================================================
  // SET BUDGET
  // =========================================================

  void _showSetBudgetSheet() {
    String selectedCategory = _categories.first.title;

    final budgetController = TextEditingController(
      text: _categories.first.limit.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4D4D1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Center(
                          child: Column(
                            children: [
                              Text('🌷', style: TextStyle(fontSize: 32)),
                              SizedBox(height: 6),
                              Text(
                                'Set Budget',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF403633),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Plan your spending wisely ✨',
                                style: TextStyle(
                                  color: Color(0xFF958580),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F4643),
                          ),
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          isExpanded: true,
                          decoration: _inputDecoration(),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.title,
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: category.color.withValues(
                                        alpha: 0.20,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      category.emoji,
                                      style: const TextStyle(fontSize: 19),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Text(
                                    category.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            final category = _categories.firstWhere(
                              (item) => item.title == value,
                            );

                            setModalState(() {
                              selectedCategory = value;

                              budgetController.text = category.limit
                                  .toStringAsFixed(0);
                            });
                          },
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Budget Limit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F4643),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: budgetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _inputDecoration().copyWith(
                            prefixText: 'RM ',
                            prefixStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF277765),
                            ),
                            hintText: '0.00',
                          ),
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              final amount = double.tryParse(
                                budgetController.text.trim(),
                              );

                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid budget amount.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              final category = _categories.firstWhere(
                                (item) => item.title == selectedCategory,
                              );

                              await AppDatabase.instance.setBudgetLimit(
                                category.title,
                                amount,
                              );

                              if (!mounted) {
                                return;
                              }

                              setState(() {
                                category.limit = amount;
                              });

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    '$selectedCategory budget updated 💖',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF277765),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Save Budget ✨',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF8B7C77)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      budgetController.dispose();
    });
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF1E6E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF277765), width: 1.4),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 25),

              _buildMonthSelector(),

              const SizedBox(height: 18),

              _buildMonthlyCard(),

              const SizedBox(height: 14),

              _buildSetBudgetButton(),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Text(
                    'Budget by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF403633),
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Text('🌷', style: TextStyle(fontSize: 18)),

                  const Spacer(),

                  IconButton(
                    onPressed: _showAddCategorySheet,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF277765),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'Tap a category to view its transactions ✨',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF9B8E89)),
              ),

              const SizedBox(height: 14),

              ..._sortedCategories.map(
                (category) => _buildCategoryRow(category),
              ),
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
          onPressed: _handleReload,
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF277765)),
        ),

        const Text('💰', style: TextStyle(fontSize: 25)),
      ],
    );
  }

  // =========================================================
  // MONTH SELECTOR
  // =========================================================

  Widget _buildMonthSelector() {
    final monthText =
        '${_monthName(_displayMonth.month)} '
        '${_displayMonth.year}';

    return Row(
      children: [
        _cuteIconButton(icon: Icons.chevron_left_rounded, onTap: _prevMonth),

        const SizedBox(width: 8),

        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF0DFDC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🗓️', style: TextStyle(fontSize: 18)),

                const SizedBox(width: 8),

                Text(
                  monthText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF544B48),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        _cuteIconButton(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
      ],
    );
  }

  Widget _cuteIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E8),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF8D5D5)),
        ),
        child: Icon(icon, color: const Color(0xFFB56C6C)),
      ),
    );
  }

  // =========================================================
  // MONTHLY BUDGET CARD
  // =========================================================

  Widget _buildMonthlyCard() {
    final rawPercent = _totalLimit == 0 ? 0.0 : _totalSpent / _totalLimit;

    final progressPercent = rawPercent.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDFB), Color(0xFFFFF2EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF2E3DF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9B4AF).withValues(alpha: 0.18),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF403633),
                ),
              ),

              SizedBox(width: 6),

              Text('💰', style: TextStyle(fontSize: 18)),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8ED),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF3A7B5).withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💰', style: TextStyle(fontSize: 46)),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Color(0xFF403633)),
                        children: [
                          TextSpan(
                            text: 'RM ${_totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          TextSpan(
                            text: ' / RM ${_totalLimit.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9A8D88),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFF0E7E4),
                        valueColor: AlwaysStoppedAnimation(
                          _getProgressColor(rawPercent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${(rawPercent * 100).toStringAsFixed(0)}% used',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getProgressColor(rawPercent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  _budgetEmoji(rawPercent),
                  style: const TextStyle(fontSize: 21),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _budgetMessage(rawPercent),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D6260),
                      fontWeight: FontWeight.w500,
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
  // SET BUDGET BUTTON
  // =========================================================

  Widget _buildSetBudgetButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _showSetBudgetSheet,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEEEE),
          foregroundColor: const Color(0xFF8C5757),
          side: const BorderSide(color: Color(0xFFF2D3D3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌸', style: TextStyle(fontSize: 19)),

            SizedBox(width: 9),

            Text(
              'Set Budget',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CATEGORY ACCORDION
  // =========================================================

  Widget _buildCategoryRow(BudgetCategory category) {
    final spent = _getCategorySpent(category.title);

    final rawPercent = category.limit == 0 ? 0.0 : spent / category.limit;

    final progressPercent = rawPercent.clamp(0.0, 1.0);

    final isExpanded = _expandedCategory == category.title;

    final transactions = _getCategoryTransactions(category.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E6E3)),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategory = null;
                } else {
                  _expandedCategory = category.title;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Center(
                      child: Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4F4643),
                                ),
                              ),
                            ),

                            Text(
                              'RM ${spent.toStringAsFixed(0)} '
                              '/ RM ${category.limit.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF9B8E89),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 9,
                            backgroundColor: const Color(0xFFF1ECEA),
                            valueColor: AlwaysStoppedAnimation(
                              _getCategoryProgressColor(category, rawPercent),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Row(
                          children: [
                            Text(
                              '${(rawPercent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getCategoryProgressColor(
                                  category,
                                  rawPercent,
                                ),
                              ),
                            ),

                            const Spacer(),

                            Text(
                              _categoryStatus(rawPercent),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryProgressColor(
                                  category,
                                  rawPercent,
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Color(0xFF9B8E89),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildCategoryTransactionList(category, transactions),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRANSACTIONS INSIDE CATEGORY
  // =========================================================

  Widget _buildCategoryTransactionList(
    BudgetCategory category,
    List<TransactionItem> transactions,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFF1E6E3)),

          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 7),
            child: Row(
              children: [
                Text(
                  '${category.emoji} ${category.title} transactions',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF625653),
                  ),
                ),

                const Spacer(),

                Text(
                  '${transactions.length} '
                  '${transactions.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9B8E89),
                  ),
                ),
              ],
            ),
          ),

          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text('🌱', style: TextStyle(fontSize: 25)),
                    SizedBox(height: 5),
                    Text(
                      'No spending here yet',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E817D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions.map(
              (transaction) => _buildMiniTransaction(transaction, category),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // =========================================================
  // MINI TRANSACTION
  // =========================================================

  Widget _buildMiniTransaction(
    TransactionItem transaction,
    BudgetCategory category,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(category.emoji, style: const TextStyle(fontSize: 19)),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F4643),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatTransactionDate(transaction.date),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9B8E89),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              '- RM ${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFA75A5A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // COLORS / STATUS
  // =========================================================

  Color _getProgressColor(double percent) {
    if (percent >= 1) {
      return const Color(0xFFE36C6C);
    }

    if (percent >= 0.8) {
      return const Color(0xFFE5AD54);
    }

    return const Color(0xFF74B9A8);
  }

  Color _getCategoryProgressColor(BudgetCategory category, double percent) {
    if (percent >= 1) {
      return const Color(0xFFE36C6C);
    }

    if (percent >= 0.8) {
      return const Color(0xFFE5AD54);
    }

    return category.color;
  }

  String _categoryStatus(double percent) {
    if (percent >= 1) {
      return 'Budget reached! 😭';
    }

    if (percent >= 0.8) {
      return 'Almost full 🥺';
    }

    if (percent >= 0.5) {
      return 'Halfway 🌼';
    }

    return 'Looking good ✨';
  }

  String _budgetEmoji(double percent) {
    if (percent >= 1) {
      return '😭';
    }

    if (percent >= 0.8) {
      return '🥺';
    }

    if (percent >= 0.5) {
      return '🌼';
    }

    return '✨';
  }

  String _budgetMessage(double percent) {
    if (percent >= 1) {
      return 'Oops! Your monthly budget has been reached.';
    }

    if (percent >= 0.8) {
      return 'Careful~ you have used more than 80% of your budget.';
    }

    if (percent >= 0.5) {
      return 'Halfway there. Keep watching your spending!';
    }

    return "You're doing great! Keep it up!";
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  String _formatTransactionDate(DateTime date) {
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

    return '${date.day} '
        '${months[date.month - 1]}';
  }

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

// =========================================================
// BUDGET CATEGORY
// =========================================================

class BudgetCategory {
  final String title;
  final String emoji;

  double limit;

  final Color color;

  BudgetCategory({
    required this.title,
    required this.emoji,
    required this.limit,
    required this.color,
  });
}
