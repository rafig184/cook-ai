import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class StatsData extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int calories; // Change from String to int

  @HiveField(3)
  int fat; // Change from String to int

  @HiveField(4)
  int protein; // Change from String to int

  @HiveField(5)
  int carbs; // Change from String to int

  @HiveField(6)
  DateTime date;

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
