import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<Category>> getCategories() async {
    try {
      final models = await localDataSource.getCategories();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw DatabaseFailure('Error al obtener las categorías: $e');
    }
  }

  @override
  Future<void> saveCategory(Category category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      await localDataSource.saveCategory(model);
    } catch (e) {
      throw DatabaseFailure('Error al guardar la categoría: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await localDataSource.deleteCategory(id);
    } catch (e) {
      throw DatabaseFailure('Error al eliminar la categoría: $e');
    }
  }
}
