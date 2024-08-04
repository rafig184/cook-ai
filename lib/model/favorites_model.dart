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

  @HiveField(5)
  String timetomake;

  @HiveField(5)
  String calories;

  @HiveField(6)
  String image;

  FavoriteData({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.timetomake,
    required this.calories,
    required this.image,
  });

  @override
  String toString() {
    return 'FavoriteData{id: $id, name: $name, description: $description, ingredients: $ingredients, instructions: $instructions, timetomake: $timetomake, calories: $calories, image: $image}';
  }
}
