import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class StatsData extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String calories;

  @HiveField(3)
  String fat;

  @HiveField(4)
  String protein;

  @HiveField(5)
  String carbs;

  @HiveField(5)
  String date;

  StatsData({
    required this.id,
    required this.title,
    required this.calories,
    required this.fat,
    required this.protein,
    required this.carbs,
    required this.date,
  });

  @override
  String toString() {
    return 'StatsData{id: $id, title: $title, calories: $calories, fat: $fat, protein: $protein, carbs: $carbs, date: $date}';
  }
}
