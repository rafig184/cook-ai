import 'dart:convert';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  TextEditingController searchController = TextEditingController();
  String geminiAIKey = "AIzaSyCfSuT7yLHdpVegyf-nPXpltrETCTHtbiA";
  List<dynamic> resultAI = <dynamic>[];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  Future<void> searchWithAi(searchText) async {
    print("start running");
    // Access your API key as an environment variable (see "Set up your API key" above)
    final apiKey = geminiAIKey;

    // The Gemini 1.5 models are versatile and work with both text-only and multimodal prompts
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [
      Content.text(
        'create some recipes that can be created with this ingredients : $searchText , send the respone data in the same language that it been sent, and make it in an json coding format, without adding : "```json" in the begining or the first and last {}, and always in this format : [{"name : name, "decription":description, "ingredients": ingredients, "instructions": instructions}]',
      )
    ];
    try {
      setState(() {
        isLoading = true;
      });

      final response = await model.generateContent(content);
      print(searchText);
      print('respone  ===> ${response.text}');
      final String responseText = response.text ?? '';
      final List<dynamic> jsonResponse = jsonDecode(responseText);

      setState(() {
        resultAI = jsonResponse;
      });

      print(resultAI);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: backgroundColor,
        title: Image.asset("images/logosmall.png", width: 90),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
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
                          hintText:
                              "Add ingredients to create recipes with AI...",
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {},
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
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
                      child: ListView.builder(
                        itemCount: resultAI.length,
                        itemBuilder: (context, index) {
                          final recipe = resultAI[index];
                          return Card(
                            margin: const EdgeInsets.all(10.0),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          (ingredient) => Text(ingredient)) ??
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
                                          (instruction) => Text(instruction)) ??
                                      [],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
