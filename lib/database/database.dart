import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/model/stats_model.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoriteDatabase {
  List favoriteRecipes = [];
  // List savedDishes = [];

  // final Box<FavoriteData> _myBox = Hive.box<FavoriteData>('mybox');
  // final _myBox = Hive.box('mybox');
  late final Box<FavoriteData> _myBox;
  // late final Box<StatsData> _myBox1;

  Future<void> initialize() async {
    if (!Hive.isBoxOpen('mybox')) {
      _myBox = await Hive.openBox<FavoriteData>('mybox');
      // _myBox1 = await Hive.openBox<StatsData>('mybox1');
    } else {
      _myBox = Hive.box<FavoriteData>('mybox');
      // _myBox1 = Hive.box<StatsData>('mybox1');
    }
    loadData();
    // loadStatsData();
  }

  // void createInitialDataStats() {
  //   // Add some initial data if needed
  //   savedDishes = [];

  //   loadStatsData();
  // }

  // void loadStatsData() {
  //   print("Loading Data from DB");
  //   savedDishes = _myBox1.values.toList();
  // }

  // void updateStatsDatabase() {
  //   _myBox1.putAll({for (var dish in savedDishes) dish.id: dish});
  // }

  // void addStats(dish) {
  //   savedDishes.add(dish);
  //   updateStatsDatabase();
  // }

  // Future<void> deleteStat(FavoriteData dish) async {
  //   savedDishes.removeWhere((item) => item.id == dish.id);
  //   _myBox1.delete(dish.id);
  // }

  // Future<void> deleteAllStats() async {
  //   // Assuming favoriteGifIds is a list of keys
  //   await _myBox1.clear();
  //   savedDishes.clear();
  // }

  void createInitialData() {
    // Add some initial data if needed
    favoriteRecipes = [];

    loadData();
  }

  void loadData() {
    print("Loading Data from DB");
    favoriteRecipes = _myBox.values.toList();
  }

  void updateDatabase() {
    _myBox
        .putAll({for (var favorite in favoriteRecipes) favorite.id: favorite});
  }

  void addFavorite(FavoriteData favorite) {
    favoriteRecipes.add(favorite);
    updateDatabase();
  }

  Future<void> deleteFavorite(FavoriteData favorite) async {
    favoriteRecipes.removeWhere((item) => item.id == favorite.id);
    _myBox.delete(favorite.id);
  }

  Future<void> deleteAllRecipes() async {
    // Assuming favoriteGifIds is a list of keys
    await _myBox.clear();
    favoriteRecipes.clear();
  }

  bool isFavorite(String name) {
    return favoriteRecipes.any((favorite) => favorite.name == name);
  }

  Future<List> searchSavedRecipes(String recipe) async {
    return Future.value(
        favoriteRecipes.where((item) => item.name.contains(recipe)).toList());
  }
}
