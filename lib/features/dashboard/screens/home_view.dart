import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/currency_service.dart';
import '../../../core/constants.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../settings/models/budget_model.dart';
import 'package:hive/hive.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalThisMonth = ref.watch(totalThisMonthProvider);
    final totalToday = ref.watch(totalTodayProvider);
    final expenses = ref.watch(expenseProvider);
    final globalCurrency = ref.watch(globalCurrencyProvider);

    // Fetch budget if any
    final budgetBox = Hive.box<Budget>('budgets');
    final overallBudget = budgetBox.get('Total')?.amount;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'This Month',
                          amount: CurrencyService.format(totalThisMonth),
                          color: theme.colorScheme.primaryContainer,
                          textColor: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Today',
                          amount: CurrencyService.format(totalToday),
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  if (overallBudget != null) ...[
                    const SizedBox(height: 16),
                    _BudgetProgressCard(totalThisMonth: totalThisMonth, budget: overallBudget),
                  ],
                  const SizedBox(height: 32),
                  Text('Recent Transactions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          expenses.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No expenses yet.\nTap + to add one!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenses[index];
                      final isConverted = expense.originalCurrency != globalCurrency;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstants.categoryColors[expense.category]?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                          child: Icon(AppConstants.categoryIcons[expense.category] ?? Icons.receipt, color: AppConstants.categoryColors[expense.category]),
                        ),
                        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${expense.category} • ${DateFormat('MMM dd').format(expense.date)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyService.format(expense.amount, expense.originalCurrency),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (isConverted)
                              Text(
                                '~ ${CurrencyService.format(CurrencyService.convert(expense.amount, expense.originalCurrency, globalCurrency))}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: expenses.length > 5 ? 5 : expenses.length, // Show up to 5 recent
                  ),
                ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final Color textColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final double totalThisMonth;
  final double budget;

  const _BudgetProgressCard({
    required this.totalThisMonth,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalThisMonth / budget).clamp(0.0, 1.0);
    final isOverBudget = totalThisMonth > budget;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget', style: theme.textTheme.titleMedium),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: isOverBudget ? Colors.red : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? Colors.red : theme.colorScheme.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            isOverBudget 
                ? 'You have exceeded your budget by ${CurrencyService.format(totalThisMonth - budget)}'
                : '${CurrencyService.format(budget - totalThisMonth)} remaining',
            style: TextStyle(color: isOverBudget ? Colors.red : Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
