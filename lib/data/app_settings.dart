import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_category.dart';

class AppSettings {
  static const _categoryCatalogVersionKey = 'categoryCatalogVersion';
  static const _categoryCatalogVersion = 1;

  const AppSettings({
    this.profileName = 'Alex Morgan',
    this.profileImageBase64,
    this.currencyCode = 'INR',
    this.monthlyBudget = 20000,
    this.darkMode = false,
    this.remindersEnabled = false,
    this.budgetAlertsEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.categories = ExpenseCategory.values,
  });

  final String profileName;
  final String? profileImageBase64;
  final String currencyCode;
  final double monthlyBudget;
  final bool darkMode;
  final bool remindersEnabled;
  final bool budgetAlertsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final List<ExpenseCategory> categories;

  AppSettings copyWith({
    String? profileName,
    String? profileImageBase64,
    bool removeProfileImage = false,
    String? currencyCode,
    double? monthlyBudget,
    bool? darkMode,
    bool? remindersEnabled,
    bool? budgetAlertsEnabled,
    int? reminderHour,
    int? reminderMinute,
    List<ExpenseCategory>? categories,
  }) {
    return AppSettings(
      profileName: profileName ?? this.profileName,
      profileImageBase64: removeProfileImage
          ? null
          : profileImageBase64 ?? this.profileImageBase64,
      currencyCode: currencyCode ?? this.currencyCode,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      darkMode: darkMode ?? this.darkMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      categories: categories ?? this.categories,
    );
  }

  Map<String, Object?> toJson() => {
    'profileName': profileName,
    'profileImageBase64': profileImageBase64,
    'currencyCode': currencyCode,
    'monthlyBudget': monthlyBudget,
    'darkMode': darkMode,
    'remindersEnabled': remindersEnabled,
    'budgetAlertsEnabled': budgetAlertsEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'categories': categories.map((category) => category.toJson()).toList(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final savedCategories = (json['categories'] as List<dynamic>?)
        ?.map(
          (value) => ExpenseCategory.fromJson(value as Map<String, dynamic>),
        )
        .toList();
    return AppSettings(
      profileName: json['profileName'] as String? ?? 'Alex Morgan',
      profileImageBase64: json['profileImageBase64'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 20000,
      darkMode: json['darkMode'] as bool? ?? false,
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      budgetAlertsEnabled: json['budgetAlertsEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      categories: savedCategories == null || savedCategories.isEmpty
          ? ExpenseCategory.values
          : savedCategories,
    );
  }

  static Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('appSettings');
    if (value == null) {
      return const AppSettings();
    }
    var settings = AppSettings.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
    final savedCatalogVersion =
        preferences.getInt(_categoryCatalogVersionKey) ?? 0;
    if (savedCatalogVersion < _categoryCatalogVersion) {
      final categories = [...settings.categories];
      if (!categories.any(
        (category) => category.id == ExpenseCategory.drink.id,
      )) {
        categories.add(ExpenseCategory.drink);
        settings = settings.copyWith(categories: categories);
      }
      await settings.save();
    }
    return settings;
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('appSettings', jsonEncode(toJson()));
    await preferences.setInt(
      _categoryCatalogVersionKey,
      _categoryCatalogVersion,
    );
  }
}
