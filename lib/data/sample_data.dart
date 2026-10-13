import '../models/expense_category.dart';
import '../models/transaction.dart';

class SampleData {
  const SampleData._();

  static const double monthlyBudget = 20000;

  static List<Transaction> transactions({DateTime? now}) {
    final today = now ?? DateTime.now();
    DateTime daysAgo(int days, {int hour = 12, int minute = 0}) {
      return DateTime(
        today.year,
        today.month,
        today.day,
        hour,
        minute,
      ).subtract(Duration(days: days));
    }

    return [
      Transaction(
        id: '1',
        description: 'Breakfast at cafe',
        amount: 220,
        date: daysAgo(0, hour: 9, minute: 10),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '2',
        description: 'Metro to office',
        amount: 60,
        date: daysAgo(0, hour: 8, minute: 35),
        category: ExpenseCategory.travel,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '3',
        description: 'Monthly salary',
        amount: 45000,
        date: daysAgo(1, hour: 10, minute: 0),
        category: ExpenseCategory.other,
        type: TransactionType.income,
      ),
      Transaction(
        id: '4',
        description: 'Weekly groceries',
        amount: 1840,
        date: daysAgo(1, hour: 19, minute: 20),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '5',
        description: 'Pharmacy medicines',
        amount: 480,
        date: daysAgo(2, hour: 17, minute: 5),
        category: ExpenseCategory.health,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '6',
        description: 'Electricity bill',
        amount: 2150,
        date: daysAgo(3, hour: 11, minute: 0),
        category: ExpenseCategory.bills,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '7',
        description: 'Office cab ride',
        amount: 310,
        date: daysAgo(4, hour: 18, minute: 45),
        category: ExpenseCategory.travel,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '8',
        description: 'New running shoes',
        amount: 2499,
        date: daysAgo(5, hour: 16, minute: 30),
        category: ExpenseCategory.shopping,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '9',
        description: 'Internet bill',
        amount: 799,
        date: daysAgo(8, hour: 10, minute: 0),
        category: ExpenseCategory.bills,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '10',
        description: 'Weekend dinner',
        amount: 960,
        date: daysAgo(9, hour: 21, minute: 0),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      ),
      Transaction(
        id: '11',
        description: 'Lent money to a friend',
        amount: 2000,
        date: daysAgo(2, hour: 14, minute: 15),
        category: ExpenseCategory.loan,
        type: TransactionType.expense,
      ),
    ];
  }
}
