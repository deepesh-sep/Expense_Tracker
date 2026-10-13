import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/sample_data.dart';
import '../models/transaction.dart';
import '../utils/expense_totals.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/category_spending_chart.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = SampleData.transactions();
  }

  Future<void> _openAddExpenseDialog() async {
    final created = await showAddExpenseDialog(context);
    if (created == null || !mounted) {
      return;
    }

    setState(() {
      _transactions = [created, ..._transactions];
    });
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings will be added in a later version.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);
    final todayTotal = ExpenseTotals.today(_transactions, now: now);
    final weekTotal = ExpenseTotals.thisWeek(_transactions, now: now);
    final monthTotal = ExpenseTotals.thisMonth(_transactions, now: now);
    final remaining = ExpenseTotals.remainingBudget(
      _transactions,
      budget: SampleData.monthlyBudget,
      now: now,
    );
    final categoryTotals = ExpenseTotals.byCategory(_transactions, now: now);
    final recent = ExpenseTotals.recent(_transactions);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Expense Tracker'),
            Text(
              monthLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(
              left: SummaryCard(
                title: "Today's expenses",
                amount: todayTotal,
                icon: Icons.today_rounded,
                accentColor: const Color(0xFF0D9488),
              ),
              right: SummaryCard(
                title: "This week's expenses",
                amount: weekTotal,
                icon: Icons.date_range_rounded,
                accentColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              left: SummaryCard(
                title: "This month's expenses",
                amount: monthTotal,
                icon: Icons.calendar_month_rounded,
                accentColor: const Color(0xFF8B5CF6),
              ),
              right: SummaryCard(
                title: 'Budget remaining',
                amount: remaining < 0 ? 0 : remaining,
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFFE07A3D),
              ),
            ),
            const SizedBox(height: 12),
            BudgetProgressCard(
              spent: monthTotal,
              budget: SampleData.monthlyBudget,
            ),
            const SizedBox(height: 12),
            CategorySpendingChart(totals: categoryTotals),
            const SizedBox(height: 12),
            RecentTransactions(transactions: recent),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }
}
