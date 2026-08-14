import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/transaction_item.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionItem? existing;
  final List<String> extraCategories;

  const AddTransactionScreen({
    super.key,
    this.existing,
    this.extraCategories = const [],
  });

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
  Uint8List? receiptBytes;

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
    if (isIncome) return incomeCategories;

    return [...expenseCategories, ...widget.extraCategories];
  }

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      titleController.text = existing.title;
      amountController.text = existing.amount.toStringAsFixed(2);
      isIncome = existing.income;
      selectedCategory = existing.category;
      selectedDate = existing.date;
      receiptBytes = existing.receipt;
      selectedPaymentMethod = existing.paymentMethod;
      selectedWallet = existing.wallet;
      noteController.text = existing.note;
    }
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

  Future<void> pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      receiptBytes = bytes;
    });
  }

  void removeReceipt() {
    setState(() {
      receiptBytes = null;
    });
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
      id: widget.existing?.id,
      title: title,
      category: selectedCategory,
      amount: amount,
      income: isIncome,
      date: selectedDate,
      receipt: receiptBytes,
      paymentMethod: selectedPaymentMethod,
      wallet: selectedWallet,
      note: noteController.text.trim(),
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
        title: Text(
          widget.existing != null ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(
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

              const SizedBox(height: 22),

              label('Receipt (optional)'),

              if (receiptBytes == null)
                InkWell(
                  onTap: pickReceipt,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE1D8D5),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF277765),
                        ),
                        SizedBox(height: 8),
                        Text('Add Receipt Photo'),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        receiptBytes!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: removeReceipt,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  child: Text(
                    widget.existing != null
                        ? 'Update Transaction'
                        : 'Save Transaction',
                    style: const TextStyle(
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