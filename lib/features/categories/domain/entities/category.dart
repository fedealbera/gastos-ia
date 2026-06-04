import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String colorHex;
  final int? iconCodePoint;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.colorHex,
    this.iconCodePoint,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, colorHex, iconCodePoint, createdAt];

  Category copyWith({
    String? id,
    String? name,
    String? colorHex,
    int? iconCodePoint,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
