import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/expense.dart';

class DashboardStats extends Equatable {
  final double totalSpent;
  final Map<String, double> categoryShares;
  final Map<String, String> categoryNames;
  final Map<String, String> categoryColors;
  final Map<String, int?> categoryIcons;
  final String? highestExpenseCategoryId;
  final Map<DateTime, double> dailySpend;
  final List<Expense> recentExpenses;

  const DashboardStats({
    required this.totalSpent,
    required this.categoryShares,
    required this.categoryNames,
    required this.categoryColors,
    required this.categoryIcons,
    this.highestExpenseCategoryId,
    required this.dailySpend,
    required this.recentExpenses,
  });

  @override
  List<Object?> get props => [
        totalSpent,
        categoryShares,
        categoryNames,
        categoryColors,
        categoryIcons,
        highestExpenseCategoryId,
        dailySpend,
        recentExpenses,
      ];
}
