import '../../../../core/usecases/usecase.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/domain/usecases/get_expenses_by_date_range.dart';
import '../entities/dashboard_stats.dart';

class GetDashboardStats implements UseCase<DashboardStats, DateRangeParams> {
  final ExpenseRepository expenseRepository;

  GetDashboardStats(this.expenseRepository);

  @override
  Future<DashboardStats> call(DateRangeParams params) async {
    final expenses = await expenseRepository.getExpensesByDateRange(params.start, params.end);

    double totalSpent = 0.0;
    final Map<String, double> categoryShares = {};
    final Map<String, String> categoryNames = {};
    final Map<String, String> categoryColors = {};
    final Map<String, int?> categoryIcons = {};
    final Map<DateTime, double> dailySpend = {};

    // Sort expenses by date descending to extract recent ones
    final sortedExpenses = List.of(expenses)..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    final recentExpenses = sortedExpenses.take(5).toList();

    for (final expense in expenses) {
      totalSpent += expense.amount;

      // Group by Category
      categoryShares[expense.categoryId] = (categoryShares[expense.categoryId] ?? 0.0) + expense.amount;
      categoryNames[expense.categoryId] = expense.categoryName;
      categoryColors[expense.categoryId] = expense.categoryColorHex;
      categoryIcons[expense.categoryId] = expense.categoryIconCodePoint;

      // Group by Day (normalized date)
      final day = DateTime(expense.expenseDate.year, expense.expenseDate.month, expense.expenseDate.day);
      dailySpend[day] = (dailySpend[day] ?? 0.0) + expense.amount;
    }

    // Find highest expense category
    String? highestExpenseCategoryId;
    double maxSpent = -1.0;
    categoryShares.forEach((catId, spent) {
      if (spent > maxSpent) {
        maxSpent = spent;
        highestExpenseCategoryId = catId;
      }
    });

    return DashboardStats(
      totalSpent: totalSpent,
      categoryShares: categoryShares,
      categoryNames: categoryNames,
      categoryColors: categoryColors,
      categoryIcons: categoryIcons,
      highestExpenseCategoryId: highestExpenseCategoryId,
      dailySpend: dailySpend,
      recentExpenses: recentExpenses,
    );
  }
}
