import '../models/expense_category.dart';
import '../models/transaction.dart';

class ExpenseTotals {
  const ExpenseTotals._();

  static Iterable<Transaction> expensesOnly(List<Transaction> items) {
    return items.where((item) => item.isExpense);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static double today(List<Transaction> items, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return expensesOnly(items)
        .where((item) => _isSameDay(item.date, today))
        .fold(0, (sum, item) => sum + item.amount);
  }

  static double thisWeek(List<Transaction> items, {DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return expensesOnly(items)
        .where(
          (item) =>
              !item.date.isBefore(weekStart) && item.date.isBefore(weekEnd),
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  static double thisMonth(List<Transaction> items, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return expensesOnly(items)
        .where((item) => _isSameMonth(item.date, today))
        .fold(0, (sum, item) => sum + item.amount);
  }

  static List<Transaction> todayTransactions(
    List<Transaction> items, {
    DateTime? now,
  }) {
    final today = _startOfDay(now ?? DateTime.now());
    return _transactionsInRange(
      items,
      today,
      today.add(const Duration(days: 1)),
    );
  }

  static List<Transaction> thisWeekTransactions(
    List<Transaction> items, {
    DateTime? now,
  }) {
    final today = _startOfDay(now ?? DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return _transactionsInRange(
      items,
      weekStart,
      weekStart.add(const Duration(days: 7)),
    );
  }

  static List<Transaction> thisMonthTransactions(
    List<Transaction> items, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    return _transactionsInRange(
      items,
      DateTime(today.year, today.month),
      DateTime(today.year, today.month + 1),
    );
  }

  static List<Transaction> _transactionsInRange(
    List<Transaction> items,
    DateTime start,
    DateTime end,
  ) {
    final filtered =
        items
            .where(
              (item) => !item.date.isBefore(start) && item.date.isBefore(end),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  static List<Transaction> transactionsForCategoryThisMonth(
    List<Transaction> items, {
    required ExpenseCategory category,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final monthStart = DateTime(today.year, today.month);
    final nextMonthStart = DateTime(today.year, today.month + 1);
    return expensesOnly(items)
        .where(
          (item) =>
              item.category == category &&
              !item.date.isBefore(monthStart) &&
              item.date.isBefore(nextMonthStart),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static double remainingBudget(
    List<Transaction> items, {
    required double budget,
    DateTime? now,
  }) {
    return budget - thisMonth(items, now: now);
  }

  static Map<ExpenseCategory, double> byCategory(
    List<Transaction> items, {
    DateTime? now,
    List<ExpenseCategory> categories = ExpenseCategory.values,
  }) {
    final today = now ?? DateTime.now();
    final totals = {for (final category in categories) category: 0.0};

    for (final item in expensesOnly(items)) {
      if (!_isSameMonth(item.date, today)) {
        continue;
      }
      if (totals.containsKey(item.category)) {
        totals[item.category] = totals[item.category]! + item.amount;
      }
    }

    return totals;
  }

  static List<Transaction> recent(List<Transaction> items, {int limit = 8}) {
    final sorted = [...items]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
}
