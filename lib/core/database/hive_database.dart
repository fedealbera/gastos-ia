import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/categories/data/models/category_model.dart';
import '../../features/expenses/data/models/expense_model.dart';

class HiveDatabase {
  HiveDatabase._();

  static Box<CategoryModel>? _categoryBox;
  static Box<ExpenseModel>? _expenseBox;
  static Box<dynamic>? _settingsBox;

  static Box<CategoryModel> get categoryBox {
    assert(_categoryBox != null, 'HiveDatabase has not been initialized. Call init() first.');
    return _categoryBox!;
  }

  static Box<ExpenseModel> get expenseBox {
    assert(_expenseBox != null, 'HiveDatabase has not been initialized. Call init() first.');
    return _expenseBox!;
  }

  static Box<dynamic> get settingsBox {
    assert(_settingsBox != null, 'HiveDatabase has not been initialized. Call init() first.');
    return _settingsBox!;
  }

  static Future<void> init() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register manual type adapters
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(ExpenseModelAdapter());

    // Open boxes
    _categoryBox = await Hive.openBox<CategoryModel>('categories');
    _expenseBox = await Hive.openBox<ExpenseModel>('expenses');
    _settingsBox = await Hive.openBox('settings');

    // Seed default categories if they are empty
    await _seedDefaultCategories();
    
    // Migrate old hardcoded codepoints to correct compile-time codepoints
    await _migrateCategoryIcons();
  }

  static Future<void> _seedDefaultCategories() async {
    if (_categoryBox!.isEmpty) {
      final defaultCategories = [
        CategoryModel(
          id: 'cat_supermarket',
          name: 'Supermercado',
          colorHex: '#3B82F6', // Blue 500
          iconCodePoint: Icons.shopping_cart_rounded.codePoint,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_fuel',
          name: 'Combustible',
          colorHex: '#EF4444', // Red 500
          iconCodePoint: Icons.local_gas_station_rounded.codePoint,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_outings',
          name: 'Salidas',
          colorHex: '#F59E0B', // Amber 500
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_transport',
          name: 'Transporte',
          colorHex: '#10B981', // Emerald 500
          iconCodePoint: Icons.directions_bus_rounded.codePoint,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_services',
          name: 'Servicios',
          colorHex: '#8B5CF6', // Purple 500
          iconCodePoint: Icons.electrical_services_rounded.codePoint,
          createdAt: DateTime.now(),
        ),
      ];

      for (final cat in defaultCategories) {
        await _categoryBox!.put(cat.id, cat);
      }
    }
  }

  static Future<void> _migrateCategoryIcons() async {
    // Maps old wrong/deprecated hex code points to current SDK code points
    final oldToNew = {
      0xe57c: Icons.shopping_cart_rounded.codePoint,
      0xe30c: Icons.local_gas_station_rounded.codePoint,
      0xe574: Icons.restaurant_rounded.codePoint,
      0xe530: Icons.directions_bus_rounded.codePoint,
      0xe0b0: Icons.electrical_services_rounded.codePoint,
    };

    // Migrate categories
    for (final key in _categoryBox!.keys) {
      final cat = _categoryBox!.get(key);
      if (cat != null && oldToNew.containsKey(cat.iconCodePoint)) {
        final newCode = oldToNew[cat.iconCodePoint]!;
        await _categoryBox!.put(
          key,
          CategoryModel(
            id: cat.id,
            name: cat.name,
            colorHex: cat.colorHex,
            iconCodePoint: newCode,
            createdAt: cat.createdAt,
          ),
        );
      }
    }

    // Migrate cached category icons in expenses
    for (final key in _expenseBox!.keys) {
      final exp = _expenseBox!.get(key);
      if (exp != null && oldToNew.containsKey(exp.categoryIconCodePoint)) {
        final newCode = oldToNew[exp.categoryIconCodePoint]!;
        await _expenseBox!.put(
          key,
          ExpenseModel(
            id: exp.id,
            categoryId: exp.categoryId,
            categoryName: exp.categoryName,
            categoryColorHex: exp.categoryColorHex,
            categoryIconCodePoint: newCode,
            amount: exp.amount,
            description: exp.description,
            expenseDate: exp.expenseDate,
            createdAt: exp.createdAt,
          ),
        );
      }
    }
  }
}
