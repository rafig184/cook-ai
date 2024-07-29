import 'package:cookai/model/favorites_model.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoriteDatabase {
  List favoriteRecipes = [];

  // final Box<FavoriteData> _myBox = Hive.box<FavoriteData>('mybox');
  // final _myBox = Hive.box('mybox');
  late final Box<FavoriteData> _myBox;

  Future<void> initialize() async {
    if (!Hive.isBoxOpen('mybox')) {
      _myBox = await Hive.openBox<FavoriteData>('mybox');
    } else {
      _myBox = Hive.box<FavoriteData>('mybox');
    }
    loadData();
  }

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

  void deleteFavorite(FavoriteData favorite) {
    favoriteRecipes.removeWhere((item) => item.id == favorite.id);
    _myBox.delete(favorite.id);
  }

  Future<void> deleteAllRecipes() async {
    // Assuming favoriteGifIds is a list of keys
    await _myBox.clear();
    favoriteRecipes.clear();
  }

  bool isFavorite(String id) {
    return favoriteRecipes.any((favorite) => favorite.id == id);
  }
}
