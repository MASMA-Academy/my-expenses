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
  final noteController = TextEditingController();

  bool isIncome = false;

  String selectedCategory = 'Food';
  String selectedPaymentMethod = 'Cash';
  String selectedWallet = 'Cash';

  DateTime selectedDate = DateTime.now();

  final List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Family',
    'Health',
    'Others',
  ];

  final List<String> incomeCategories = [
    'Salary',
    'Allowance',
    'Freelance',
    'Bonus',
    'Others',
  ];

  final List<String> paymentMethods = [
    'Cash',
    'Card',
    'E-wallet',
  ];

  final List<String> wallets = [
    'Cash',
    'Maybank',
    'TnG E-Wallet',
    'ShopeePay',
  ];

  List<String> get currentCategories {
    return isIncome ? incomeCategories : expenseCategories;
  }

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void changeType(bool income) {
    setState(() {
      isIncome = income;

      if (isIncome) {
        selectedCategory = incomeCategories.first;
      } else {
        selectedCategory = expenseCategories.first;
      }
    });
  }

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
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
      category: selectedCategory,
      amount: amount,
      income: isIncome,
      date: selectedDate,

      // Kalau model TransactionItem kau belum ada field ni,
      // jangan masukkan dulu.
      //
      // paymentMethod: selectedPaymentMethod,
      // wallet: selectedWallet,
      // note: noteController.text.trim(),
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

  InputDecoration inputDecoration({
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE1D8D5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE1D8D5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF277765),
          width: 1.5,
        ),
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget transactionTypeButton({
    required String title,
    required bool income,
  }) {
    final selected = isIncome == income;

    return Expanded(
      child: GestureDetector(
        onTap: () => changeType(income),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF8CCCC)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? const Color(0xFF7B3636)
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F7),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F7),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          'Add Transaction',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E7),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFFF2B6B6).withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // decorative sparkle kiri
                      Positioned(
                        left: 22,
                        top: 25,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: const Color(0xFFFFC95A)
                              .withOpacity(0.8),
                        ),
                      ),

                      // decorative sparkle kanan
                      Positioned(
                        right: 25,
                        top: 35,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: const Color(0xFFF4A6B5)
                              .withOpacity(0.8),
                        ),
                      ),

                      // small decorative circle
                      Positioned(
                        left: 35,
                        bottom: 30,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF9EDBCB),
                          ),
                        ),
                      ),

                      // main image
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: Image.asset(
                          'assets/images/transaction.png',
                          width: 250,
                          height: 165,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE5E3),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Row(
                  children: [
                    transactionTypeButton(
                      title: 'Expense',
                      income: false,
                    ),
                    transactionTypeButton(
                      title: 'Income',
                      income: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              label('Amount (RM)'),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inputDecoration(
                  hint: '0.00',
                ),
              ),

              const SizedBox(height: 22),

              label('Title'),

              TextField(
                controller: titleController,
                decoration: inputDecoration(
                  hint: isIncome
                      ? 'e.g. Salary'
                      : 'e.g. Lunch, Petrol',
                ),
              ),

              const SizedBox(height: 22),

              label('Category'),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: inputDecoration(
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                  ),
                ),
                items: currentCategories.map(
                  (category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        '${categoryEmoji(category)}  $category',
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 22),

              label('Date'),

              InkWell(
                onTap: selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE1D8D5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF277765),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}/'
                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                        '${selectedDate.year}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              label('Payment Method'),

              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                decoration: inputDecoration(
                  prefixIcon: const Icon(
                    Icons.payment_outlined,
                  ),
                ),
                items: paymentMethods.map(
                  (method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPaymentMethod = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 22),

              label('Wallet'),

              DropdownButtonFormField<String>(
                value: selectedWallet,
                decoration: inputDecoration(
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
                items: wallets.map(
                  (wallet) {
                    return DropdownMenuItem(
                      value: wallet,
                      child: Text(wallet),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedWallet = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 22),

              label('Note (optional)'),

              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: inputDecoration(
                  hint: 'Add a note...',
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF277765),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Save Transaction',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
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

      case 'Family':
        return '👨‍👩‍👧';

      case 'Health':
        return '❤️';

      case 'Salary':
        return '💰';

      case 'Allowance':
        return '💵';

      case 'Freelance':
        return '💻';

      case 'Bonus':
        return '🎁';

      default:
        return '💸';
    }
  }
}