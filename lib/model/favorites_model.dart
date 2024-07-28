import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class FavoriteData extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String ingredients;

  @HiveField(4)
  String instructions;

  FavoriteData({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
  });

  @override
  String toString() {
    return 'FavoriteData{id: $id, name: $name, description: $description, ingredients: $ingredients, instructions: $instructions}';
  }
}
