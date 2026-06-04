import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/get_expenses_by_date_range.dart';
import '../../domain/usecases/save_expense.dart';
import '../../../../core/usecases/usecase.dart';

// --- EVENTS ---
abstract class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpensesEvent {}

class LoadExpensesByDateRange extends ExpensesEvent {
  final DateTime start;
  final DateTime end;
  
  const LoadExpensesByDateRange({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class SaveExpenseEvent extends ExpensesEvent {
  final Expense expense;
  const SaveExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends ExpensesEvent {
  final String id;
  const DeleteExpenseEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// --- STATES ---
abstract class ExpensesState extends Equatable {
  const ExpensesState();

  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpensesState {}

class ExpensesLoading extends ExpensesState {}

class ExpensesLoaded extends ExpensesState {
  final List<Expense> expenses;
  final DateTime? filterStart;
  final DateTime? filterEnd;

  const ExpensesLoaded({
    required this.expenses,
    this.filterStart,
    this.filterEnd,
  });

  @override
  List<Object?> get props => [expenses, filterStart, filterEnd];
}

class ExpensesError extends ExpensesState {
  final String message;
  const ExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final GetExpenses getExpenses;
  final SaveExpense saveExpense;
  final DeleteExpense deleteExpense;
  final GetExpensesByDateRange getExpensesByDateRange;

  ExpensesBloc({
    required this.getExpenses,
    required this.saveExpense,
    required this.deleteExpense,
    required this.getExpensesByDateRange,
  }) : super(ExpensesInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadExpensesByDateRange>(_onLoadExpensesByDateRange);
    on<SaveExpenseEvent>(_onSaveExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(ExpensesLoading());
    try {
      final list = await getExpenses(const NoParams());
      emit(ExpensesLoaded(expenses: list));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> _onLoadExpensesByDateRange(
    LoadExpensesByDateRange event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(ExpensesLoading());
    try {
      final list = await getExpensesByDateRange(
        DateRangeParams(start: event.start, end: event.end),
      );
      emit(ExpensesLoaded(
        expenses: list,
        filterStart: event.start,
        filterEnd: event.end,
      ));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> _onSaveExpense(
    SaveExpenseEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    final currentFilterStart = state is ExpensesLoaded ? (state as ExpensesLoaded).filterStart : null;
    final currentFilterEnd = state is ExpensesLoaded ? (state as ExpensesLoaded).filterEnd : null;
    
    emit(ExpensesLoading());
    try {
      await saveExpense(event.expense);
      
      // Reload based on previous filters
      List<Expense> list;
      if (currentFilterStart != null && currentFilterEnd != null) {
        list = await getExpensesByDateRange(
          DateRangeParams(start: currentFilterStart, end: currentFilterEnd),
        );
      } else {
        list = await getExpenses(const NoParams());
      }
      
      emit(ExpensesLoaded(
        expenses: list,
        filterStart: currentFilterStart,
        filterEnd: currentFilterEnd,
      ));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    final currentFilterStart = state is ExpensesLoaded ? (state as ExpensesLoaded).filterStart : null;
    final currentFilterEnd = state is ExpensesLoaded ? (state as ExpensesLoaded).filterEnd : null;

    emit(ExpensesLoading());
    try {
      await deleteExpense(event.id);

      // Reload based on previous filters
      List<Expense> list;
      if (currentFilterStart != null && currentFilterEnd != null) {
        list = await getExpensesByDateRange(
          DateRangeParams(start: currentFilterStart, end: currentFilterEnd),
        );
      } else {
        list = await getExpenses(const NoParams());
      }

      emit(ExpensesLoaded(
        expenses: list,
        filterStart: currentFilterStart,
        filterEnd: currentFilterEnd,
      ));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }
}
