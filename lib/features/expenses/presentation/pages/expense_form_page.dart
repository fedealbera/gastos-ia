import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/color_helper.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_categories.dart';
import '../bloc/expenses_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../../../core/usecases/usecase.dart';

class ExpenseFormPage extends StatefulWidget {
  final String? expenseId;

  const ExpenseFormPage({super.key, this.expenseId});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late ExpensesBloc _expensesBloc;
  
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _expensesBloc = getIt<ExpensesBloc>();
    _loadCategoriesAndExpense();
  }

  Future<void> _loadCategoriesAndExpense() async {
    try {
      final getCats = getIt<GetCategories>();
      final list = await getCats(const NoParams());
      
      Category? matchingCategory;
      if (widget.expenseId != null) {
        final getExpenses = getIt<GetExpenses>();
        final expensesList = await getExpenses(const NoParams());
        final expense = expensesList.firstWhere((e) => e.id == widget.expenseId);
        
        _amountController.text = expense.amount % 1 == 0 
            ? expense.amount.toStringAsFixed(0) 
            : expense.amount.toString();
        _descriptionController.text = expense.description ?? '';
        _selectedDate = expense.expenseDate;
        _createdAt = expense.createdAt;
        
        final index = list.indexWhere((c) => c.id == expense.categoryId);
        matchingCategory = index != -1 ? list[index] : (list.isNotEmpty ? list[0] : null);
      }

      setState(() {
        _categories = list;
        _isLoadingCategories = false;
        if (matchingCategory != null) {
          _selectedCategory = matchingCategory;
        } else if (list.isNotEmpty) {
          _selectedCategory = list[0];
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _selectedCategory != null
                      ? ColorHelper.fromHex(_selectedCategory!.colorHex)
                      : Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() == true) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una categoría')),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa un monto válido mayor a 0')),
        );
        return;
      }

      final expense = Expense(
        id: widget.expenseId ?? const Uuid().v4(),
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryColorHex: _selectedCategory!.colorHex,
        categoryIconCodePoint: _selectedCategory!.iconCodePoint,
        amount: amount,
        description: _descriptionController.text.trim(),
        expenseDate: _selectedDate,
        createdAt: _createdAt ?? DateTime.now(),
      );

      _expensesBloc.add(SaveExpenseEvent(expense));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Dynamic Accent Color matching the selected category!
    final accentColor = _selectedCategory != null
        ? ColorHelper.fromHex(_selectedCategory!.colorHex)
        : theme.colorScheme.primary;

    return BlocProvider<ExpensesBloc>(
      create: (_) => _expensesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expenseId != null ? 'Editar Gasto' : 'Registrar Gasto'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.expenseId != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Eliminar Gasto?'),
                      content: const Text('¿Estás seguro de que deseas eliminar este gasto de forma permanente?'),
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
                  if (confirm == true && context.mounted) {
                    _expensesBloc.add(DeleteExpenseEvent(widget.expenseId!));
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
        body: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Amount Input Field (Glow Accent Color)
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(28.0),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monto del Gasto',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontSize: 36.0,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: theme.textTheme.headlineLarge?.copyWith(
                                      fontSize: 42.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.0,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Requerido';
                                      if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Monto inválido';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      // Category Selector Chips
                      Text('Seleccionar Categoría', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12.0),
                      if (_categories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Center(
                            child: Text(
                              'Por favor crea categorías primero',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10.0),
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory?.id == cat.id;
                              final catCol = ColorHelper.fromHex(cat.colorHex);

                              return ChoiceChip(
                                label: Row(
                                  children: [
                                    if (cat.iconCodePoint != null) ...[
                                      Icon(
                                        IconData(cat.iconCodePoint!, fontFamily: 'MaterialIcons'),
                                        size: 16.0,
                                        color: isSelected ? Colors.white : catCol,
                                      ),
                                      const SizedBox(width: 6.0),
                                    ],
                                    Text(cat.name),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  }
                                },
                                selectedColor: catCol,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                  side: BorderSide(
                                    color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 28.0),

                      // Description Input Box
                      Text('Descripción opcional', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Compra mensual de víveres...',
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      // Date selector calendar card
                      Text('Fecha del Gasto', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12.0),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: accentColor),
                              const SizedBox(width: 12.0),
                              Text(
                                DateFormat('EEEE dd, MMMM yyyy', 'es_ES').format(_selectedDate),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_calendar_rounded, size: 20.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // Submit elevated button (Glow Accent background)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: ColorHelper.getContrastColor(accentColor),
                          ),
                          child: const Text(
                            'Guardar Gasto',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
