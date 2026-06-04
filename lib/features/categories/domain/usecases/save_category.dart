import '../../../../core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class SaveCategory implements UseCase<void, Category> {
  final CategoryRepository repository;

  SaveCategory(this.repository);

  @override
  Future<void> call(Category category) {
    return repository.saveCategory(category);
  }
}
