import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/app.dart';

void main() {
  testWidgets('Dashboard shows summary sections and add button', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(find.text('My Expense Tracker'), findsOneWidget);
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
    expect(find.text('Other'), findsWidgets);
    expect(find.text('Lent money to a friend'), findsOneWidget);
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.text('Breakfast at cafe'), findsOneWidget);
    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(
      find.widgetWithText(FloatingActionButton, 'Add Expense'),
      findsOneWidget,
    );
  });

  testWidgets('Add expense dialog validates amount and can be cancelled', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExpenseTrackerApp());
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
}
