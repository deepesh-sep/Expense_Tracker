import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_category.dart';
import '../models/transaction.dart';
import '../utils/money.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(transaction.date);
    final isExpense = transaction.isExpense;
    final amountColor = isExpense
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF15803D);
    final amountPrefix = isExpense ? '-' : '+';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: transaction.category.color.withValues(alpha: 0.12),
        foregroundColor: transaction.category.color,
        child: Icon(
          isExpense ? transaction.category.icon : Icons.south_west_rounded,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${transaction.category.label} · $dateLabel'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$amountPrefix${formatInr(transaction.amount)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          Text(
            isExpense ? 'Expense' : 'Income',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
