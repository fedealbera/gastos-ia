import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/color_helper.dart';
import '../../../../core/widgets/custom_date_range_picker.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../../../core/database/hive_database.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardBloc _dashboardBloc;
  late DateTime _selectedMonth;
  late String _userName;
  bool _isCustomRange = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = getIt<DashboardBloc>();
    _selectedMonth = DateTime.now();
    _userName = HiveDatabase.settingsBox.get('userName', defaultValue: 'Federico') as String;
    _loadData();
  }

  void _loadData() {
    if (_isCustomRange && _customStartDate != null && _customEndDate != null) {
      final start = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
      final end = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
      _dashboardBloc.add(LoadDashboardData(start: start, end: end));
    } else {
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      _dashboardBloc.add(LoadDashboardData(start: start, end: end));
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

    return BlocProvider<DashboardBloc>(
      create: (_) => _dashboardBloc,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoading) {
                      return const SizedBox(
                        height: 500,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is DashboardError) {
                      return SizedBox(
                        height: 500,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              Text('Ocurrió un error', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(state.message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (state is DashboardLoaded) {
                      final stats = state.stats;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Branding
                          _buildBranding(theme),
                          const SizedBox(height: 16.0),

                          // Date Picker Section (Monthly or Custom range)
                          _buildDatePickerSection(theme, isDark),
                          const SizedBox(height: 24.0),

                          // Total spent card
                          _buildTotalSpentCard(theme, isDark, stats.totalSpent, currencyFormat),
                          const SizedBox(height: 24.0),

                          // Quick Action Buttons
                          _buildQuickActions(theme, isDark),
                          const SizedBox(height: 28.0),

                          // Dashboard charts & analytics
                          if (stats.totalSpent > 0) ...[
                            Text('Distribución de Gastos', style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 16.0),
                            _buildPieChartSection(theme, isDark, stats, currencyFormat),
                            const SizedBox(height: 28.0),

                            _buildHighlightsSection(theme, isDark, stats, currencyFormat),
                            const SizedBox(height: 28.0),
                          ] else
                            _buildEmptyState(theme, isDark),

                          // Recent transaction list
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gastos Recientes', style: theme.textTheme.headlineMedium),
                              TextButton(
                                onPressed: () async {
                                  await context.push(AppRouter.expenses);
                                  _loadData();
                                },
                                child: Text(
                                  'Ver Todo',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          _buildRecentExpensesList(theme, isDark, stats.recentExpenses, currencyFormat),
                          const SizedBox(height: 40.0),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hola $_userName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              tooltip: 'Editar nombre',
              onPressed: _showEditNameDialog,
            ),
          ],
        ),
        Text(
          'Controla tus finanzas inteligentes',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nombre'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tu Nombre',
              hintText: 'Ej. Federico, Sofía...',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final newName = controller.text.trim();
                HiveDatabase.settingsBox.put('userName', newName);
                setState(() {
                  _userName = newName;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildTabButton(
              theme: theme,
              isDark: isDark,
              title: 'Mensual',
              isSelected: !_isCustomRange,
              onTap: () {
                setState(() {
                  _isCustomRange = false;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 8.0),
            _buildTabButton(
              theme: theme,
              isDark: isDark,
              title: 'Rango de Fechas',
              isSelected: _isCustomRange,
              onTap: () {
                setState(() {
                  _isCustomRange = true;
                });
                if (_customStartDate == null || _customEndDate == null) {
                  _selectCustomDateRange();
                } else {
                  _loadData();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        _isCustomRange
            ? _buildCustomRangePicker(theme, isDark)
            : _buildMonthPicker(theme, isDark),
      ],
    );
  }

  Widget _buildTabButton({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangePicker(ThemeData theme, bool isDark) {
    final hasRange = _customStartDate != null && _customEndDate != null;
    final rangeText = hasRange
        ? '${DateFormat('dd/MM/yyyy').format(_customStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate!)}'
        : 'Seleccionar rango de fechas...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectCustomDateRange,
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: hasRange ? theme.colorScheme.primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        rangeText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasRange ? null : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasRange)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              onPressed: () {
                setState(() {
                  _customStartDate = null;
                  _customEndDate = null;
                });
                _loadData();
              },
              tooltip: 'Limpiar filtro',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadData();
    }
  }

  Widget _buildMonthPicker(ThemeData theme, bool isDark) {
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth);
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: () => _changeMonth(-1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            formattedMonth,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            onPressed: () => _changeMonth(1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpentCard(ThemeData theme, bool isDark, double totalSpent, NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F766E), const Color(0xFF0D9488)]
              : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 24.0,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Total Gastado este Mes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '\$ ${NumberFormat('#,##0.00', 'es_AR').format(totalSpent)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 42.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.white.withValues(alpha: 0.8), size: 18),
              const SizedBox(width: 6.0),
              Text(
                'Presupuesto saludable en curso',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.0,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              await context.push(AppRouter.expenseForm);
              _loadData();
            },
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, color: theme.colorScheme.primary, size: 28),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Nuevo Gasto',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: InkWell(
            onTap: () async {
              await context.push(AppRouter.categories);
              _loadData();
            },
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.grid_view_rounded, color: theme.colorScheme.secondary, size: 28),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Categorías',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: InkWell(
            onTap: () async {
              await context.push(AppRouter.expenses);
              _loadData();
            },
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF8B5CF6), size: 28),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Historial',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection(
      ThemeData theme, bool isDark, DashboardStats stats, NumberFormat format) {
    final shares = stats.categoryShares;
    
    // Sort shares descending to display nicely
    final sortedEntries = shares.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> getSections() {
      return sortedEntries.map((entry) {
        final catId = entry.key;
        final amount = entry.value;
        final percentage = (amount / stats.totalSpent) * 100;
        final color = ColorHelper.fromHex(stats.categoryColors[catId] ?? '#000000');

        return PieChartSectionData(
          color: color,
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: getSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent &&
                        pieTouchResponse != null &&
                        pieTouchResponse.touchedSection != null) {
                      final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (index >= 0 && index < sortedEntries.length) {
                        final catId = sortedEntries[index].key;
                        _navigateToCategoryExpenses(catId, stats);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Custom beautiful legends grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4.0),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final catId = entry.key;
              final amount = entry.value;
              final color = ColorHelper.fromHex(stats.categoryColors[catId] ?? '#000000');
              final name = stats.categoryNames[catId] ?? 'Otro';

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToCategoryExpenses(catId, stats),
                  borderRadius: BorderRadius.circular(12.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '\$ ${NumberFormat('#,##0.00', 'es_AR').format(amount)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void _navigateToCategoryExpenses(String categoryId, DashboardStats stats) async {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    final name = stats.categoryNames[categoryId] ?? 'Otro';
    final colorHex = stats.categoryColors[categoryId] ?? '#000000';
    final iconCode = stats.categoryIcons[categoryId];

    final uri = Uri(
      path: AppRouter.categoryExpenses,
      queryParameters: {
        'categoryId': categoryId,
        'categoryName': name,
        'categoryColorHex': colorHex,
        if (iconCode != null) 'categoryIconCodePoint': iconCode.toString(),
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      },
    );

    await context.push(uri.toString());
    _loadData();
  }

  Widget _buildHighlightsSection(
      ThemeData theme, bool isDark, DashboardStats stats, NumberFormat format) {
    if (stats.highestExpenseCategoryId == null) return const SizedBox();

    final catId = stats.highestExpenseCategoryId!;
    final name = stats.categoryNames[catId] ?? 'Otro';
    final amount = stats.categoryShares[catId] ?? 0.0;
    final pct = (amount / stats.totalSpent) * 100;
    final color = ColorHelper.fromHex(stats.categoryColors[catId] ?? '#000000');
    final iconCode = stats.categoryIcons[catId];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : Icons.category_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mayor Gasto Mensual',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '(${pct.toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  '\$ ${NumberFormat('#,##0.00', 'es_AR').format(amount)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        children: [
          Icon(Icons.wallet_rounded, size: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            'Sin Gastos Registrados',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '¡Registra tu primer gasto para ver las estadísticas!',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpensesList(
      ThemeData theme, bool isDark, List<Expense> expenses, NumberFormat format) {
    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text('No hay gastos recientes', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          final color = ColorHelper.fromHex(expense.categoryColorHex);
          
          return InkWell(
            onTap: () async {
              await context.push('${AppRouter.expenseForm}?expenseId=${expense.id}');
              _loadData();
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
                          : Icons.monetization_on_rounded,
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
                                expense.description?.isNotEmpty == true ? expense.description! : expense.categoryName,
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
          );
        },
      ),
    );
  }
}
