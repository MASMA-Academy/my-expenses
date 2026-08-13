import 'package:flutter/material.dart';

import '../models/transaction_item.dart';

class BudgetScreen extends StatefulWidget {
	final List<TransactionItem> transactions;
	final VoidCallback onAddTransaction;

	const BudgetScreen({Key? key, required this.transactions, required this.onAddTransaction}) : super(key: key);

	@override
	State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
	late DateTime _displayMonth;

	final List<BudgetCategory> _categories = [
		BudgetCategory(
			title: 'Food',
			icon: Icons.fastfood,
			spent: 450,
			limit: 700,
			color: const Color(0xFF7BD389),
		),
		BudgetCategory(
			title: 'Transport',
			icon: Icons.directions_car,
			spent: 300,
			limit: 500,
			color: const Color(0xFF7BD3D3),
		),
		BudgetCategory(
			title: 'Shopping',
			icon: Icons.shopping_bag,
			spent: 600,
			limit: 800,
			color: const Color(0xFFFFC7C7),
		),
		BudgetCategory(
			title: 'Bills',
			icon: Icons.receipt_long,
			spent: 400,
			limit: 600,
			color: const Color(0xFFFFD27A),
		),
		BudgetCategory(
			title: 'Others',
			icon: Icons.more_horiz,
			spent: 0,
			limit: 400,
			color: const Color(0xFFD6C6FF),
		),
	];

	double get _totalSpent => _categories.fold(0, (p, c) => p + c.spent);

	double get _totalLimit => _categories.fold(0, (p, c) => p + c.limit);

	@override
	Widget build(BuildContext context) {
		final media = MediaQuery.of(context).size;

		return Scaffold(
			appBar: AppBar(
				title: const Text('Budget'),
				centerTitle: true,
				elevation: 0,
				backgroundColor: Colors.transparent,
				foregroundColor: Colors.black,
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							_buildMonthSelector(),
							const SizedBox(height: 12),
							_buildMonthlyCard(media),
							const SizedBox(height: 18),
							const Text(
								'Budget by Category',
								style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
							),
							const SizedBox(height: 12),
							..._categories.map((c) => _buildCategoryRow(c)).toList(),
						],
					),
				),
			),
		);
	}

	@override
	void initState() {
		super.initState();
		_displayMonth = DateTime.now();
	}

	Widget _buildMonthSelector() {
		final monthText = '${_monthName(_displayMonth.month)} ${_displayMonth.year}';
		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				IconButton(
					onPressed: _prevMonth,
					icon: const Icon(Icons.chevron_left),
				),
				Container(
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
					decoration: BoxDecoration(
						color: Colors.grey.shade100,
						borderRadius: BorderRadius.circular(24),
					),
					child: Row(
						children: [
							Text(monthText, style: const TextStyle(fontWeight: FontWeight.w600)),
							const SizedBox(width: 8),
							const Icon(Icons.calendar_today_outlined, size: 16),
						],
					),
				),
				IconButton(
					onPressed: _nextMonth,
					icon: const Icon(Icons.chevron_right),
				),
			],
		);
	}

	void _prevMonth() {
		setState(() {
			_displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
		});
	}

	void _nextMonth() {
		setState(() {
			_displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
		});
	}

	Widget _buildMonthlyCard(Size media) {
		final percent = (_totalLimit == 0) ? 0.0 : (_totalSpent / _totalLimit).clamp(0.0, 1.0);

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				boxShadow: [
					BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, spreadRadius: 3),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.w600)),
					const SizedBox(height: 8),
					Row(
						children: [
							// Piggy placeholder
							Container(
								width: 80,
								height: 80,
								decoration: BoxDecoration(
									color: Colors.pink.shade50,
									borderRadius: BorderRadius.circular(12),
								),
								child: const Center(child: Text('🐷', style: TextStyle(fontSize: 36))),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text('RM ${_totalSpent.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
										const SizedBox(height: 4),
										Text(' / RM ${_totalLimit.toInt()}', style: TextStyle(color: Colors.grey.shade600)),
										const SizedBox(height: 12),
										ClipRRect(
											borderRadius: BorderRadius.circular(12),
											child: LinearProgressIndicator(
												value: percent,
												minHeight: 12,
												backgroundColor: Colors.grey.shade200,
												valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
											),
										),
										const SizedBox(height: 8),
										Row(
											children: [
												Text('${(percent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
												const SizedBox(width: 8),
												const Text("You're doing great! Keep it up! "),
												const Icon(Icons.favorite, color: Colors.green, size: 16),
											],
										),
									],
								),
							),
						],
					),
				],
			),
		);
	}

	Widget _buildCategoryRow(BudgetCategory c) {
		final percent = (c.limit == 0) ? 0.0 : (c.spent / c.limit).clamp(0.0, 1.0);

		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 10),
			child: Row(
				children: [
					Container(
						width: 44,
						height: 44,
						decoration: BoxDecoration(
							color: c.color.withOpacity(0.2),
							borderRadius: BorderRadius.circular(12),
						),
						child: Icon(c.icon, color: c.color, size: 22),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
										Text('RM ${c.spent.toInt()} / RM ${c.limit.toInt()}', style: TextStyle(color: Colors.grey.shade600)),
									],
								),
								const SizedBox(height: 8),
								ClipRRect(
									borderRadius: BorderRadius.circular(10),
									child: LinearProgressIndicator(
										minHeight: 10,
										value: percent,
										backgroundColor: Colors.grey.shade200,
										valueColor: AlwaysStoppedAnimation(c.color),
									),
								),
							],
						),
					),
				],
			),
		);
	}

	String _monthName(int m) {
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
			'December'
		];
		return names[m - 1];
	}
}

class BudgetCategory {
	final String title;
	final IconData icon;
	final double spent;
	final double limit;
	final Color color;

	BudgetCategory({required this.title, required this.icon, required this.spent, required this.limit, required this.color});
}

