import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/color_helper.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/export_helper.dart';
import '../../../../core/widgets/custom_date_range_picker.dart';
import '../bloc/expenses_bloc.dart';
import '../../domain/entities/expense.dart';

class ExpensesListPage extends StatefulWidget {
  const ExpensesListPage({super.key});

  @override
  State<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  late ExpensesBloc _expensesBloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _expensesBloc = getIt<ExpensesBloc>();
    _loadExpenses();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadExpenses() {
    if (_startDate != null && _endDate != null) {
      _expensesBloc.add(LoadExpensesByDateRange(start: _startDate!, end: _endDate!));
    } else {
      _expensesBloc.add(LoadExpenses());
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadExpenses();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadExpenses();
  }

  Future<void> _exportFilteredExpenses(List<Expense> allExpenses) async {
    final filtered = allExpenses.where((expense) {
      if (_searchQuery.isEmpty) return true;
      return (expense.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          expense.categoryName.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay gastos que coincidan con los filtros activos.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String periodTitle;
      if (_startDate != null && _endDate != null) {
        periodTitle = 'Filtro: ${DateFormat('dd-MM-yyyy').format(_startDate!)} - ${DateFormat('dd-MM-yyyy').format(_endDate!)}';
      } else {
        periodTitle = 'Historial Completo';
      }

      if (_searchQuery.isNotEmpty) {
        periodTitle += ' (Búsqueda: $_searchQuery)';
      }

      await ExportHelper.exportExpensesToExcel(
        expenses: filtered,
        periodTitle: periodTitle,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Pop loading
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

    return BlocProvider<ExpensesBloc>(
      create: (_) => _expensesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Gastos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            BlocBuilder<ExpensesBloc, ExpensesState>(
              bloc: _expensesBloc,
              builder: (context, state) {
                if (state is ExpensesLoaded && state.expenses.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Exportar a Excel',
                    onPressed: () => _exportFilteredExpenses(state.expenses),
                  );
                }
                return const SizedBox();
              },
            ),
            IconButton(
              icon: Icon(
                _startDate != null ? Icons.date_range_rounded : Icons.date_range_outlined,
                color: _startDate != null ? theme.colorScheme.primary : null,
              ),
              onPressed: _selectDateRange,
            ),
            if (_startDate != null)
              IconButton(
                icon: const Icon(Icons.filter_alt_off_rounded),
                onPressed: _clearDateFilter,
              ),
          ],
        ),
        body: Column(
          children: [
            // Search Box and Info bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar gastos por descripción...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                  if (_startDate != null && _endDate != null) ...[
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6.0),
                          Text(
                            'Filtrando desde: ${DateFormat('dd/MM/yy').format(_startDate!)} hasta ${DateFormat('dd/MM/yy').format(_endDate!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<ExpensesBloc, ExpensesState>(
                builder: (context, state) {
                  if (state is ExpensesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ExpensesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text('Error de conexión', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(state.message, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    );
                  } else if (state is ExpensesLoaded) {
                    // Locally filter based on Search Query
                    final filtered = state.expenses.where((expense) {
                      if (_searchQuery.isEmpty) return true;
                      return (expense.description?.toLowerCase().contains(_searchQuery) ?? false) ||
                          expense.categoryName.toLowerCase().contains(_searchQuery);
                    }).toList()
                      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            const SizedBox(height: 16),
                            Text('No se encontraron gastos', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Registra nuevos gastos para visualizarlos.', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final expense = filtered[index];
                        final color = ColorHelper.fromHex(expense.categoryColorHex);

                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('¿Eliminar Gasto?'),
                                content: Text('Esta acción eliminará el gasto por ${currencyFormat.format(expense.amount)} de "${expense.categoryName}" de forma permanente.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text('Eliminar', style: TextStyle(color: theme.colorScheme.error)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            _expensesBloc.add(DeleteExpenseEvent(expense.id));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: InkWell(
                              onTap: () async {
                                await context.push('${AppRouter.expenseForm}?expenseId=${expense.id}');
                                _loadExpenses();
                              },
                              borderRadius: BorderRadius.circular(20.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        expense.categoryIconCodePoint != null
                                            ? IconData(expense.categoryIconCodePoint!, fontFamily: 'MaterialIcons')
                                            : Icons.payments_rounded,
                                        color: color,
                                        size: 24.0,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  expense.description?.isNotEmpty == true
                                                      ? expense.description!
                                                      : expense.categoryName,
                                                  textAlign: TextAlign.left,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(expense.expenseDate),
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            '-\$ ${NumberFormat('#,##0.00', 'es_AR').format(expense.amount)}',
                                            textAlign: TextAlign.right,
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: theme.colorScheme.error,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
