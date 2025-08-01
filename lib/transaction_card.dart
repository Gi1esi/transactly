import 'package:flutter/material.dart';

class RecentTransactionModern extends StatelessWidget {
  final bool isIncome;
  final String description;
  final String amount;
  final String date;
  final String category;
  final VoidCallback onEditCategory;
  final Color primary;
  final Color onBackground;
  final Color secondary;
  final Color onSecondary;


  const RecentTransactionModern({
    super.key,
    required this.isIncome,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'Uncategorized',
    required this.onEditCategory,
    required this.primary,
    required this.onBackground,
    required this.secondary,
    required this.onSecondary,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incomeColor = theme.colorScheme.primary;
    final expenseColor = theme.colorScheme.secondary;
    final iconColor = isIncome ? incomeColor : expenseColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  color: iconColor,
                ),
              ),
              TextButton(
                onPressed: onEditCategory,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )

        ],
      ),
    );
  }
}
