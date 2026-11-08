import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_settings.dart';
import '../models/expense_category.dart';
import '../models/transaction.dart';
import '../utils/money.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.transactions,
    required this.onSettingsChanged,
    required this.onClearTransactions,
  });

  final AppSettings settings;
  final List<Transaction> transactions;
  final Future<void> Function(AppSettings) onSettingsChanged;
  final Future<void> Function() onClearTransactions;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings = widget.settings;

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  Future<void> _saveSettings(AppSettings updated) async {
    await widget.onSettingsChanged(updated);
    if (mounted) {
      setState(() => _settings = updated);
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final name = await _promptText(
      context: context,
      title: 'Edit profile name',
      initialValue: _settings.profileName,
      label: 'Name',
    );
    if (name != null && name.isNotEmpty) {
      await _saveSettings(_settings.copyWith(profileName: name));
    }
  }

  Future<void> _choosePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_settings.profileImageBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove profile photo'),
                  onTap: () {
                    Navigator.pop(context, null);
                    _saveSettings(_settings.copyWith(removeProfileImage: true));
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    await _saveSettings(
      _settings.copyWith(profileImageBase64: base64Encode(bytes)),
    );
  }

  Future<void> _editBudget(BuildContext context) async {
    final value = await _promptText(
      context: context,
      title: 'Monthly budget',
      initialValue: _settings.monthlyBudget.toStringAsFixed(0),
      label: 'Budget amount',
      number: true,
    );
    final amount = value == null ? null : double.tryParse(value);
    if (amount != null) {
      await _saveSettings(_settings.copyWith(monthlyBudget: amount));
    }
  }

  Future<void> _editCategory(
    BuildContext context, {
    ExpenseCategory? category,
  }) async {
    final label = await _promptText(
      context: context,
      title: category == null ? 'Add category' : 'Rename category',
      initialValue: category?.label ?? '',
      label: 'Category name',
      maxLength: 24,
      showEmojis: true,
    );
    if (label == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final duplicate = _settings.categories.any(
      (item) =>
          item.id != category?.id &&
          item.label.toLowerCase() == label.toLowerCase(),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A category with that name already exists.'),
        ),
      );
      return;
    }
    final categories = [..._settings.categories];
    if (category == null) {
      categories.add(
        ExpenseCategory.custom(
          'custom-${DateTime.now().microsecondsSinceEpoch}',
          label,
        ),
      );
    } else {
      final index = categories.indexWhere((item) => item.id == category.id);
      categories[index] = category.withLabel(label);
    }
    await _saveSettings(_settings.copyWith(categories: categories));
  }

  Future<void> _removeCategory(
    BuildContext context,
    ExpenseCategory category,
  ) async {
    if (_settings.categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one expense category.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove category?'),
        content: Text(
          '“${category.label}” will be removed from the category list. '
          'Existing transactions keep their original category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _saveSettings(
        _settings.copyWith(
          categories: _settings.categories
              .where((item) => item.id != category.id)
              .toList(),
        ),
      );
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear transaction data?'),
        content: const Text(
          'This removes all current transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onClearTransactions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction data cleared.')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final backup = {
      'format': 'expense_tracker_backup_v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': widget.transactions.map((item) => item.toJson()).toList(),
      'settings': _settings.toJson(),
    };
    await SharePlus.instance.share(
      ShareParams(
        title: 'Expense tracker backup',
        subject: 'Expense tracker backup',
        text: const JsonEncoder.withIndent('  ').convert(backup),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(title: 'Profile'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: InkWell(
                    onTap: () => _choosePhoto(context),
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _ProfileAvatar(settings: _settings, radius: 28),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(_settings.profileName),
                  subtitle: const Text('Tap image to upload photo'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editProfile(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Currency'),
                  subtitle: const Text('Used throughout the dashboard'),
                  trailing: DropdownButton<String>(
                    value: _settings.currencyCode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: 'INR',
                        child: Text('Indian Rupee (₹)'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('US Dollar (\$)'),
                      ),
                      DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                      DropdownMenuItem(
                        value: 'GBP',
                        child: Text('British Pound (£)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _saveSettings(_settings.copyWith(currencyCode: value));
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Monthly budget'),
                  subtitle: Text(formatInr(_settings.monthlyBudget)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editBudget(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark theme'),
                  value: _settings.darkMode,
                  onChanged: (value) =>
                      _saveSettings(_settings.copyWith(darkMode: value)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Daily expense reminder'),
                  subtitle: Text(
                    'Remind me at ${TimeOfDay(hour: _settings.reminderHour, minute: _settings.reminderMinute).format(context)}',
                  ),
                  value: _settings.remindersEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _settings.reminderHour,
                          minute: _settings.reminderMinute,
                        ),
                      );
                      if (time != null) {
                        try {
                          await _saveSettings(
                            _settings.copyWith(
                              remindersEnabled: true,
                              reminderHour: time.hour,
                              reminderMinute: time.minute,
                            ),
                          );
                        } on StateError catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        }
                      }
                    } else {
                      await _saveSettings(
                        _settings.copyWith(remindersEnabled: false),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Budget alerts'),
                  subtitle: const Text('Notify at 80% and 100% of your budget'),
                  value: _settings.budgetAlertsEnabled,
                  onChanged: (value) async {
                    try {
                      await _saveSettings(
                        _settings.copyWith(budgetAlertsEnabled: value),
                      );
                    } on StateError catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'History'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('History'),
              subtitle: const Text('Browse completed months by week and day'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) =>
                        HistoryScreen(transactions: widget.transactions),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Categories'),
          Card(
            child: Column(
              children: [
                for (final category in _settings.categories)
                  ListTile(
                    leading: Icon(category.icon, color: category.color),
                    title: Text(category.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Rename ${category.label}',
                          onPressed: () =>
                              _editCategory(context, category: category),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Remove ${category.label}',
                          onPressed: () => _removeCategory(context, category),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add category'),
                  onTap: () => _editCategory(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('Export / back up data'),
                  subtitle: const Text(
                    'Share a JSON copy of transactions and settings',
                  ),
                  onTap: _exportData,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Clear transaction data'),
                  subtitle: const Text('Remove all current transactions'),
                  onTap: () => _clearData(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _promptText({
  required BuildContext context,
  required String title,
  required String initialValue,
  required String label,
  int? maxLength,
  bool number = false,
  bool showEmojis = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextEntryDialog(
      title: title,
      initialValue: initialValue,
      label: label,
      maxLength: maxLength,
      number: number,
      showEmojis: showEmojis,
    ),
  );
}

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({
    required this.title,
    required this.initialValue,
    required this.label,
    this.maxLength,
    this.number = false,
    this.showEmojis = false,
  });

  final String title;
  final String initialValue;
  final String label;
  final int? maxLength;
  final bool number;
  final bool showEmojis;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  void _insertSymbol(String symbol) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length).toInt()
        : text.length;
    final end = selection.isValid
        ? selection.end.clamp(start, text.length).toInt()
        : text.length;
    final updated = text.replaceRange(start, end, symbol);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLength: widget.maxLength,
              keyboardType: widget.number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: widget.label),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Enter a value';
                }
                if (widget.number) {
                  final amount = double.tryParse(text);
                  if (amount == null || amount <= 0) {
                    return 'Enter an amount greater than 0';
                  }
                }
                return null;
              },
            ),
            if (widget.showEmojis) ...[
              const SizedBox(height: 8),
              Text(
                'Add icon / GIF',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 0,
                children:
                    [
                          '🍔',
                          '🍷',
                          '🛒',
                          '🚗',
                          '🏠',
                          '💊',
                          '🎮',
                          '🐾',
                          '✈️',
                          '💰',
                          '☕',
                          '🍕',
                        ]
                        .map(
                          (emoji) => ActionChip(
                            label: Text(emoji),
                            onPressed: () => _insertSymbol(emoji),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.settings, this.radius = 20});

  final AppSettings settings;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = settings.profileImageBase64;
    final image = bytes == null
        ? null
        : Uint8List.fromList(base64Decode(bytes));
    final initials = settings.profileName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundImage: image == null ? null : MemoryImage(image),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: image == null ? Text(initials) : null,
    );
  }
}
