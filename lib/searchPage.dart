import 'package:cookai/database/database.dart';
import 'package:cookai/model/favorites_model.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:cookai/utils/colors.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:social_share/social_share.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  String geminiAIKey = "AIzaSyCfSuT7yLHdpVegyf-nPXpltrETCTHtbiA";
  List<dynamic> resultAI = <dynamic>[];
  bool isLoading = false;
  bool isSearch = false;
  bool isLoadingSnackBar = false;
  bool isNotGenerate = false;
  late FavoriteDatabase db;

  @override
  void initState() {
    super.initState();
    db = FavoriteDatabase();
    initializeDatabase();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  Future<void> initializeDatabase() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('mybox')) {
      await Hive.openBox<FavoriteData>('mybox');
    }
    await db.initialize();
    if (db.favoriteRecipes.isEmpty) {
      db.createInitialData();
    } else {
      db.loadData();
    }
    setState(() {});
  }

  Future<void> searchWithAi(searchText) async {
    print("start running");
    // Access your API key as an environment variable (see "Set up your API key" above)
    final apiKey = geminiAIKey;

    // The Gemini 1.5 models are versatile and work with both text-only and multimodal prompts
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [
      Content.text(
        'create some recipes that can be created with this ingredients : $searchText , send the respone data in the same language that it been sent, and make it in an json coding format, without adding : "```json" in the begining or the first and last {}, and always in this format : [{"id":random 6 figures number as a string", "name" : name, "decription":description, "ingredients": ingredients, "instructions": instructions}]',
      )
    ];
    try {
      setState(() {
        isLoading = true;
        isSearch = true;
      });

      final response = await model.generateContent(content);
      print(searchText);
      print('respone  ===> ${response.text}');
      final String responseText = response.text ?? '';

      if (responseText.contains(
          "GenerativeAIException: Candidate was blocked due to recitation")) {
        print(
            "Error: GenerativeAIException - Candidate was blocked due to recitation");
        // Handle the specific error case here, e.g., show an alert or a message to the user
        setState(() {
          isNotGenerate = true;
          resultAI = [];
        });
      } else {
        final List<dynamic> jsonResponse = jsonDecode(responseText);
        setState(() {
          resultAI = jsonResponse;
        });
      }

      print(resultAI);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void clearAll() {
    setState(() {
      isSearch = false;
    });
  }

  Future<void> addToFavorite(String id, String name, String description,
      String ingredients, String instructions) async {
    final favorite = FavoriteData(
        id: id,
        name: name,
        description: description,
        ingredients: ingredients,
        instructions: instructions);

    setState(() {
      if (db.isFavorite(id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Recipe is already in favorites.."),
          ),
        );
      } else {
        db.addFavorite(favorite);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to favorites.."),
          ),
        );
      }
    });

    // Print each FavoriteData instance in a readable format
    for (var favorite in db.favoriteRecipes) {
      print(favorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              "Add ingredients to create recipes with AI",
              style: GoogleFonts.openSans(
                textStyle: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w400,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 15.0, right: 15.0, top: 15.0, bottom: 15.0),
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
                    onPressed: () {
                      searchWithAi(searchController.text);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Type ingredients...",
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        searchWithAi(searchController.text);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      searchController.clear();
                      clearAll();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          isSearch
              ? Container(
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.only(
                              top: 30.0), // Adjust the padding value as needed
                          child: Column(
                            children: [
                              LoadingAnimationWidget.hexagonDots(
                                color: primaryColor,
                                size: 80,
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              const Text("Creating recipes just for you..")
                            ],
                          ),
                        )
                      : Flexible(
                          child: isNotGenerate
                              ? const Text(
                                  "AI could not generate, plaese try again..")
                              : ListView.builder(
                                  itemCount: resultAI.length,
                                  itemBuilder: (context, index) {
                                    final recipe = resultAI[index];
                                    var recipeName = recipe['name'].toString();
                                    var recipeDescription =
                                        recipe['description'].toString();
                                    var recipeIngredients =
                                        recipe['ingredients'].toString();
                                    var recipeInstructions =
                                        recipe['instructions'].toString();
                                    var stringRecipe =
                                        "$recipeName, $recipeDescription Ingredients : $recipeIngredients, Instructions : $recipeInstructions";
                                    return Stack(children: [
                                      Card(
                                        margin: const EdgeInsets.all(10.0),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe['name'] ?? 'No Name',
                                                style: const TextStyle(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10.0),
                                              Text(recipe['description'] ??
                                                  'No Description'),
                                              const SizedBox(height: 10.0),
                                              const Text(
                                                'Ingredients:',
                                                style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              ...?recipe['ingredients']?.map(
                                                      (ingredient) =>
                                                          Text(ingredient)) ??
                                                  [],
                                              const SizedBox(height: 10.0),
                                              const Text(
                                                'Instructions:',
                                                style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              ...?recipe['instructions']?.map(
                                                      (instruction) =>
                                                          Text(instruction)) ??
                                                  [],
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
                                                      SocialShare
                                                          .copyToClipboard(
                                                              text:
                                                                  stringRecipe);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              const SnackBar(
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
                                              addToFavorite(
                                                resultAI[index]['id'],
                                                resultAI[index]['name'],
                                                resultAI[index]['description'],
                                                resultAI[index]['ingredients'].join(
                                                    ', '), // Convert list to string
                                                resultAI[index]['instructions']
                                                    .join(', '),
                                              );
                                            },
                                            child: const Icon(
                                              size: 30,
                                              Icons.star,
                                              color: Color.fromARGB(
                                                  255, 253, 194, 46),
                                            ),
                                          ))
                                    ]);
                                  },
                                ),
                        ),
                )
              : Container()
        ],
      ),
    );
  }
}
