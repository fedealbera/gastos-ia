import 'package:hive/hive.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> saveCategory(CategoryModel model);
  Future<void> deleteCategory(String id);
}

class HiveCategoryLocalDataSource implements CategoryLocalDataSource {
  final Box<CategoryModel> categoryBox;

  HiveCategoryLocalDataSource(this.categoryBox);

  @override
  Future<List<CategoryModel>> getCategories() async {
    return categoryBox.values.toList();
  }

  @override
  Future<void> saveCategory(CategoryModel model) async {
    await categoryBox.put(model.id, model);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await categoryBox.delete(id);
  }
}
