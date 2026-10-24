import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_settings.dart';
import 'data/notification_service.dart';
import 'models/transaction.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'utils/expense_totals.dart';
import 'utils/money.dart';

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  AppSettings _settings = const AppSettings();
  List<Transaction> _transactions = const [];
  bool _ready = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _loadError = null);
    }
    try {
      final (settings, transactions) = await _loadPersistedData().timeout(
        const Duration(seconds: 30),
      );
      if (!mounted) {
        return;
      }
      setCurrencyCode(settings.currencyCode);
      setState(() {
        _settings = settings;
        _transactions = transactions;
        _ready = true;
      });
    } on TimeoutException {
      _showLoadError(
        'App startup took longer than 30 seconds. Check the phone and try again.',
      );
    } on Object catch (error) {
      _showLoadError(error.toString());
    }
  }

  void _showLoadError(String error) {
    if (!mounted) {
      return;
    }
    setState(() => _loadError = error);
  }

  Future<(AppSettings, List<Transaction>)> _loadPersistedData() async {
    final preferences = await SharedPreferences.getInstance();
    var settings = await AppSettings.load();
    final savedTransactions = preferences.getString('transactions');
    final savedTransactionsList = savedTransactions == null
        ? <Transaction>[]
        : (jsonDecode(savedTransactions) as List<dynamic>)
              .map(
                (value) => Transaction.fromJson(value as Map<String, dynamic>),
              )
              .toList();
    final categoriesById = {
      for (final category in settings.categories) category.id: category,
    };
    final transactions = savedTransactionsList.map((transaction) {
      final category = categoriesById[transaction.category.id];
      return category == null
          ? transaction
          : transaction.copyWith(category: category);
    }).toList();
    if (settings.remindersEnabled) {
      final scheduled = await NotificationService.instance
          .scheduleDailyReminder(
            hour: settings.reminderHour,
            minute: settings.reminderMinute,
          );
      if (!scheduled) {
        final updated = settings.copyWith(remindersEnabled: false);
        await updated.save();
        settings = updated;
      }
    }
    return (settings, transactions);
  }

  Future<void> _updateSettings(AppSettings updated) async {
    if (updated.remindersEnabled) {
      if (!_settings.remindersEnabled ||
          updated.reminderHour != _settings.reminderHour ||
          updated.reminderMinute != _settings.reminderMinute) {
        final scheduled = await NotificationService.instance
            .scheduleDailyReminder(
              hour: updated.reminderHour,
              minute: updated.reminderMinute,
            );
        if (!scheduled) {
          throw StateError(
            'Notification permission is unavailable or unsupported.',
          );
        }
      }
    } else if (_settings.remindersEnabled) {
      await NotificationService.instance.cancelDailyReminder();
    }
    if (updated.budgetAlertsEnabled && !_settings.budgetAlertsEnabled) {
      final allowed = await NotificationService.instance
          .requestNotificationPermission();
      if (!allowed) {
        throw StateError(
          'Notification permission is required for budget alerts.',
        );
      }
    }

    final categoriesById = {
      for (final category in updated.categories) category.id: category,
    };
    final remappedTransactions = _transactions.map((transaction) {
      final category = categoriesById[transaction.category.id];
      return category == null
          ? transaction
          : transaction.copyWith(category: category);
    }).toList();
    await updated.save();
    await _saveTransactions(remappedTransactions);
    setCurrencyCode(updated.currencyCode);
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = updated;
      _transactions = remappedTransactions;
    });
  }

  Future<void> _updateTransactions(List<Transaction> updated) async {
    final oldSpent = ExpenseTotals.thisMonth(_transactions);
    final newSpent = ExpenseTotals.thisMonth(updated);
    await _saveTransactions(updated);
    if (!mounted) {
      return;
    }
    setState(() => _transactions = updated);

    if (!_settings.budgetAlertsEnabled || newSpent <= oldSpent) {
      return;
    }
    final budget = _settings.monthlyBudget;
    final thresholds = [
      (id: 2, fraction: 0.8, title: 'Budget almost reached'),
      (id: 3, fraction: 1.0, title: 'Monthly budget reached'),
    ];
    for (final threshold in thresholds) {
      if (oldSpent < budget * threshold.fraction &&
          newSpent >= budget * threshold.fraction) {
        await NotificationService.instance.showBudgetAlert(
          id: threshold.id,
          title: threshold.title,
          message:
              'You have spent ${formatInr(newSpent)} of your ${formatInr(budget)} budget.',
        );
      }
    }
  }

  Future<void> _saveTransactions(List<Transaction> transactions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'transactions',
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        title: 'My Expense Tracker',
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: _loadError == null
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading expense tracker...'),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SpendNote could not finish starting.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      );
    }
    final image = _settings.profileImageBase64;
    return MaterialApp(
      title: 'My Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: DashboardScreen(
        settings: _settings,
        transactions: _transactions,
        profileImage: image == null
            ? null
            : MemoryImage(Uint8List.fromList(base64Decode(image))),
        onSettingsChanged: _updateSettings,
        onTransactionsChanged: _updateTransactions,
      ),
    );
  }
}
