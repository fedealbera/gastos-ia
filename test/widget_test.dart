import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gastos_ia/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:gastos_ia/features/expenses/domain/repositories/expense_repository.dart';
import 'package:gastos_ia/features/expenses/domain/entities/expense.dart';
import 'package:gastos_ia/features/expenses/domain/usecases/get_expenses_by_date_range.dart';

// Create a mock class for the repository
class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late GetDashboardStats getDashboardStats;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    getDashboardStats = GetDashboardStats(mockExpenseRepository);
  });

  final testExpenses = [
    Expense(
      id: '1',
      categoryId: 'cat_supermarket',
      categoryName: 'Supermercado',
      categoryColorHex: '#3B82F6',
      amount: 42000,
      description: 'Compra semanal',
      expenseDate: DateTime(2026, 5, 12),
      createdAt: DateTime.now(),
    ),
    Expense(
      id: '2',
      categoryId: 'cat_fuel',
      categoryName: 'Combustible',
      categoryColorHex: '#EF4444',
      amount: 25000,
      description: 'Carga nafta',
      expenseDate: DateTime(2026, 5, 10),
      createdAt: DateTime.now(),
    ),
    Expense(
      id: '3',
      categoryId: 'cat_supermarket',
      categoryName: 'Supermercado',
      categoryColorHex: '#3B82F6',
      amount: 18000,
      description: 'Verduleria',
      expenseDate: DateTime(2026, 5, 12),
      createdAt: DateTime.now(),
    ),
  ];

  test('debe calcular correctamente las estadisticas y agregaciones', () async {
    // Arrange
    final start = DateTime(2026, 5, 1);
    final end = DateTime(2026, 5, 31);
    
    // Register fallback parameter if needed, or simply stub the exact call
    registerFallbackValue(start);
    
    when(() => mockExpenseRepository.getExpensesByDateRange(any(), any()))
        .thenAnswer((_) async => testExpenses);

    // Act
    final stats = await getDashboardStats(DateRangeParams(start: start, end: end));

    // Assert
    // 1. Total spent: 42000 + 25000 + 18000 = 85000
    expect(stats.totalSpent, equals(85000.0));

    // 2. Supermercado shares: 42000 + 18000 = 60000. Fuel: 25000.
    expect(stats.categoryShares['cat_supermarket'], equals(60000.0));
    expect(stats.categoryShares['cat_fuel'], equals(25000.0));

    // 3. Highest expense category: Supermercado
    expect(stats.highestExpenseCategoryId, equals('cat_supermarket'));

    // 4. Daily spend for 2026-05-12: 42000 + 18000 = 60000
    final day12 = DateTime(2026, 5, 12);
    expect(stats.dailySpend[day12], equals(60000.0));
  });
}
