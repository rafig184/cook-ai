import 'package:cookai/model/stats_model.dart';
import 'package:cookai/model/chart_class.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class StatsDatabase {
  List savedDishes = [];
  List totalWeeklyCalories = [];
  List<ChartData> caloriesPerDay = [];

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

  Future<void> createInitialData() async {
    savedDishes = [];

    loadData();
  }

  Future<void> loadData() async {
    print("Loading Data from DB");
    savedDishes = _myBox.values.toList();
  }

  Future<void> updateDatabase() async {
    _myBox.putAll({for (var dish in savedDishes) dish.id: dish});
  }

  Future<void> addStats(StatsData dish) async {
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

  List<ChartData> getCaloriesPerDay() {
    print("savedDishes content: $savedDishes"); // Check savedDishes content

    Map<String, int> caloriesByDate = {};
    for (var dish in savedDishes) {
      // Ensure dish.date is a DateTime and dish.calories is an int
      String formattedDate =
          DateFormat('dd/MM').format(dish.date); // Format the date
      if (caloriesByDate.containsKey(formattedDate)) {
        // If the date already exists, add to the existing calories
        caloriesByDate[formattedDate] =
            (caloriesByDate[formattedDate]! + dish.calories).toInt();
      } else {
        // If the date doesn't exist, initialize it with the current dish's calories
        caloriesByDate[formattedDate] = dish.calories;
      }
    }

    print("Calories by date: $caloriesByDate"); // Check the caloriesByDate map

    // Create a list of _ChartData objects
    caloriesPerDay = caloriesByDate.entries
        .map((entry) => ChartData(entry.key,
            entry.value.toDouble())) // Use entry.value.toDouble() if needed
        .toList();

    return caloriesPerDay; // Return the list of _ChartData objects
  }

  double getMaxCalories() {
    if (caloriesPerDay.isEmpty) return 0;

    return caloriesPerDay
        .map((data) =>
            data.y) // Access the y value (calories) for each ChartData entry
        .reduce((a, b) => a > b ? a : b);
  }

  List<ChartData> getWeeklyCalories() {
    // Map to store total calories for each week
    Map<String, double> caloriesByWeek = {};

    for (var dish in savedDishes) {
      // Format the date to get the start of the week (e.g., "W01-24" for week 1 of 2024)
      String weekKey =
          "${DateFormat('yy').format(dish.date)}-W${(dish.date.day / 7).ceil()}";

      // If the week already exists, add to the existing calories
      if (caloriesByWeek.containsKey(weekKey)) {
        caloriesByWeek[weekKey] = caloriesByWeek[weekKey]! + dish.calories;
      } else {
        // Otherwise, initialize the week's calories with the current dish's calories
        caloriesByWeek[weekKey] = dish.calories.toDouble();
      }
    }

    // Convert the map to a list of ChartData objects for weekly totals
    List<ChartData> weeklyCalories = caloriesByWeek.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();
    totalWeeklyCalories = weeklyCalories;

    print("Weekly Calories: $weeklyCalories");
    return weeklyCalories;
  }
}
