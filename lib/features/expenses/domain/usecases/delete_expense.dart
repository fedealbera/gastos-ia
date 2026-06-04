import '../../../../core/usecases/usecase.dart';
import '../repositories/expense_repository.dart';

class DeleteExpense implements UseCase<void, String> {
  final ExpenseRepository repository;

  DeleteExpense(this.repository);

  @override
  Future<void> call(String id) {
    return repository.deleteExpense(id);
  }
}
