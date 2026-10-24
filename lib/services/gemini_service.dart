import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/expense_category.dart';

class ProposedExpense {
  final double amount;
  final String description;
  final ExpenseCategory category;
  final DateTime date;
  final String? paymentMethod;

  const ProposedExpense({
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.paymentMethod,
  });
}

class GeminiResponse {
  final String textResponse;
  final ProposedExpense? proposedExpense;

  const GeminiResponse({
    required this.textResponse,
    this.proposedExpense,
  });
}

class GeminiService {
  GenerativeModel? _model;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      return;
    }
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _initialized = true;
  }

  Future<GeminiResponse> processUserQuery({
    required String userQuery,
    required String summaryContext,
  }) async {
    if (!_initialized || _model == null) {
      initialize();
    }

    if (_model == null) {
      throw StateError(
        'Gemini is not configured. Use a trusted backend for production; '
        'do not embed the API key in the mobile app.',
      );
    }

    final prompt = '''
You are an intelligent financial assistant for an offline-first expense tracker app.

User Query: "$userQuery"

Minimal Financial Summary Context from Local Database:
$summaryContext

Instructions:
1. Determine if the user wants to LOG A NEW EXPENSE/TRANSACTION (e.g., "I spent 250 on lunch", "Paid 1200 for electricity bill", "Bought shoes for 1500 with Card").
2. If logging an expense, return ONLY a JSON object with this EXACT structure (no markdown code blocks, no extra text):
{"is_expense": true, "amount": <number in rupees>, "description": "<short description>", "category": "<one of: food, travel, shopping, bills, health, loan, other>", "payment_method": "<optional text or null>"}

3. If asking a question or seeking spending insights (e.g. "How much did I spend this month?", "Which category costs me the most?", "Am I within my budget?"), return a natural, helpful, encouraging response in 2-3 concise sentences based strictly on the provided financial summary context.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      var responseText = response.text?.trim() ?? 'No response received.';

      // Clean markdown code fence if wrapped by LLM
      if (responseText.startsWith('```json')) {
        responseText =
            responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (responseText.startsWith('```')) {
        responseText = responseText.replaceAll('```', '').trim();
      }

      // Try parsing JSON for expense entry intent
      if (responseText.startsWith('{') && responseText.endsWith('}')) {
        try {
          final decoded = jsonDecode(responseText) as Map<String, dynamic>;
          if (decoded['is_expense'] == true) {
            final amount = (decoded['amount'] as num).toDouble();
            final description =
                (decoded['description'] as String?)?.trim() ?? 'Expense';
            final categoryStr =
                (decoded['category'] as String?)?.toLowerCase() ?? 'other';
            final paymentMethod = decoded['payment_method'] as String?;

            ExpenseCategory category = ExpenseCategory.other;
            for (final c in ExpenseCategory.values) {
              if (c.id.toLowerCase() == categoryStr) {
                category = c;
                break;
              }
            }

            final proposed = ProposedExpense(
              amount: amount,
              description: description,
              category: category,
              date: DateTime.now(),
              paymentMethod: paymentMethod,
            );

            return GeminiResponse(
              textResponse:
                  'I extracted the expense details from your message. Please review the details below and confirm to save.',
              proposedExpense: proposed,
            );
          }
        } catch (_) {
          // Fall back to text response if JSON parsing fails
        }
      }

      return GeminiResponse(textResponse: responseText);
    } catch (e) {
      final err = e.toString();
      if (err.contains('PERMISSION_DENIED') ||
          err.contains('Verify your account') ||
          err.contains('API_KEY_INVALID') ||
          err.contains('API key not valid')) {
        return const GeminiResponse(
          textResponse:
              '⚠️ Gemini API access is not configured. Configure a trusted backend to protect the API key before enabling this feature.',
        );
      }
      return GeminiResponse(
        textResponse:
            '⚠️ Error communicating with Gemini Pro: ${err.replaceAll("Exception: ", "")}',
      );
    }
  }
}
