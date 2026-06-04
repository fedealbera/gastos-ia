import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesByDateRange implements UseCase<List<Expense>, DateRangeParams> {
  final ExpenseRepository repository;

  GetExpensesByDateRange(this.repository);

  @override
  Future<List<Expense>> call(DateRangeParams params) {
    return repository.getExpensesByDateRange(params.start, params.end);
  }
}

class DateRangeParams {
  final DateTime start;
  final DateTime end;

  const DateRangeParams({
    required this.start,
    required this.end,
  });
}
