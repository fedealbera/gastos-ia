import 'package:get_it/get_it.dart';
import '../database/hive_database.dart';
import '../services/sync_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/categories/data/datasources/category_local_datasource.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/delete_category.dart';
import '../../features/categories/domain/usecases/get_categories.dart';
import '../../features/categories/domain/usecases/save_category.dart';
import '../../features/categories/presentation/bloc/categories_bloc.dart';
import '../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/domain/usecases/delete_expense.dart';
import '../../features/expenses/domain/usecases/get_expenses.dart';
import '../../features/expenses/domain/usecases/get_expenses_by_date_range.dart';
import '../../features/expenses/domain/usecases/save_expense.dart';
import '../../features/expenses/presentation/bloc/expenses_bloc.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_stats.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<SyncService>()) {
    return;
  }
  // 0. Services
  getIt.registerLazySingleton<SyncService>(() => SyncService());
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // 1. Data Sources
  getIt.registerLazySingleton<CategoryLocalDataSource>(
    () => HiveCategoryLocalDataSource(HiveDatabase.categoryBox),
  );
  getIt.registerLazySingleton<ExpenseLocalDataSource>(
    () => HiveExpenseLocalDataSource(HiveDatabase.expenseBox),
  );

  // 2. Repositories
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      getIt<CategoryLocalDataSource>(),
      getIt<SyncService>(),
    ),
  );
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      getIt<ExpenseLocalDataSource>(),
      getIt<SyncService>(),
    ),
  );

  // 3. Use Cases
  getIt.registerLazySingleton<GetCategories>(() => GetCategories(getIt<CategoryRepository>()));
  getIt.registerLazySingleton<SaveCategory>(() => SaveCategory(getIt<CategoryRepository>()));
  getIt.registerLazySingleton<DeleteCategory>(() => DeleteCategory(getIt<CategoryRepository>()));

  getIt.registerLazySingleton<GetExpenses>(() => GetExpenses(getIt<ExpenseRepository>()));
  getIt.registerLazySingleton<SaveExpense>(() => SaveExpense(getIt<ExpenseRepository>()));
  getIt.registerLazySingleton<DeleteExpense>(() => DeleteExpense(getIt<ExpenseRepository>()));
  getIt.registerLazySingleton<GetExpensesByDateRange>(() => GetExpensesByDateRange(getIt<ExpenseRepository>()));

  getIt.registerLazySingleton<GetDashboardStats>(() => GetDashboardStats(getIt<ExpenseRepository>()));

  // 4. Blocs
  getIt.registerFactory<CategoriesBloc>(() => CategoriesBloc(
        getCategories: getIt(),
        saveCategory: getIt(),
        deleteCategory: getIt(),
      ));

  getIt.registerFactory<ExpensesBloc>(() => ExpensesBloc(
        getExpenses: getIt(),
        saveExpense: getIt(),
        deleteExpense: getIt(),
        getExpensesByDateRange: getIt(),
      ));

  getIt.registerFactory<DashboardBloc>(() => DashboardBloc(
        getDashboardStats: getIt(),
      ));

  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(authRepository: getIt<AuthRepository>()));
}
