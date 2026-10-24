import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense_category.dart';
import '../models/transaction.dart';
import '../utils/money.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key, required this.categories});

  final List<ExpenseCategory> categories;

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late ExpenseCategory _category = widget.categories.first;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      Transaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        description: description.isEmpty ? 'New expense' : description,
        amount: amount,
        date: DateTime.now(),
        category: _category,
        type: TransactionType.expense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount ($currencySymbol)',
                  hintText: '500',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter an amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Lunch with friends',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in widget.categories)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

Future<Transaction?> showAddExpenseDialog(
  BuildContext context, {
  required List<ExpenseCategory> categories,
}) {
  return showDialog<Transaction>(
    context: context,
    builder: (context) => AddExpenseDialog(categories: categories),
  );
}
