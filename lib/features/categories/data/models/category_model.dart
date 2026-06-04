import 'package:hive/hive.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.colorHex,
    super.iconCodePoint,
    required super.createdAt,
  });

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      colorHex: entity.colorHex,
      iconCodePoint: entity.iconCodePoint,
      createdAt: entity.createdAt,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      colorHex: colorHex,
      iconCodePoint: iconCodePoint,
      createdAt: createdAt,
    );
  }
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 0;

  @override
  CategoryModel read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final Map<int, dynamic> fields = {};
    for (var i = 0; i < fieldsCount; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorHex: fields[2] as String,
      iconCodePoint: fields[3] as int?,
      createdAt: DateTime.parse(fields[4] as String),
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer.writeByte(5); // 5 fields
    
    writer.writeByte(0);
    writer.write(obj.id);
    
    writer.writeByte(1);
    writer.write(obj.name);
    
    writer.writeByte(2);
    writer.write(obj.colorHex);
    
    writer.writeByte(3);
    writer.write(obj.iconCodePoint);
    
    writer.writeByte(4);
    writer.write(obj.createdAt.toIso8601String());
  }
}
