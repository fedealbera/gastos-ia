import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/color_helper.dart';
import '../bloc/categories_bloc.dart';
import '../../domain/entities/category.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late CategoriesBloc _categoriesBloc;

  @override
  void initState() {
    super.initState();
    _categoriesBloc = getIt<CategoriesBloc>();
    _categoriesBloc.add(LoadCategories());
  }

  void _showCategoryForm([Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider<CategoriesBloc>.value(
        value: _categoriesBloc,
        child: CategoryFormSheet(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<CategoriesBloc>(
      create: (_) => _categoriesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestionar Categorías'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoriesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text('Error al cargar categorías', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(state.message, style: theme.textTheme.bodyMedium),
                  ],
                ),
              );
            } else if (state is CategoriesLoaded) {
              final list = state.categories;
              
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      Text('No hay categorías creadas', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Crea una para poder organizar tus gastos.', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20.0),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14.0),
                itemBuilder: (context, index) {
                  final cat = list[index];
                  final color = ColorHelper.fromHex(cat.colorHex);
                  
                  return Dismissible(
                    key: Key(cat.id),
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
                      // Prevent deleting default categories if needed, or simply confirm
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('¿Eliminar Categoría?'),
                          content: Text('Esto eliminará permanentemente la categoría "${cat.name}". Los gastos asociados a ella seguirán existiendo con la información histórica.'),
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
                      _categoriesBloc.add(DeleteCategoryEvent(cat.id));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        leading: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat.iconCodePoint != null
                                ? IconData(cat.iconCodePoint!, fontFamily: 'MaterialIcons')
                                : Icons.category_rounded,
                            color: color,
                            size: 24.0,
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              onPressed: () => _showCategoryForm(cat),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('¿Eliminar Categoría?'),
                                    content: Text('Esto eliminará permanentemente la categoría "${cat.name}". Los gastos asociados a ella seguirán existiendo con la información histórica.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(color: theme.colorScheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  _categoriesBloc.add(DeleteCategoryEvent(cat.id));
                                }
                              },
                            ),
                          ],
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCategoryForm(),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// Modal bottom sheet form for adding/editing categories
class CategoryFormSheet extends StatefulWidget {
  final Category? category;

  const CategoryFormSheet({super.key, this.category});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedColorHex;
  int? _selectedIconCode;

  // Selected Harmonized color palette
  final List<String> _colors = [
    '#3B82F6', // Sky Blue
    '#10B981', // Emerald Green
    '#EF4444', // Coral Red
    '#F59E0B', // Amber Gold
    '#8B5CF6', // Purple Royal
    '#EC4899', // Hot Pink
    '#06B6D4', // Deep Teal
    '#F97316', // Bright Orange
  ];

  // Selected custom icons list
  final List<int> _icons = [
    0xe57c, // shopping_cart
    0xe30c, // local_gas_station
    0xe574, // restaurant
    0xe530, // directions_bus
    0xe0b0, // electrical_services
    0xe406, // movie
    0xe244, // fitness_center
    0xeb3f, // school
    0xe333, // home
    0xe556, // local_hospital
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _selectedColorHex = cat?.colorHex ?? _colors[0];
    _selectedIconCode = cat?.iconCodePoint ?? _icons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() == true) {
      final newCategory = Category(
        id: widget.category?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        colorHex: _selectedColorHex,
        iconCodePoint: _selectedIconCode,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
      );

      context.read<CategoriesBloc>().add(SaveCategoryEvent(newCategory));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      padding: EdgeInsets.only(
        top: 24.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar indicator
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.category != null ? 'Editar Categoría' : 'Nueva Categoría',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // Category Name Input
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Categoría',
                  hintText: 'Ej. Gimnasio, Mascotas...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Por favor ingrese un nombre';
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // Color Swatch Selection Grid
              Text('Seleccionar Color', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _colors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, idx) {
                  final hex = _colors[idx];
                  final col = ColorHelper.fromHex(hex);
                  final isSelected = hex == _selectedColorHex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorHex = hex;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: ColorHelper.getContrastColor(col),
                              size: 16,
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24.0),

              // Icon Picker Grid
              Text('Seleccionar Ícono', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                  itemBuilder: (context, idx) {
                    final iconCode = _icons[idx];
                    final isSelected = iconCode == _selectedIconCode;
                    final activeColor = ColorHelper.fromHex(_selectedColorHex);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIconCode = iconCode;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.15)
                              : isDark
                                  ? const Color(0xFF334155).withValues(alpha: 0.3)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16.0),
                          border: isSelected ? Border.all(color: activeColor, width: 2) : null,
                        ),
                        child: Icon(
                          IconData(iconCode, fontFamily: 'MaterialIcons'),
                          color: isSelected ? activeColor : theme.iconTheme.color,
                          size: 24.0,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32.0),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    widget.category != null ? 'Guardar Cambios' : 'Crear Categoría',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
