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

  Transaction copyWith({ExpenseCategory? category}) => Transaction(
    id: id,
    description: description,
    amount: amount,
    date: date,
    category: category ?? this.category,
    type: type,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.toJson(),
    'type': type.name,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    category: ExpenseCategory.fromJson(
      json['category'] as Map<String, dynamic>,
    ),
    type: TransactionType.values.byName(json['type'] as String),
  );
}
