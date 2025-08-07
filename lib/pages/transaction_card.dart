import 'package:flutter/material.dart';

class RecentTransactionModern extends StatelessWidget {
  final bool isIncome;
  final String description;
  final String amount;
  final String date;
  final String category;
  final VoidCallback onEditCategory;
  final Future<void> Function(BuildContext context, double amount, String description) onSplit;
  final Color primary;
  final Color onBackground;
  final Color secondary;
  final Color onSecondary;
  final bool isChild;

  const RecentTransactionModern({
    super.key,
    required this.isIncome,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'Uncategorized',
    required this.onEditCategory,
    required this.onSplit, 
    required this.primary,
    required this.onBackground,
    required this.secondary,
    required this.onSecondary,
     required this.isChild,
  });

  Future<void> _showSplitDialog(BuildContext context) async {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Split Transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Split Amount',
              hintText: 'Enter amount to split',
            ),
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Split Description',
              hintText: 'Description for this split part',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final amountText = _amountController.text.trim();
            final descText = _descController.text.trim();
            if (amountText.isEmpty || descText.isEmpty) return;
            final parsedAmount = double.tryParse(amountText);
            if (parsedAmount == null) return;
            await onSplit(ctx, parsedAmount, descText);

            Navigator.pop(ctx); 
          },
          child: const Text('Split'),
        ),
      ],
    ),
  );
}


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
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        color: Colors.black45,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isChild)
                    TextButton(
                      onPressed: () => _showSplitDialog(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Split',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
