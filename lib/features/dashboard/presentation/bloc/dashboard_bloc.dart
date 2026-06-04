import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_dashboard_stats.dart';
import '../../../expenses/domain/usecases/get_expenses_by_date_range.dart';

// --- EVENTS ---
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final DateTime? start;
  final DateTime? end;

  const LoadDashboardData({this.start, this.end});

  @override
  List<Object?> get props => [start, end];
}

// --- STATES ---
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final DateTime start;
  final DateTime end;

  const DashboardLoaded({
    required this.stats,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [stats, start, end];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStats getDashboardStats;

  DashboardBloc({
    required this.getDashboardStats,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final now = DateTime.now();
      // Default range is the current calendar month
      final start = event.start ?? DateTime(now.year, now.month, 1);
      final end = event.end ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final stats = await getDashboardStats(
        DateRangeParams(start: start, end: end),
      );

      emit(DashboardLoaded(
        stats: stats,
        start: start,
        end: end,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
