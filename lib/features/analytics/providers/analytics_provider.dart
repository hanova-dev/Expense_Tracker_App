import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/currency_service.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/providers/expense_provider.dart';
import 'package:intl/intl.dart';

// Provides expenses converted to the global currency
final convertedExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseProvider);
  final globalCurrency = ref.watch(globalCurrencyProvider);

  return expenses.map((e) {
    if (e.originalCurrency == globalCurrency) return e;
    final convertedAmount =
        CurrencyService.convert(e.amount, e.originalCurrency, globalCurrency);
    return e.copyWith(amount: convertedAmount);
  }).toList();
});

// Category Breakdown for Pie Chart (Current Month, expenses only)
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(convertedExpensesProvider);
  final now = DateTime.now();

  final Map<String, double> breakdown = {};
  for (final expense in expenses) {
    if (!expense.isIncome &&
        expense.date.year == now.year &&
        expense.date.month == now.month) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }
  }
  return breakdown;
});

// Daily Spending for Bar Chart (Current Month, expenses only)
final dailySpendingProvider = Provider<Map<int, double>>((ref) {
  final expenses = ref.watch(convertedExpensesProvider);
  final now = DateTime.now();

  final Map<int, double> daily = {};
  for (final expense in expenses) {
    if (!expense.isIncome &&
        expense.date.year == now.year &&
        expense.date.month == now.month) {
      daily[expense.date.day] =
          (daily[expense.date.day] ?? 0) + expense.amount;
    }
  }
  return daily;
});

// Monthly Spending for Line Chart (Past 6 months, expenses only)
final monthlySpendingProvider =
    Provider<List<MapEntry<String, double>>>((ref) {
  final expenses = ref.watch(convertedExpensesProvider);
  final now = DateTime.now();

  final Map<String, double> monthly = {};

  for (int i = 5; i >= 0; i--) {
    final monthDate = DateTime(now.year, now.month - i, 1);
    final monthKey = DateFormat('MMM').format(monthDate);
    monthly[monthKey] = 0.0;
  }

  for (final expense in expenses) {
    if (expense.isIncome) continue;
    final differenceInMonths =
        (now.year - expense.date.year) * 12 + now.month - expense.date.month;
    if (differenceInMonths >= 0 && differenceInMonths < 6) {
      final monthKey = DateFormat('MMM').format(expense.date);
      if (monthly.containsKey(monthKey)) {
        monthly[monthKey] = (monthly[monthKey] ?? 0) + expense.amount;
      }
    }
  }

  return monthly.entries.toList();
});

// All transactions this month (income + expenses combined — used by budget card)
final totalThisMonthProvider = Provider<double>((ref) {
  final expenses = ref.watch(convertedExpensesProvider);
  final now = DateTime.now();
  return expenses
      .where((e) =>
          !e.isIncome &&
          e.date.year == now.year &&
          e.date.month == now.month)
      .fold(0.0, (sum, e) => sum + e.amount);
});

final totalTodayProvider = Provider<double>((ref) {
  final expenses = ref.watch(convertedExpensesProvider);
  final now = DateTime.now();
  return expenses
      .where((e) =>
          !e.isIncome &&
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day)
      .fold(0.0, (sum, e) => sum + e.amount);
});

// Income this month
final totalIncomeThisMonthProvider = Provider<double>((ref) {
  final expenses = ref.watch(convertedExpensesProvider);
  final now = DateTime.now();
  return expenses
      .where((e) =>
          e.isIncome &&
          e.date.year == now.year &&
          e.date.month == now.month)
      .fold(0.0, (sum, e) => sum + e.amount);
});

// Expenses only this month (excludes income entries)
final totalExpensesOnlyThisMonthProvider = Provider<double>((ref) {
  return ref.watch(totalThisMonthProvider);
});
