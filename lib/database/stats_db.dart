import 'package:cookai/model/stats_model.dart';
import 'package:cookai/model/chart_class.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class StatsDatabase {
  List savedDishes = [];
  List savedDishesByDate = [];
  List<ChartData> caloriesByWeek = [];
  List totalWeeklyCalories = [];
  double totalLast7DaysCalories = 0;
  double totalLast30DaysCalories = 0;
  double totalDayCalories = 0;
  List<ChartData> caloriesPerDay = [];
  List<ChartData> caloriesPerWeek = [];
  List<ChartData> selectedDayCalories = [];
  List<ChartData> dishesPerDay = [];

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
    print("saved dishes : $savedDishes");
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

  DateTime? getFirstDate() {
    if (savedDishes.isEmpty) return null;
    savedDishes.sort((a, b) => a.date.compareTo(b.date));
    return savedDishes.first.date;
  }

  DateTime? getLastDate() {
    if (savedDishes.isEmpty) return null;
    savedDishes.sort((a, b) => a.date.compareTo(b.date));
    return savedDishes.last.date;
  }

  Future<void> loadDataPerDay(DateTime chosenDate) async {
    // Filter dishes based on the exact day
    savedDishesByDate = savedDishes.where((item) {
      return item.date.year == chosenDate.year &&
          item.date.month == chosenDate.month &&
          item.date.day == chosenDate.day;
    }).toList();

    List<ChartData> dishCaloriesData = savedDishesByDate.map((dish) {
      return ChartData(dish.title, dish.calories.toDouble());
    }).toList();

    dishesPerDay = dishCaloriesData;

    print("saved 222 : $savedDishesByDate");

    // Sum up the calories for the filtered dishes
    double totalCalories =
        savedDishesByDate.fold(0, (sum, item) => sum + item.calories);

    // Format the result as `[date, totalCalories]`
    String formattedDate = DateFormat('dd/MM/yy').format(chosenDate);

    selectedDayCalories = [ChartData(formattedDate, totalCalories)];

    print("Selected Date Calories: $selectedDayCalories");
    totalDayCalories = totalCalories;

    // Optionally, store the result in a variable if needed for other parts of the app
    // selectedDateCalories = result;
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

  double getMaxCaloriesPerDay() {
    if (caloriesPerDay.isEmpty) return 0;

    return caloriesPerDay
        .map((data) =>
            data.y) // Access the y value (calories) for each ChartData entry
        .reduce((a, b) => a > b ? a : b);
  }

  double getMaxCaloriesPerWeek() {
    if (caloriesPerWeek.isEmpty) return 0;

    return caloriesPerWeek
        .map((data) =>
            data.y) // Access the y value (calories) for each ChartData entry
        .reduce((a, b) => a > b ? a : b);
  }

  double getMaxCaloriesPerSpecificDay() {
    if (dishesPerDay.isEmpty) return 0;

    return dishesPerDay
        .map((data) =>
            data.y) // Access the y value (calories) for each ChartData entry
        .reduce((a, b) => a > b ? a : b);
  }

  // List<Map<String, dynamic>> getWeeklyCalories() {
  //   // Map to store total calories for each week with the key "Week X - Month"
  //   Map<String, double> caloriesByWeek = {};

  //   for (var dish in savedDishes) {
  //     // Calculate the week number within the month for each dish date
  //     int weekOfMonth = ((dish.date.day - 1) ~/ 7) + 1;
  //     String monthName = DateFormat('MMMM').format(dish.date);

  //     // Format the week key as "Week X - Month"
  //     String weekKey = "Week $weekOfMonth - $monthName";

  //     // Sum calories for each week
  //     if (caloriesByWeek.containsKey(weekKey)) {
  //       caloriesByWeek[weekKey] = caloriesByWeek[weekKey]! + dish.calories;
  //     } else {
  //       caloriesByWeek[weekKey] = dish.calories.toDouble();
  //     }
  //   }

  //   // Convert the map to a list of maps with 'week' and 'calories' keys
  //   List<Map<String, dynamic>> weeklyCalories = caloriesByWeek.entries
  //       .map((entry) => {'week': entry.key, 'calories': entry.value})
  //       .toList();

  //   print("Weekly Calories: $weeklyCalories");
  //   return weeklyCalories;
  // }

  Map<String, double> getWeeklyCaloriesLast30Days() {
    // Get the date 30 days before today
    DateTime last30DaysDate = DateTime.now().subtract(Duration(days: 30));

    // Map to store total calories for each week with the key "Week X - Month"
    Map<String, double> caloriesByWeek = {};

    for (var dish in savedDishes) {
      // Only include dishes from the last 30 days
      if (dish.date.isAfter(last30DaysDate)) {
        // Calculate the week number within the month for each dish date
        int weekOfMonth = ((dish.date.day - 1) ~/ 7) + 1;
        String monthName = DateFormat('MMMM').format(dish.date);

        // Format the week key as "Week X - Month"
        String weekKey = "Week $weekOfMonth - $monthName";

        // Sum calories for each week
        if (caloriesByWeek.containsKey(weekKey)) {
          caloriesByWeek[weekKey] = caloriesByWeek[weekKey]! + dish.calories;
        } else {
          caloriesByWeek[weekKey] = dish.calories.toDouble();
        }
      }
    }

    print("Weekly Calories (Last 30 Days): $caloriesByWeek");

    caloriesPerWeek = caloriesByWeek.entries
        .map((entry) => ChartData(
              entry.key,
              entry.value.toDouble(),
            ))
        .toList();

    print("Calories per day (final sorted list): $caloriesPerWeek");

    return caloriesByWeek;
  }

  List<ChartData> getLast7DaysCalories() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    // Filter the entries to include only those within the last 7 days
    Map<String, double> caloriesByDay = {};

    for (var dish in savedDishes) {
      if (dish.date.isAfter(sevenDaysAgo) && dish.date.isBefore(now)) {
        String dayKey = DateFormat('dd/MM').format(dish.date);

        if (caloriesByDay.containsKey(dayKey)) {
          caloriesByDay[dayKey] = caloriesByDay[dayKey]! + dish.calories;
        } else {
          caloriesByDay[dayKey] = dish.calories.toDouble();
        }
      }
    }

    // Convert the map to a list of ChartData objects for daily totals
    List<ChartData> last7DaysCalories = caloriesByDay.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();

    // Sort the list by date in ascending order
    last7DaysCalories.sort((a, b) => DateFormat('dd/MM')
        .parse(a.x)
        .compareTo(DateFormat('dd/MM').parse(b.x)));

    // Calculate the total calories for the week
    double totalWeeklyCalories =
        last7DaysCalories.fold(0, (sum, data) => sum + data.y);

    print("Last 7 Days Calories: $last7DaysCalories");
    print("Total Weekly Calories: $totalWeeklyCalories");

    totalLast7DaysCalories = totalWeeklyCalories;

    return last7DaysCalories;
  }

  List<double> getMonthlyCaloriesLast30Days() {
    // Get the date 30 days before today
    DateTime last30DaysDate = DateTime.now().subtract(Duration(days: 30));

    // Map to store total calories for each month (not returned, only for intermediate calculation)
    Map<String, double> caloriesByMonth = {};

    for (var dish in savedDishes) {
      // Only include dishes from the last 30 days
      if (dish.date.isAfter(last30DaysDate)) {
        // Get the month name and year
        String monthName = DateFormat('MMMM').format(dish.date);
        String year = DateFormat('yyyy').format(dish.date);

        // Format the month key as "Month Year"
        String monthKey = "$monthName $year";

        // Sum calories for each month
        if (caloriesByMonth.containsKey(monthKey)) {
          caloriesByMonth[monthKey] =
              caloriesByMonth[monthKey]! + dish.calories;
        } else {
          caloriesByMonth[monthKey] = dish.calories.toDouble();
        }
      }
    }

    // Calculate the total calories for the last 30 days
    double totalMonthlyCalories =
        caloriesByMonth.values.fold(0, (sum, value) => sum + value);

    print("Total Monthly Calories: $totalMonthlyCalories");

    totalLast30DaysCalories = totalMonthlyCalories;
    // Return the total as a list with a single element
    return [totalMonthlyCalories];
  }
}
