import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final box = Hive.box<Expense>('expenses');
  return ExpenseRepository(box);
});

class ExpenseNotifier extends Notifier<List<Expense>> {
  @override
  List<Expense> build() {
    final repository = ref.watch(expenseRepositoryProvider);
    return repository.getAllExpenses();
  }

  Future<void> addExpense(Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.addExpense(expense);
    state = repository.getAllExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.updateExpense(expense);
    state = repository.getAllExpenses();
  }

  Future<void> deleteExpense(String id) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.deleteExpense(id);
    state = repository.getAllExpenses();
  }
}

final expenseProvider = NotifierProvider<ExpenseNotifier, List<Expense>>(() {
  return ExpenseNotifier();
});
