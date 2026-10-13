import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../utils/money.dart';

class CategorySpendingChart extends StatelessWidget {
  const CategorySpendingChart({super.key, required this.totals});

  final Map<ExpenseCategory, double> totals;

  @override
  Widget build(BuildContext context) {
    final entries = ExpenseCategory.values
        .map((category) => MapEntry(category, totals[category] ?? 0))
        .toList();
    final maxAmount = entries.fold<double>(
      0,
      (current, entry) => entry.value > current ? entry.value : current,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final fraction = maxAmount == 0 ? 0.0 : entry.value / maxAmount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CategoryBar(
                  category: entry.key,
                  amount: entry.value,
                  fraction: fraction,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.fraction,
  });

  final ExpenseCategory category;
  final double amount;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(category.icon, size: 18, color: category.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              formatInr(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            color: category.color,
            backgroundColor: category.color.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}
