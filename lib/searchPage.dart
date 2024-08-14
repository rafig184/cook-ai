import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:cookai/database/database.dart';
import 'package:cookai/model/favorites_model.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:cookai/utils/colors.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:social_share/social_share.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  String geminiAIKey = "AIzaSyCfSuT7yLHdpVegyf-nPXpltrETCTHtbiA";
  String pexelsKey = "kXOUGfQ9o2rjErnylqmOtexVYnFHBChRP095JUoXsttbNOTVMCA9xWoo";
  List<dynamic> resultAI = <dynamic>[];
  List<dynamic> recipiesNames = <dynamic>[];
  List<dynamic> imageListPexels = [];
  List<dynamic> ingredientsList = [];
  bool isLoading = false;
  bool isSearch = false;
  bool isImage = false;
  bool isIngredientInclude = false;
  bool isIngredientsVisible = false;
  bool isLoadingSnackBar = false;
  bool isLoadingImage = false;
  bool isNotGenerate = false;
  late FavoriteDatabase db;
  final FocusNode _focusNode = FocusNode();
  bool _isFieldEmpty = false;

  void _focusOnTextField() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

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
    _focusNode.dispose();
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

  void addIngredients(String searchText) {
    setState(() {
      isIngredientInclude = false;
    });
    if (ingredientsList.contains(searchText) ||
        ingredientsList.contains('$searchText ')) {
      setState(() {
        isIngredientInclude = true;
      });
      return;
    }
    ingredientsList.add(searchText);
    setState(() {
      isIngredientsVisible = true;
    });
  }

  Future<void> searchWithAi(List ingredientsList) async {
    if (ingredientsList.isEmpty) {
      setState(() {
        _isFieldEmpty = true;
        isNotGenerate = true;
      });
      return;
    }

    var stringIngredients = ingredientsList.toString();

    setState(() {
      isNotGenerate = false;
      isLoading = true;
      isSearch = true;
      isIngredientsVisible = false;
      ingredientsList.clear();
    });

    print("Start running");

    final apiKey = geminiAIKey;
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [
      Content.text(
        'create some recipes that can be created with this ingredients: $stringIngredients. Send the response data in the same language it was sent in, in JSON format, without adding "```json" at the beginning or the first and last {}. Always in this format: [{"id": "random 6-figure number as a string", "name": "name", "description": "description", "ingredients": ["ingredient1", "ingredient2"], "instructions": "instructions", "timetomake": "time", "calories": "calories"}], return the ingretients with messurments',
      ),
    ];

    try {
      final response = await model.generateContent(content);
      final String responseText = response.text ?? '';

      print('Response ===> $responseText');

      if (responseText.isNotEmpty) {
        final List<dynamic> jsonResponse = jsonDecode(responseText);

        // Ensure the jsonResponse is a list and not empty
        if (jsonResponse.isNotEmpty) {
          setState(() {
            resultAI = jsonResponse;
            recipiesNames = jsonResponse;
          });

          await fetchImages(resultAI);
          print(resultAI);
        } else {
          setState(() {
            isNotGenerate = true;
          });
          print('Error: The response JSON is not a list or is empty.');
        }
      } else {
        setState(() {
          isNotGenerate = true;
        });
        print('Error: The response text is empty.');
      }
    } catch (e) {
      setState(() {
        isNotGenerate = true;
      });
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchImages(resultAI) async {
    try {
      await langdetect.initLangDetect();
      if (resultAI == null || resultAI.isEmpty) {
        print('Error: Recipes list is null or empty.');
        return;
      } else {
        setState(() {
          imageListPexels = [];
          isImage = false;
          isLoadingImage = true;
        });
        for (var result in resultAI) {
          var imageSearch = result['name'];
          final language = langdetect.detect(imageSearch);
          print("langugae ---> $language");
          if (language != 'en') {
            final translator = GoogleTranslator();
            var translation = await translator.translate(imageSearch,
                from: language, to: 'en');

            print("translation ---> $translation");
            var apiUrl =
                "https://api.pexels.com/v1/search?query=$translation&per_page=1&orientation=landscape";
            var response = await http.get(
              Uri.parse(apiUrl),
              headers: {
                HttpHeaders.authorizationHeader: pexelsKey,
              },
            );
            if (response.statusCode == 200) {
              var data = json.decode(response.body);
              var imageUrl = data['photos'][0]['src']['medium'];
              setState(() {
                imageListPexels.add(imageUrl);
                isImage = true;
              });
              print(imageUrl);
            } else {
              setState(() {
                isImage = false;
              });
              print('Failed to load image for $imageSearch');
            }
          } else {
            var apiUrl =
                "https://api.pexels.com/v1/search?query=$imageSearch&per_page=1&orientation=landscape";
            var response = await http.get(
              Uri.parse(apiUrl),
              headers: {
                HttpHeaders.authorizationHeader: pexelsKey,
              },
            );

            if (response.statusCode == 200) {
              var data = json.decode(response.body);
              var imageUrl = data['photos'][0]['src']['medium'];
              setState(() {
                imageListPexels.add(imageUrl);
                isImage = true;
              });
              print(imageUrl);
            } else {
              setState(() {
                isImage = false;
              });
              print('Failed to load image for $imageSearch');
            }
          }
        }
      }
    } catch (e) {
      print(e);
    } finally {
      isLoadingImage = false;
    }
  }

  void clearAll() {
    setState(() {
      isSearch = false;
      ingredientsList.clear();
    });
  }

  Future<void> addToFavorite(
    String id,
    String name,
    String description,
    String ingredients,
    String instructions,
    String timetomake,
    String calories,
    String image,
  ) async {
    final favorite = FavoriteData(
      id: id,
      name: name,
      description: description,
      ingredients: ingredients,
      instructions: instructions,
      timetomake: timetomake,
      calories: calories,
      image: image,
    );

    setState(() {
      if (db.isFavorite(name)) {
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
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              "Add ingredients to create recipes with AI",
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 15.0, right: 15.0, top: 15.0, bottom: 15.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          clearAll();
                          setState(() {});
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          maxLines: null,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: "Press + after each ingredient..",
                            border: InputBorder.none,
                            errorText: _isFieldEmpty
                                ? 'Please add ingredients..'
                                : isIngredientInclude
                                    ? 'Ingredient already included..'
                                    : null,
                            errorBorder: _isFieldEmpty
                                ? const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red),
                                  )
                                : InputBorder.none,
                            focusedErrorBorder: _isFieldEmpty ||
                                    isIngredientInclude
                                ? const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red),
                                  )
                                : InputBorder.none,
                          ),
                          textInputAction: TextInputAction.done,
                          onChanged: (value) {
                            setState(() {
                              setState(() {
                                _isFieldEmpty = value.isEmpty;
                                isIngredientInclude = false;
                              });
                            });
                          },
                          onSubmitted: (value) {
                            setState(() {
                              _isFieldEmpty = value.isEmpty;
                            });
                            if (!_isFieldEmpty) {
                              addIngredients(searchController.text);
                              searchController.clear();
                            }
                            FocusScope.of(context).requestFocus(_focusNode);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.grey),
                        onPressed: () {
                          addIngredients(searchController.text);
                          searchController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                isIngredientsVisible
                    ? Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: ingredientsList.map<Widget>((ingredient) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: ElevatedButton(
                              iconAlignment: IconAlignment.end,
                              onPressed: () {
                                setState(() {
                                  ingredientsList.remove(ingredient);
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(ingredient.toString()),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  const Icon(Icons.close,
                                      color: Colors.grey, size: 17),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Container(),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: ingredientsList.isEmpty
                      ? Container()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 17),
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            searchWithAi(ingredientsList);
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Create Recipes",
                              ),
                              SizedBox(
                                width: 7,
                              ),
                              Icon(
                                Icons.send_rounded,
                                size: 18,
                              )
                            ],
                          )),
                ),
              ],
            ),
          ),
          isSearch
              ? Container(
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.only(top: 150.0),
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
                                  "AI could not generate, please try again..")
                              : ListView.builder(
                                  itemCount: resultAI.length,
                                  itemBuilder: (context, index) {
                                    final recipe = resultAI[index];
                                    var recipeName = recipe['name'].toString();
                                    var recipeDescription =
                                        recipe['description'].toString();
                                    var recipeIngredients =
                                        recipe['ingredients'] is List
                                            ? (recipe['ingredients'] as List)
                                                .join(', ')
                                                .replaceAll(', ', '\n')
                                            : recipe['ingredients']
                                                .toString()
                                                .replaceAll(', ', '\n');

                                    var recipeInstructions =
                                        recipe['instructions'] is List
                                            ? (recipe['instructions'] as List)
                                                .join(', ')
                                            : recipe['instructions'].toString();

                                    var timeToMake =
                                        recipe['timetomake'].toString();
                                    var calories =
                                        recipe['calories'].toString();
                                    var stringRecipe =
                                        "${recipeName + '\n' + '\n'}Time to make : ${timeToMake + '\n' + '\n'}${recipeDescription + '\n' + '\n'}Ingredients :${'\n'}${recipeIngredients + '\n' + '\n'}Instructions :${'\n'}${recipeInstructions + '\n' + '\n'}Calories : ${calories + '\n'}";

                                    return Stack(children: [
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      recipe['name'] ??
                                                          'No Name',
                                                      style: const TextStyle(
                                                        fontSize: 20.0,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                              ..._buildTextWidgets(
                                                  recipe['ingredients']),
                                              const SizedBox(height: 10.0),
                                              const Text(
                                                'Instructions:',
                                                style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              ..._buildTextWidgets(
                                                  recipe['instructions']),
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
                                                  Text(recipe['calories']),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              isLoadingImage
                                                  ? LoadingAnimationWidget
                                                      .hexagonDots(
                                                      color: primaryColor,
                                                      size: 80,
                                                    )
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16.0),
                                                      child: isImage
                                                          ? Image.network(
                                                              imageListPexels[
                                                                  index],
                                                              fit: BoxFit.cover,
                                                            )
                                                          : const Text(
                                                              "No image found"),
                                                    ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      SocialShare.shareOptions(
                                                          recipeIngredients);
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
                                                    child: const Icon(
                                                      Icons.copy,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      addToFavorite(
                                                          resultAI[index]['id'],
                                                          resultAI[index]
                                                              ['name'],
                                                          resultAI[index]
                                                              ['description'],
                                                          resultAI[index]['ingredients']
                                                                  is List
                                                              ? resultAI[index][
                                                                      'ingredients']
                                                                  .join(', ')
                                                              : resultAI[index][
                                                                  'ingredients'],
                                                          resultAI[index]
                                                                      ['instructions']
                                                                  is List
                                                              ? resultAI[index][
                                                                      'instructions']
                                                                  .join(', ')
                                                              : resultAI[index][
                                                                  'instructions'],
                                                          resultAI[index]
                                                              ['timetomake'],
                                                          resultAI[index]
                                                              ['calories'],
                                                          imageListPexels[index]);
                                                    },
                                                    child: Icon(
                                                      Icons.favorite,
                                                      color: db.isFavorite(
                                                              resultAI[index]
                                                                  ['name'])
                                                          ? Colors.red
                                                          : Colors.grey,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ]);
                                  },
                                ),
                        ),
                )
              : Flexible(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 90,
                        ),
                        IconButton(
                          onPressed: () => _focusOnTextField(),
                          icon: const Opacity(
                            opacity: 0.3,
                            child: Icon(
                              Icons.control_point,
                              size: 140,
                            ),
                          ),
                        ),
                        const Opacity(
                            opacity: 0.4, child: Text("Tap to add ingredients"))
                      ],
                    ),
                  ),
                )
        ],
      ),
    );
  }

  List<Widget> _buildTextWidgets(dynamic data) {
    if (data is List) {
      return data.map<Widget>((item) => Text(item.toString())).toList();
    } else if (data is String) {
      return [Text(data)];
    } else {
      return [];
    }
  }

  Future<void> _loadImage(String url) async {
    final Completer<void> completer = Completer();
    final image = Image.network(url);

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
      },
    );

    image.image.resolve(ImageConfiguration()).addListener(listener);

    return completer.future;
  }
}
