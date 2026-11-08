import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/data/app_settings.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/screens/dashboard_screen.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:expense_tracker/utils/expense_totals.dart';
import 'package:expense_tracker/utils/money.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Amounts show currency symbols instead of currency codes', () {
    const currencies = {'INR': '₹', 'USD': r'$', 'EUR': '€', 'GBP': '£'};

    for (final entry in currencies.entries) {
      setCurrencyCode(entry.key);
      final formatted = formatInr(1250);
      expect(formatted, contains(entry.value));
      expect(formatted, isNot(contains(entry.key)));
    }
    setCurrencyCode('INR');
  });

  test('Weekly total includes only the current Monday-to-Sunday week', () {
    final items = [
      for (final entry in [
        (DateTime(2026, 11, 8), 10.0),
        (DateTime(2026, 11, 9), 20.0),
        (DateTime(2026, 11, 15), 30.0),
        (DateTime(2026, 11, 16), 40.0),
      ])
        Transaction(
          id: entry.$1.toIso8601String(),
          description: 'Purchase',
          amount: entry.$2,
          date: entry.$1,
          category: ExpenseCategory.food,
          type: TransactionType.expense,
        ),
    ];

    expect(ExpenseTotals.thisWeek(items, now: DateTime(2026, 11, 9)), 50);
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
      findsNWidgets(2),
    );
    expect(find.text("Today's expenses"), findsOneWidget);
    expect(find.text("This week's expenses"), findsOneWidget);
    expect(find.text("This month's expenses"), findsOneWidget);
    final now = DateTime.now();
    expect(find.text(DateFormat('EEEE, d MMMM').format(now)), findsNWidgets(2));
    final weekOfMonth =
        (now.day + DateTime(now.year, now.month, 1).weekday - 2) ~/ 7 + 1;
    expect(
      find.text('${DateFormat('MMMM').format(now)} · Week $weekOfMonth'),
      findsOneWidget,
    );
    expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);
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

  testWidgets('Daily, weekly, and monthly cards open matching transactions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final transactions = [
      Transaction(
        id: 'today',
        description: 'Today purchase',
        amount: 10,
        date: now,
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      ),
      Transaction(
        id: 'last-week',
        description: 'Last week purchase',
        amount: 20,
        date: weekStart.subtract(const Duration(days: 1)),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      ),
      Transaction(
        id: 'last-month',
        description: 'Last month purchase',
        amount: 30,
        date: DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1)),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          settings: const AppSettings(),
          transactions: transactions,
          onSettingsChanged: (_) async {},
          onTransactionsChanged: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapCardAndExpect({
      required String cardTitle,
      required String sheetTitle,
      required List<String> included,
      required List<String> excluded,
    }) async {
      await tester.tap(find.text(cardTitle));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text(sheetTitle)),
        findsOneWidget,
      );
      for (final description in included) {
        expect(
          find.descendant(of: sheet, matching: find.text(description)),
          findsOneWidget,
        );
      }
      for (final description in excluded) {
        expect(
          find.descendant(of: sheet, matching: find.text(description)),
          findsNothing,
        );
      }
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
    }

    await tapCardAndExpect(
      cardTitle: "Today's expenses",
      sheetTitle: "Today's transactions",
      included: ['Today purchase'],
      excluded: ['Last week purchase', 'Last month purchase'],
    );
    await tapCardAndExpect(
      cardTitle: "This week's expenses",
      sheetTitle: "This week's transactions",
      included: ['Today purchase'],
      excluded: ['Last week purchase', 'Last month purchase'],
    );
    await tapCardAndExpect(
      cardTitle: "This month's expenses",
      sheetTitle: "This month's transactions",
      included: ['Today purchase'],
      excluded: ['Last month purchase'],
    );
  });

  testWidgets('Settings history browses completed months by week and day', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = currentMonth.subtract(const Duration(days: 1));
    final olderDay = DateTime(lastMonth.year, lastMonth.month, 11, 10);
    final newerDay = DateTime(lastMonth.year, lastMonth.month, 10, 10);
    final previousMonthTransaction = Transaction(
      id: 'completed-month',
      description: 'Completed month purchase',
      amount: 25,
      date: newerDay,
      category: ExpenseCategory.food,
      type: TransactionType.expense,
    );
    final sameWeekTransaction = Transaction(
      id: 'same-week',
      description: 'Another day purchase',
      amount: 15,
      date: olderDay,
      category: ExpenseCategory.food,
      type: TransactionType.expense,
    );
    final currentMonthTransaction = Transaction(
      id: 'current-month',
      description: 'Current month purchase',
      amount: 35,
      date: now,
      category: ExpenseCategory.food,
      type: TransactionType.expense,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settings: const AppSettings(),
          transactions: [
            previousMonthTransaction,
            sameWeekTransaction,
            currentMonthTransaction,
          ],
          onSettingsChanged: (_) async {},
          onClearTransactions: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final historyTile = find.widgetWithText(ListTile, 'History');
    await tester.scrollUntilVisible(
      historyTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(historyTile);
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat('MMMM yyyy').format(lastMonth)),
      findsOneWidget,
    );
    expect(find.text(DateFormat('MMMM yyyy').format(now)), findsNothing);
    await tester.tap(find.text(DateFormat('MMMM yyyy').format(lastMonth)));
    await tester.pumpAndSettle();

    final weekNumber =
        (newerDay.day +
                DateTime(newerDay.year, newerDay.month, 1).weekday -
                2) ~/
            7 +
        1;
    await tester.tap(find.text('Week $weekNumber'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DateFormat('EEEE, d MMMM').format(newerDay)));
    await tester.pumpAndSettle();

    expect(find.text('Completed month purchase'), findsOneWidget);
    expect(find.text('Current month purchase'), findsNothing);
  });

  testWidgets(
    'Category chart opens matching current-month expense transactions',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final now = DateTime.now();
      final currentMonthExpense = Transaction(
        id: 'current-expense',
        description: 'Current food purchase',
        amount: 25,
        date: DateTime(now.year, now.month, 1, 10),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      );
      final currentMonthIncome = Transaction(
        id: 'current-income',
        description: 'Food refund',
        amount: 5,
        date: now,
        category: ExpenseCategory.food,
        type: TransactionType.income,
      );
      final previousMonthExpense = Transaction(
        id: 'previous-expense',
        description: 'Previous month food',
        amount: 15,
        date: DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1)),
        category: ExpenseCategory.food,
        type: TransactionType.expense,
      );
      final otherCategoryExpense = Transaction(
        id: 'other-category',
        description: 'Travel purchase',
        amount: 20,
        date: now,
        category: ExpenseCategory.travel,
        type: TransactionType.expense,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            settings: const AppSettings(),
            transactions: [
              currentMonthExpense,
              currentMonthIncome,
              previousMonthExpense,
              otherCategoryExpense,
            ],
            onSettingsChanged: (_) async {},
            onTransactionsChanged: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final foodCategory = find.text('Food');
      await tester.scrollUntilVisible(
        foodCategory,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(foodCategory);
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      expect(
        find.descendant(
          of: bottomSheet,
          matching: find.text('Food transactions'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: bottomSheet,
          matching: find.text('Current food purchase'),
        ),
        findsOneWidget,
      );
      for (final excluded in [
        'Food refund',
        'Previous month food',
        'Travel purchase',
      ]) {
        expect(
          find.descendant(of: bottomSheet, matching: find.text(excluded)),
          findsNothing,
        );
      }
    },
  );

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
      currencyDropdown.items!.map((item) => (item.child as Text).data).toList(),
      ['Indian Rupee (₹)', r'US Dollar ($)', 'Euro (€)', 'British Pound (£)'],
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
