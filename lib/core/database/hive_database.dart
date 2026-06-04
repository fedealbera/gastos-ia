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
  }

  static Future<void> _seedDefaultCategories() async {
    if (_categoryBox!.isEmpty) {
      final defaultCategories = [
        CategoryModel(
          id: 'cat_supermarket',
          name: 'Supermercado',
          colorHex: '#3B82F6', // Blue 500
          iconCodePoint: 0xe57c, // shopping_cart
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_fuel',
          name: 'Combustible',
          colorHex: '#EF4444', // Red 500
          iconCodePoint: 0xe30c, // local_gas_station
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_outings',
          name: 'Salidas',
          colorHex: '#F59E0B', // Amber 500
          iconCodePoint: 0xe574, // restaurant
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_transport',
          name: 'Transporte',
          colorHex: '#10B981', // Emerald 500
          iconCodePoint: 0xe530, // directions_bus
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'cat_services',
          name: 'Servicios',
          colorHex: '#8B5CF6', // Purple 500
          iconCodePoint: 0xe0b0, // electrical_services
          createdAt: DateTime.now(),
        ),
      ];

      for (final cat in defaultCategories) {
        await _categoryBox!.put(cat.id, cat);
      }
    }
  }
}
