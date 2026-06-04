import 'package:hive/hive.dart';
import '../models/expense_model.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<void> saveExpense(ExpenseModel model);
  Future<void> deleteExpense(String id);
}

class HiveExpenseLocalDataSource implements ExpenseLocalDataSource {
  final Box<ExpenseModel> expenseBox;

  HiveExpenseLocalDataSource(this.expenseBox);

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    return expenseBox.values.toList();
  }

  @override
  Future<void> saveExpense(ExpenseModel model) async {
    await expenseBox.put(model.id, model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }
}
