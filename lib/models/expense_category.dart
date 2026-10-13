import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  travel,
  shopping,
  bills,
  health,
  loan,
  other,
}

extension ExpenseCategoryUi on ExpenseCategory {
  String get label {
    return switch (this) {
      ExpenseCategory.food => 'Food',
      ExpenseCategory.travel => 'Travel',
      ExpenseCategory.shopping => 'Shopping',
      ExpenseCategory.bills => 'Bills',
      ExpenseCategory.health => 'Health',
      ExpenseCategory.loan => 'Loan',
      ExpenseCategory.other => 'Other',
    };
  }

  IconData get icon {
    return switch (this) {
      ExpenseCategory.food => Icons.restaurant_rounded,
      ExpenseCategory.travel => Icons.directions_bus_rounded,
      ExpenseCategory.shopping => Icons.shopping_bag_rounded,
      ExpenseCategory.bills => Icons.receipt_long_rounded,
      ExpenseCategory.health => Icons.local_hospital_rounded,
      ExpenseCategory.loan => Icons.handshake_rounded,
      ExpenseCategory.other => Icons.category_rounded,
    };
  }

  Color get color {
    return switch (this) {
      ExpenseCategory.food => const Color(0xFFE07A3D),
      ExpenseCategory.travel => const Color(0xFF3B82F6),
      ExpenseCategory.shopping => const Color(0xFF8B5CF6),
      ExpenseCategory.bills => const Color(0xFF0D9488),
      ExpenseCategory.health => const Color(0xFF22C55E),
      ExpenseCategory.loan => const Color(0xFFCA8A04),
      ExpenseCategory.other => const Color(0xFF64748B),
    };
  }
}
