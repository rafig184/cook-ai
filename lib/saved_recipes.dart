import 'package:cookai/database/database.dart';
import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/cupertino.dart';
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
  TextEditingController searchController = TextEditingController();
  List searchResults = [];
  bool isSearch = false;

  @override
  void initState() {
    super.initState();
    favoriteBox = Hive.box<FavoriteData>('mybox');
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await db.initialize();
  }

  Future<void> searchRecipe(name) async {
    if (name.isEmpty) {
      setState(() {
        isSearch = false;
      });
    } else {
      try {
        final response = await db.searchSavedRecipes(name);
        setState(() {
          searchResults = response;
          isSearch = true;
        });
        print(response);
      } catch (e) {
        print(e);
      }
    }
  }

  void ClearSearch() {
    setState(() {
      isSearch = false;
    });
  }

  Future<void> _showMyDialog(recipe) async {
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
                              await db.deleteFavorite(recipe);
                              await searchRecipe(searchController.text);
                              Navigator.of(context).pop();
                              setState(() {
                                // isSearch = false;
                              });
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
                              setState(() {
                                isSearch = false;
                              });
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
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15.0, right: 15.0, top: 15.0, bottom: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.grey),
                          onPressed: () async {
                            await searchRecipe(searchController.text);
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Search saved recipes...",
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              setState(() {});
                            },
                            onSubmitted: (value) async {
                              await searchRecipe(searchController.text);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            ClearSearch();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Text(
                        "Favorite Recipes",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 15,
                      ),
                      child: TextButton(
                          onPressed: () async {
                            await deleteAllDialog();
                          },
                          child: const Text("Clear All")),
                    ),
                  ],
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: favoriteBox.listenable(),
                    builder: (context, Box<FavoriteData> box, _) {
                      final displayList =
                          isSearch ? searchResults : box.values.toList();
                      return ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final recipe = displayList[index];
                          var recipeName = recipe?.name.toString();
                          var recipeDescription =
                              recipe?.description.toString();
                          var recipeIngredients = recipe?.ingredients is List
                              ? (recipe?.ingredients as List)
                                  .join(', ')
                                  .replaceAll(', ', '\n')
                              : recipe?.ingredients
                                  .toString()
                                  .replaceAll(', ', '\n');

                          var recipeInstructions = recipe?.instructions is List
                              ? (recipe?.instructions as List).join(', ')
                              : recipe?.instructions.toString();
                          var timeToMake = recipe?.timetomake;
                          var calories = recipe?.calories.toString();
                          var stringRecipe =
                              "$recipeName\n\nTime to make: $timeToMake\n\n$recipeDescription\n\nIngredients:\n$recipeIngredients\n\nInstructions:\n$recipeInstructions\n\nCalories: $calories";
                          return ExpansionTile(
                            collapsedBackgroundColor: Colors.grey.shade200,
                            // backgroundColor: backgroundColor,
                            title: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        recipe?.name ?? 'No Name',
                                        style: const TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w500),
                                        softWrap: true,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _showMyDialog(recipe);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.grey,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: Image.network(
                                        recipe?.image,
                                        fit: BoxFit.cover,
                                        width: 300,
                                        height: 100,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              Stack(
                                children: [
                                  Card(
                                    margin: const EdgeInsets.all(10.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  recipe?.name ?? 'No Name',
                                                  style: const TextStyle(
                                                    fontSize: 20.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  const Icon(
                                                      Icons.timer_outlined),
                                                  Text(timeToMake)
                                                ],
                                              ),
                                            ],
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
                                          Text(
                                            recipeIngredients ??
                                                'No Ingredients',
                                            softWrap: true,
                                            maxLines: null,
                                          ),
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
                                          const Text(
                                            'Calories:',
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                CupertinoIcons.flame_fill,
                                                color: Colors.black,
                                                size: 15.0,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(recipe?.calories),
                                            ],
                                          ),
                                          const SizedBox(height: 15),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                16.0), // Adjust the radius as needed
                                            child: Image.network(
                                              recipe?.image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  SocialShare.shareOptions(
                                                      recipeIngredients
                                                          .toString());
                                                },
                                                child: const Icon(
                                                  Icons.list_alt,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  SocialShare.shareOptions(
                                                      stringRecipe);
                                                },
                                                child: const Icon(
                                                  Icons.share,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  SocialShare.copyToClipboard(
                                                      text: stringRecipe);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                          const SnackBar(
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    content: Text(
                                                        "Copied to Clipboard.."),
                                                  ));
                                                },
                                                child: const Icon(
                                                  Icons.copy,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _showMyDialog(recipe);
                                                },
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
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
