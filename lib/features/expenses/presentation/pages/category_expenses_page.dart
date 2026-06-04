import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/color_helper.dart';
import '../../domain/entities/expense.dart';
import '../bloc/expenses_bloc.dart';

class CategoryExpensesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String categoryColorHex;
  final int? categoryIconCodePoint;
  final DateTime startDate;
  final DateTime endDate;

  const CategoryExpensesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColorHex,
    this.categoryIconCodePoint,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CategoryExpensesPage> createState() => _CategoryExpensesPageState();
}

class _CategoryExpensesPageState extends State<CategoryExpensesPage> {
  late ExpensesBloc _expensesBloc;

  @override
  void initState() {
    super.initState();
    _expensesBloc = getIt<ExpensesBloc>();
    _loadExpenses();
  }

  void _loadExpenses() {
    _expensesBloc.add(LoadExpensesByDateRange(
      start: widget.startDate,
      end: widget.endDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    final categoryColor = ColorHelper.fromHex(widget.categoryColorHex);

    return BlocProvider<ExpensesBloc>(
      create: (_) => _expensesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<ExpensesBloc, ExpensesState>(
          builder: (context, state) {
            if (state is ExpensesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ExpensesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text('Ocurrió un error',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(state.message, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadExpenses,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            } else if (state is ExpensesLoaded) {
              // Filter expenses by categoryId
              final categoryExpenses = state.expenses
                  .where((e) => e.categoryId == widget.categoryId)
                  .toList()
                ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

              final totalAmount = categoryExpenses.fold<double>(
                  0.0, (sum, e) => sum + e.amount);

              return Column(
                children: [
                  // Summary Header Card
                  _buildSummaryCard(
                    theme,
                    isDark,
                    categoryColor,
                    totalAmount,
                    categoryExpenses.length,
                    currencyFormat,
                  ),

                  // Expense List
                  Expanded(
                    child: categoryExpenses.isEmpty
                        ? _buildEmptyState(theme, isDark)
                        : _buildExpensesList(
                            theme,
                            isDark,
                            categoryExpenses,
                            currencyFormat,
                            categoryColor,
                          ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    bool isDark,
    Color categoryColor,
    double totalAmount,
    int count,
    NumberFormat format,
  ) {
    final monthName =
        DateFormat('MMMM yyyy', 'es_ES').format(widget.startDate);
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Container(
      margin: const EdgeInsets.all(20.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor,
            HSLColor.fromColor(categoryColor)
                .withLightness(
                    (HSLColor.fromColor(categoryColor).lightness + 0.15)
                        .clamp(0.0, 1.0))
                .toColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.3),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.categoryIconCodePoint != null
                  ? IconData(widget.categoryIconCodePoint!,
                      fontFamily: 'MaterialIcons')
                  : Icons.category_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16.0),

          // Category name
          Text(
            widget.categoryName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4.0),

          // Month label
          Text(
            formattedMonth,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16.0),

          // Total amount
          Text(
            '\$ ${NumberFormat('#,##0.00', 'es_AR').format(totalAmount)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 38.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12.0),

          // Transaction count chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              '$count ${count == 1 ? 'transacción' : 'transacciones'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64,
              color:
                  isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text('Sin gastos en esta categoría',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('No se registraron gastos durante este mes.',
              style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildExpensesList(
    ThemeData theme,
    bool isDark,
    List<Expense> expenses,
    NumberFormat format,
    Color categoryColor,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final expense = expenses[index];

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
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('¿Eliminar Gasto?'),
                content: Text(
                    'Esta acción eliminará el gasto por ${format.format(expense.amount)} de forma permanente.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Eliminar',
                        style: TextStyle(color: theme.colorScheme.error)),
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
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: InkWell(
              onTap: () async {
                await context.push(
                    '${AppRouter.expenseForm}?expenseId=${expense.id}');
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
                        color: categoryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.categoryIconCodePoint != null
                            ? IconData(widget.categoryIconCodePoint!,
                                fontFamily: 'MaterialIcons')
                            : Icons.payments_rounded,
                        color: categoryColor,
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
                                      : widget.categoryName,
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
}
