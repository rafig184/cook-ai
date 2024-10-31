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

    // Step 1: Sort savedDishes by date in ascending order
    savedDishes.sort((a, b) => a.date.compareTo(b.date));

    // Step 2: Aggregate calories by formatted date
    Map<String, int> caloriesByDate = {};
    for (var dish in savedDishes) {
      String formattedDate =
          DateFormat('dd/MM').format(dish.date); // Format date
      if (caloriesByDate.containsKey(formattedDate)) {
        caloriesByDate[formattedDate] =
            (caloriesByDate[formattedDate]! + dish.calories).toInt();
      } else {
        caloriesByDate[formattedDate] = dish.calories;
      }
    }

    print("Calories by date (aggregated and sorted): $caloriesByDate");

    // Step 3: Convert to a list of ChartData
    caloriesPerDay = caloriesByDate.entries
        .map((entry) => ChartData(
              entry.key,
              entry.value.toDouble(),
            ))
        .toList();

    print("Calories per day (final sorted list): $caloriesPerDay");

    return caloriesPerDay; // Return the sorted list of ChartData
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
