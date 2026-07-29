import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/errors/failures.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  final SyncService syncService;

  ExpenseRepositoryImpl(this.localDataSource, this.syncService);

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final models = await localDataSource.getExpenses();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw DatabaseFailure('Error al obtener los gastos: $e');
    }
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await localDataSource.saveExpense(model);
      
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await syncService.uploadExpense(currentUser.uid, model);
      }
    } catch (e) {
      throw DatabaseFailure('Error al guardar el gasto: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await localDataSource.deleteExpense(id);
      
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await syncService.deleteExpense(currentUser.uid, id);
      }
    } catch (e) {
      throw DatabaseFailure('Error al eliminar el gasto: $e');
    }
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      final list = await getExpenses();
      // Normalize dates to match start and end precisely (ignoring hours/minutes or using complete ranges)
      final normalizedStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
      final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
      
      return list.where((expense) {
        return expense.expenseDate.isAfter(normalizedStart.subtract(const Duration(seconds: 1))) &&
               expense.expenseDate.isBefore(normalizedEnd.add(const Duration(seconds: 1)));
      }).toList();
    } catch (e) {
      throw DatabaseFailure('Error al filtrar gastos por fecha: $e');
    }
  }
}
