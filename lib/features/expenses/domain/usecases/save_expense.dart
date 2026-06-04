import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class SaveExpense implements UseCase<void, Expense> {
  final ExpenseRepository repository;

  SaveExpense(this.repository);

  @override
  Future<void> call(Expense expense) {
    return repository.saveExpense(expense);
  }
}
