import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_settings.dart';
import '../models/expense_category.dart';
import '../models/transaction.dart';
import '../utils/expense_totals.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/category_spending_chart.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.settings,
    required this.transactions,
    required this.onSettingsChanged,
    required this.onTransactionsChanged,
    this.profileImage,
  });

  final AppSettings settings;
  final List<Transaction> transactions;
  final Future<void> Function(AppSettings) onSettingsChanged;
  final Future<void> Function(List<Transaction>) onTransactionsChanged;
  final ImageProvider<Object>? profileImage;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _openAddExpenseDialog() async {
    final created = await showAddExpenseDialog(
      context,
      categories: widget.settings.categories,
    );
    if (created == null || !mounted) {
      return;
    }

    await widget.onTransactionsChanged([created, ...widget.transactions]);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settings: widget.settings,
          transactions: widget.transactions,
          onSettingsChanged: widget.onSettingsChanged,
          onClearTransactions: () => widget.onTransactionsChanged([]),
        ),
      ),
    );
  }

  Future<void> _openCategoryTransactions(
    BuildContext context,
    ExpenseCategory category,
  ) async {
    final now = DateTime.now();
    final transactions = ExpenseTotals.transactionsForCategoryThisMonth(
      widget.transactions,
      category: category,
      now: now,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.label} transactions',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM yyyy').format(now),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text('No transactions in this category yet.'),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) =>
                              TransactionTile(transaction: transactions[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPeriodTransactions(
    BuildContext context, {
    required String title,
    required List<Transaction> transactions,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text('No transactions for this period.'),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) =>
                              TransactionTile(transaction: transactions[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final profileDateLabel = DateFormat('EEEE, d MMMM').format(now);
    final weekOfMonth =
        (now.day + DateTime(now.year, now.month, 1).weekday - 2) ~/ 7 + 1;
    final todayTotal = ExpenseTotals.today(widget.transactions, now: now);
    final weekTotal = ExpenseTotals.thisWeek(widget.transactions, now: now);
    final monthTotal = ExpenseTotals.thisMonth(widget.transactions, now: now);
    final remaining = ExpenseTotals.remainingBudget(
      widget.transactions,
      budget: widget.settings.monthlyBudget,
      now: now,
    );
    final categoryTotals = ExpenseTotals.byCategory(
      widget.transactions,
      now: now,
      categories: widget.settings.categories,
    );
    final recent = ExpenseTotals.recent(widget.transactions);

    return Scaffold(
      appBar: AppBar(
        title: _ProfileHeader(
          name: widget.settings.profileName,
          dateLabel: profileDateLabel,
          image: widget.profileImage,
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
                periodLabel: DateFormat('EEEE, d MMMM').format(now),
                onTap: () => _openPeriodTransactions(
                  context,
                  title: "Today's transactions",
                  transactions: ExpenseTotals.todayTransactions(
                    widget.transactions,
                    now: now,
                  ),
                ),
              ),
              right: SummaryCard(
                title: "This week's expenses",
                amount: weekTotal,
                icon: Icons.date_range_rounded,
                accentColor: const Color(0xFF3B82F6),
                periodLabel:
                    '${DateFormat('MMMM').format(now)} · Week $weekOfMonth',
                onTap: () => _openPeriodTransactions(
                  context,
                  title: "This week's transactions",
                  transactions: ExpenseTotals.thisWeekTransactions(
                    widget.transactions,
                    now: now,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              left: SummaryCard(
                title: "This month's expenses",
                amount: monthTotal,
                icon: Icons.calendar_month_rounded,
                accentColor: const Color(0xFF8B5CF6),
                periodLabel: DateFormat('MMMM yyyy').format(now),
                onTap: () => _openPeriodTransactions(
                  context,
                  title: "This month's transactions",
                  transactions: ExpenseTotals.thisMonthTransactions(
                    widget.transactions,
                    now: now,
                  ),
                ),
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
              budget: widget.settings.monthlyBudget,
            ),
            const SizedBox(height: 12),
            CategorySpendingChart(
              totals: categoryTotals,
              categories: widget.settings.categories,
              onCategoryTap: (category) =>
                  _openCategoryTransactions(context, category),
            ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.dateLabel,
    this.image,
  });

  final String name;
  final String dateLabel;
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          backgroundImage: image,
          child: image == null
              ? Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
