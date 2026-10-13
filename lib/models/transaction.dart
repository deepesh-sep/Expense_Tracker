import 'expense_category.dart';

enum TransactionType { expense, income }

class Transaction {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final TransactionType type;

  bool get isExpense => type == TransactionType.expense;
}
