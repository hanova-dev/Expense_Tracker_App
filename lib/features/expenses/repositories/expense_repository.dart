import 'package:hive/hive.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final Box<Expense> _box;

  ExpenseRepository(this._box);

  List<Expense> getAllExpenses() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense(Expense expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }
}
