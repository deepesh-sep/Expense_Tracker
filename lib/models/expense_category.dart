import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  static const food = ExpenseCategory(
    id: 'food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFE07A3D),
  );
  static const travel = ExpenseCategory(
    id: 'travel',
    label: 'Travel',
    icon: Icons.directions_bus_rounded,
    color: Color(0xFF3B82F6),
  );
  static const shopping = ExpenseCategory(
    id: 'shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF8B5CF6),
  );
  static const bills = ExpenseCategory(
    id: 'bills',
    label: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFF0D9488),
  );
  static const health = ExpenseCategory(
    id: 'health',
    label: 'Health',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFF22C55E),
  );
  static const loan = ExpenseCategory(
    id: 'loan',
    label: 'Loan',
    icon: Icons.handshake_rounded,
    color: Color(0xFFCA8A04),
  );
  static const drink = ExpenseCategory(
    id: 'drink',
    label: 'Drink',
    icon: Icons.local_bar_rounded,
    color: Color(0xFF06B6D4),
  );
  static const other = ExpenseCategory(
    id: 'other',
    label: 'Other',
    icon: Icons.category_rounded,
    color: Color(0xFF64748B),
  );

  static const values = [
    food,
    travel,
    shopping,
    bills,
    health,
    loan,
    drink,
    other,
  ];

  factory ExpenseCategory.custom(String id, String label) {
    return ExpenseCategory(
      id: id,
      label: label,
      icon: Icons.category_rounded,
      color: other.color,
    );
  }

  ExpenseCategory withLabel(String value) {
    return ExpenseCategory(id: id, label: value, icon: icon, color: color);
  }

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final label = json['label'] as String;
    for (final category in values) {
      if (category.id == id) {
        return category.withLabel(label);
      }
    }
    return ExpenseCategory.custom(id, label);
  }

  Map<String, String> toJson() => {'id': id, 'label': label};

  @override
  bool operator ==(Object other) => other is ExpenseCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
