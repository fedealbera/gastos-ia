import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.categoryColorHex,
    super.categoryIconCodePoint,
    required super.amount,
    super.description,
    required super.expenseDate,
    required super.createdAt,
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      categoryColorHex: entity.categoryColorHex,
      categoryIconCodePoint: entity.categoryIconCodePoint,
      amount: entity.amount,
      description: entity.description,
      expenseDate: entity.expenseDate,
      createdAt: entity.createdAt,
    );
  }

  Expense toEntity() {
    return Expense(
      id: id,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColorHex: categoryColorHex,
      categoryIconCodePoint: categoryIconCodePoint,
      amount: amount,
      description: description,
      expenseDate: expenseDate,
      createdAt: createdAt,
    );
  }
}

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 1;

  @override
  ExpenseModel read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final Map<int, dynamic> fields = {};
    for (var i = 0; i < fieldsCount; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return ExpenseModel(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      categoryName: fields[2] as String,
      categoryColorHex: fields[3] as String,
      categoryIconCodePoint: fields[4] as int?,
      amount: fields[5] as double,
      description: fields[6] as String?,
      expenseDate: DateTime.parse(fields[7] as String),
      createdAt: DateTime.parse(fields[8] as String),
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer.writeByte(9); // 9 fields
    
    writer.writeByte(0);
    writer.write(obj.id);
    
    writer.writeByte(1);
    writer.write(obj.categoryId);
    
    writer.writeByte(2);
    writer.write(obj.categoryName);
    
    writer.writeByte(3);
    writer.write(obj.categoryColorHex);
    
    writer.writeByte(4);
    writer.write(obj.categoryIconCodePoint);
    
    writer.writeByte(5);
    writer.write(obj.amount);
    
    writer.writeByte(6);
    writer.write(obj.description);
    
    writer.writeByte(7);
    writer.write(obj.expenseDate.toIso8601String());
    
    writer.writeByte(8);
    writer.write(obj.createdAt.toIso8601String());
  }
}
