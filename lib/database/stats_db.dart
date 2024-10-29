import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/model/stats_model.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class StatsDatabase {
  List savedDishes = [];

  // final Box<FavoriteData> _myBox = Hive.box<FavoriteData>('mybox');
  // final _myBox = Hive.box('mybox');
  late final Box<StatsData> _myBox;

  Future<void> initialize() async {
    if (!Hive.isBoxOpen('mybox1')) {
      _myBox = await Hive.openBox<StatsData>('mybox1');
    } else {
      _myBox = Hive.box<StatsData>('mybox1');
    }
    loadData();
  }

  void createInitialData() {
    // Add some initial data if needed
    savedDishes = [];

    loadData();
  }

  void loadData() {
    print("Loading Data from DB");
    savedDishes = _myBox.values.toList();
  }

  void updateDatabase() {
    _myBox.putAll({for (var dish in savedDishes) dish.id: dish});
  }

  void addStats(StatsData dish) {
    savedDishes.add(dish);
    updateDatabase();
  }

  Future<void> deleteSelectedDish(StatsData dish) async {
    savedDishes.removeWhere((item) => item.id == dish.id);
    _myBox.delete(dish.id);
  }

  Future<void> deleteAllRecipes() async {
    // Assuming favoriteGifIds is a list of keys
    await _myBox.clear();
    savedDishes.clear();
  }

  Map<String, int> getCaloriesPerDayLast7Days() {
    final today = DateTime.now();
    final last7Days = today.subtract(Duration(days: 7));

    Map<String, int> dailyCalories = {};

    for (var dish in savedDishes) {
      DateTime dishDate = DateFormat("dd/MM/yyyy HH:mm").parse(dish.date);

      if (dishDate.isAfter(last7Days) &&
          dishDate.isBefore(today.add(Duration(days: 1)))) {
        String formattedDate = DateFormat("yyyy-MM-dd").format(dishDate);

        if (!dailyCalories.containsKey(formattedDate)) {
          dailyCalories[formattedDate] = 0;
        }

        // Ensure the value is treated as int
        dailyCalories[formattedDate] =
            (dailyCalories[formattedDate]! + dish.calories.toInt()) as int;
      }
    }
    print("weekly : $dailyCalories");
    return dailyCalories;
  }
}
