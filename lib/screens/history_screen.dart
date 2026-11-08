import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final completedTransactions =
        transactions.where((item) => item.date.isBefore(currentMonth)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final months = <DateTime, List<Transaction>>{};

    for (final transaction in completedTransactions) {
      final month = DateTime(transaction.date.year, transaction.date.month);
      months.putIfAbsent(month, () => []).add(transaction);
    }

    final monthEntries = months.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: monthEntries.isEmpty
          ? const Center(child: Text('No completed month history yet.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final entry in monthEntries)
                  _MonthHistory(month: entry.key, transactions: entry.value),
              ],
            ),
    );
  }
}

class _MonthHistory extends StatelessWidget {
  const _MonthHistory({required this.month, required this.transactions});

  final DateTime month;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final weeks = <int, Map<DateTime, List<Transaction>>>{};
    for (final transaction in transactions) {
      final weekNumber = _weekOfMonth(transaction.date);
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      weeks
          .putIfAbsent(weekNumber, () => {})
          .putIfAbsent(day, () => [])
          .add(transaction);
    }

    final weekNumbers = weeks.keys.toList()..sort((a, b) => b.compareTo(a));

    return Card(
      child: ExpansionTile(
        key: PageStorageKey('history-${month.year}-${month.month}'),
        title: Text(
          DateFormat('MMMM yyyy').format(month),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${transactions.length} transaction${transactions.length == 1 ? '' : 's'}',
        ),
        children: [
          for (final weekNumber in weekNumbers)
            _WeekHistory(weekNumber: weekNumber, days: weeks[weekNumber]!),
        ],
      ),
    );
  }
}

class _WeekHistory extends StatelessWidget {
  const _WeekHistory({required this.weekNumber, required this.days});

  final int weekNumber;
  final Map<DateTime, List<Transaction>> days;

  @override
  Widget build(BuildContext context) {
    final dayEntries = days.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ExpansionTile(
      key: PageStorageKey('history-week-$weekNumber-${dayEntries.first.key}'),
      tilePadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text('Week $weekNumber'),
      children: [
        for (final entry in dayEntries)
          _DayHistory(day: entry.key, transactions: entry.value),
      ],
    );
  }
}

class _DayHistory extends StatelessWidget {
  const _DayHistory({required this.day, required this.transactions});

  final DateTime day;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey('history-day-${day.year}-${day.month}-${day.day}'),
      tilePadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(DateFormat('EEEE, d MMMM').format(day)),
      children: [
        for (final transaction in transactions)
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: TransactionTile(transaction: transaction),
          ),
      ],
    );
  }
}

int _weekOfMonth(DateTime date) {
  final firstWeekday = DateTime(date.year, date.month, 1).weekday;
  return (date.day + firstWeekday - 2) ~/ 7 + 1;
}
