import 'package:cookai/database/database.dart';
import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:social_share/social_share.dart';

class SavedRecipes extends StatefulWidget {
  const SavedRecipes({super.key});

  @override
  State<SavedRecipes> createState() => _SavedRecipesState();
}

class _SavedRecipesState extends State<SavedRecipes> {
  late Box<FavoriteData> favoriteBox;
  FavoriteDatabase db = FavoriteDatabase();

  @override
  void initState() {
    super.initState();
    favoriteBox = Hive.box<FavoriteData>('mybox');
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await db.initialize();
  }

  Future<void> _showMyDialog(index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        "Are you sure that you want to delete this recipe?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await favoriteBox.deleteAt(index);
                              Navigator.of(context).pop();
                              setState(() {});
                            },
                            child: const Text(
                              "Yes",
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "No",
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> deleteAllDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        "Are you sure that you want to delete all the recipes?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await db.deleteAllRecipes();
                              Navigator.of(context).pop();
                              setState(() {});
                            },
                            child: const Text(
                              "Yes",
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "No",
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: favoriteBox.isEmpty
          ? const Text("There are no saved recipes..")
          : Column(
              children: [
                TextButton(
                    onPressed: () async {
                      await deleteAllDialog();
                    },
                    child: const Text("Clear All")),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: favoriteBox.listenable(),
                    builder: (context, Box<FavoriteData> box, _) {
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final recipe = box.getAt(index);
                          var recipeName = recipe?.name.toString();
                          var recipeDescription =
                              recipe?.description.toString();
                          var recipeIngredients =
                              recipe?.ingredients.toString();
                          var recipeInstructions =
                              recipe?.instructions.toString();
                          var stringRecipe =
                              "$recipeName, $recipeDescription Ingredients : $recipeIngredients, Instructions : $recipeInstructions";
                          return Stack(
                            children: [
                              Card(
                                margin: const EdgeInsets.all(10.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe?.name ?? 'No Name',
                                        style: const TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),
                                      Text(recipe?.description ??
                                          'No Description'),
                                      const SizedBox(height: 10.0),
                                      const Text(
                                        'Ingredients:',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(recipe?.ingredients ??
                                          'No Ingredients'),
                                      const SizedBox(height: 10.0),
                                      const Text(
                                        'Instructions:',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(recipe?.instructions ??
                                          'No Instructions'),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              SocialShare.shareOptions(
                                                  stringRecipe);
                                            },
                                            child: const Column(
                                              children: [
                                                Icon(
                                                  Icons.share,
                                                  color: Colors.grey,
                                                ),
                                                Text("Share")
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              SocialShare.copyToClipboard(
                                                  text: stringRecipe);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "Copied to Clipboard.."),
                                              ));
                                            },
                                            child: const Column(
                                              children: [
                                                Icon(
                                                  Icons.copy,
                                                  color: Colors.grey,
                                                ),
                                                Text("Copy")
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 15,
                                right: 8,
                                child: TextButton(
                                  onPressed: () {
                                    _showMyDialog(index);
                                  },
                                  child: const Icon(
                                    Icons.delete,
                                    color: Color.fromARGB(255, 255, 62, 62),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
