import 'package:nyimpeun/features/wallet/domain/entities/category_entity.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
    this.icon,
    this.color,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime? createdAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'is_default': isDefault,
      };

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        userId: userId,
        name: name,
        type: type,
        icon: icon,
        color: color,
        isDefault: isDefault,
        createdAt: createdAt,
      );
}
