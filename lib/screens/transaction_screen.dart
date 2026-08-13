import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final amountController = TextEditingController();
  final titleController = TextEditingController();

  bool isIncome = false;
  String selectedCategory = 'Food';

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
  ];

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    super.dispose();
  }

  void saveTransaction() {
    final title = titleController.text.trim();

    final amount = double.tryParse(
      amountController.text.trim(),
    );

    if (title.isEmpty) {
      showMessage('Please enter transaction title.');
      return;
    }

    if (amount == null || amount <= 0) {
      showMessage('Please enter a valid amount.');
      return;
    }

    final transaction = TransactionItem(
      title: title,
      category: isIncome ? 'Income' : selectedCategory,
      amount: amount,
      income: isIncome,
      date: DateTime.now(),
    );

    Navigator.pop(
      context,
      transaction,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF8F6),
        title: const Text(
          'Add Transaction',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          22,
          20,
          22,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 30),

             Center(
                child: Image.asset(
                  'assets/images/logoexpenses.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),


            _buildTransactionType(),
            

            const SizedBox(height: 50),

            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'RM ',
                prefixStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF277765),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: isIncome
                    ? 'Example: Salary'
                    : 'Example: Lunch',

                prefixIcon: const Icon(
                  Icons.edit_outlined,
                ),

                filled: true,
                fillColor: Colors.white,

                contentPadding: const EdgeInsets.all(18),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (!isIncome) ...[
              const SizedBox(height: 22),

              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedCategory,

                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),

                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      '${categoryEmoji(category)}  $category',
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
            ],

            const SizedBox(height: 22),

            const Text(
              'Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: Color(0xFF74B9A8),
                  ),

                  SizedBox(width: 12),

                  Text(
                    'Today',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveTransaction,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF277765),
                  foregroundColor: Colors.white,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                child: const Text(
                  'Save Transaction',
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
    );
  }

  Widget _buildTransactionType() {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: const Color(0xFFECE2E0),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        children: [
          _typeButton(
            title: 'Expense',
            income: false,
          ),

          _typeButton(
            title: 'Income',
            income: true,
          ),
        ],
      ),
    );
  }

  Widget _typeButton({
    required String title,
    required bool income,
  }) {
    final selected = isIncome == income;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isIncome = income;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ),

          padding: const EdgeInsets.symmetric(
            vertical: 12,
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

  String categoryEmoji(String category) {
    switch (category) {
      case 'Food':
        return '🍔';

      case 'Transport':
        return '🚗';

      case 'Shopping':
        return '🛍️';

      case 'Bills':
        return '💡';

      default:
        return '💸';
    }
  }
}