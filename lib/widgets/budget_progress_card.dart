import 'package:flutter/material.dart';

import '../utils/money.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.spent,
    required this.budget,
  });

  final double spent;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final remaining = budget - spent;
    final progress = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final overBudget = remaining < 0;
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = overBudget ? colorScheme.error : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly budget',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              overBudget
                  ? '${formatInr(-remaining)} over the ${formatInr(budget)} budget'
                  : '${formatInr(remaining)} remaining of ${formatInr(budget)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: overBudget
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: barColor,
                backgroundColor: barColor.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spent ${formatInr(spent)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remaining ${formatInr(remaining < 0 ? 0 : remaining)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
