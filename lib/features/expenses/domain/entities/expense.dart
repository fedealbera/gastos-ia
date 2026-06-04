import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryColorHex;
  final int? categoryIconCodePoint;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColorHex,
    this.categoryIconCodePoint,
    required this.amount,
    this.description,
    required this.expenseDate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        categoryName,
        categoryColorHex,
        categoryIconCodePoint,
        amount,
        description,
        expenseDate,
        createdAt,
      ];

  Expense copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? categoryColorHex,
    int? categoryIconCodePoint,
    double? amount,
    String? description,
    DateTime? expenseDate,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      categoryIconCodePoint: categoryIconCodePoint ?? this.categoryIconCodePoint,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
