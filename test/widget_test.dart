import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/utils/money.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Amounts show currency symbols instead of currency codes', () {
    const currencies = {
      'INR': '₹',
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
    };

    for (final entry in currencies.entries) {
      setCurrencyCode(entry.key);
      final formatted = formatInr(1250);
      expect(formatted, contains(entry.value));
      expect(formatted, isNot(contains(entry.key)));
    }
    setCurrencyCode('INR');
  });

  testWidgets('Startup failures show details and allow retry', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'appSettings': '{invalid'});

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('SpendNote could not finish starting.'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });

  testWidgets('Dashboard shows summary sections and add button', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);
    expect(
      find.text(DateFormat('EEEE, d MMMM').format(DateTime.now())),
      findsOneWidget,
    );
    expect(find.text("Today's expenses"), findsOneWidget);
    expect(find.text("This week's expenses"), findsOneWidget);
    expect(find.text("This month's expenses"), findsOneWidget);
    expect(find.text('Budget remaining'), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Travel'), findsWidgets);
    expect(find.text('Shopping'), findsWidgets);
    expect(find.text('Bills'), findsWidgets);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('Loan'), findsWidgets);
    expect(find.text('Drink'), findsWidgets);
    expect(find.text('Other'), findsWidgets);
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.text('No transactions yet.'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(
      find.widgetWithText(FloatingActionButton, 'Add Expense'),
      findsOneWidget,
    );
  });

  testWidgets('Legacy category settings add Drink to spending chart', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'appSettings': '{"categories":[{"id":"food","label":"Food"}]}',
    });
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Drink'), findsOneWidget);
    final storedSettings = await SharedPreferences.getInstance();
    expect(storedSettings.getString('appSettings'), contains('"id":"drink"'));
    expect(storedSettings.getInt('categoryCatalogVersion'), 1);
  });

  testWidgets('Add expense dialog validates amount and can be cancelled', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsWidgets);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount greater than 0'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount greater than 0'), findsNothing);
  });

  testWidgets('Settings exposes preferences and category management', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    expect(find.text('Daily expense reminder'), findsOneWidget);
    expect(find.text('Budget alerts'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Add category'), findsOneWidget);
    final currencyDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(
      currencyDropdown.items!
          .map((item) => (item.child as Text).data)
          .toList(),
      [
        'Indian Rupee (₹)',
        r'US Dollar ($)',
        'Euro (€)',
        'British Pound (£)',
      ],
    );

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.text('Add category'), findsNWidgets(2));
    await tester.enterText(find.byType(EditableText).last, 'Pets');
    await tester.tap(find.widgetWithText(ActionChip, '🐾'));
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      'Pets🐾',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Add category'), findsOneWidget);
    final storedSettings = await SharedPreferences.getInstance();
    expect(storedSettings.getString('appSettings'), contains('Pets🐾'));
    expect(find.text('Pets🐾'), findsOneWidget);
    expect(find.text('Export / back up data'), findsOneWidget);
    expect(find.text('Clear transaction data'), findsOneWidget);
  });
}
