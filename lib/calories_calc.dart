import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cookai/database/stats_db.dart';
import 'package:cookai/model/stats_model.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final String x;
  final int y;

  ChartData(this.x, this.y);
}

class CaloriesCalcPage extends StatefulWidget {
  const CaloriesCalcPage({super.key});

  @override
  State<CaloriesCalcPage> createState() => _CaloriesCalcPageState();
}

class _CaloriesCalcPageState extends State<CaloriesCalcPage> {
  String geminiAIKey = "AIzaSyCfSuT7yLHdpVegyf-nPXpltrETCTHtbiA";
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool isAnalyzingImage = false;
  bool isAnalyzingImageError = false;
  String imageErrorResponse = "";
  // String resultAi = "";
  List<dynamic> resultAi = <dynamic>[];
  String selectedDataTitle = '';
  int selectedDataValue = 0;
  List<ChartData> chartData = [];
  late StatsDatabase db;
  int dishId = 0;
  final Random _random = Random();
  DateTime dateTime = DateTime.now();

  void generateRandomNumber() {
    var timestamp = DateTime.now();
    // var formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    setState(
      () {
        dishId = 1000 + _random.nextInt(9000);
        dateTime = timestamp;
        print(timestamp);
        print('stats : ${db.savedDishes}');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    db = StatsDatabase();
    initializeDatabase();
    print(db.savedDishes);
  }

  Future<void> initializeDatabase() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('mybox1')) {
      await Hive.openBox<StatsData>('mybox1');
    }
    await db.initialize();
    if (db.savedDishes.isEmpty) {
      db.createInitialData();
    } else {
      db.loadData();
    }
    setState(() {});
  }

  void updateChartData(int index) {
    final result = resultAi[index];
    int fat = int.tryParse(result['fatInGrams']?.toString() ?? '0') ?? 0;
    int protein = int.tryParse(result['protein']?.toString() ?? '0') ?? 0;
    int carbs = int.tryParse(result['carbs']?.toString() ?? '0') ?? 0;

    chartData = [
      ChartData('Fat', fat),
      ChartData('Protein', protein),
      ChartData('Carbs', carbs),
    ];
  }

  Future getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      resultAi.clear();
      isAnalyzingImage = false;
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        analysePicture();
      }
    });
  }

  Future<void> _openCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      setState(() {
        resultAi.clear();
        _image = File(pickedFile.path);
        // isAnalyzingImageError = false;

        analysePicture();
      });
    }

    print("image path : $_image");
  }

  Future<void> analysePicture() async {
    if (_image == null) {
      print("No image selected.");
      return;
    }

    try {
      setState(() {
        isAnalyzingImageError = false;
        isAnalyzingImage = true;
      });

      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: geminiAIKey,
      );

      const promptText =
          'what is the dish that you see in the picture and how many calories it containes?.in JSON format, without adding "```json" at the beginning or the first and last {}. Always in this format: [{"title": "title", "description": "description", "calories": "calories", "fatInGrams": "fatInGrams", "protein": "protein", "carbs": "carbs"}], calories fatInGrams and protein must be a number . if the image doesnt contain food or there is something with the quality return the word "Something went wrong" and then the reason for the error.';
      final prompt = TextPart(promptText);

      // Read image bytes efficiently
      final imageBytes = await _image!.readAsBytes();

      // Create a DataPart for the image
      final imagePart = DataPart('image/jpeg', imageBytes);

      final content = [prompt, imagePart];

      final response = await model.generateContent([Content.multi(content)]);

      print("this is the response : ${response.text}");
      if (response.text!.contains("Something went wrong")) {
        setState(() {
          isAnalyzingImageError = true;
          imageErrorResponse = response.text.toString();
          showErrorDialog(response.text.toString());
        });
      } else {
        setState(() {
          resultAi = jsonDecode(response.text!);
          print(resultAi);
        });
      }
    } on PlatformException catch (e) {
      print("Error using Gemini API: $e");
      setState(() {
        isAnalyzingImageError = true;
      });
    } catch (e) {
      print("Unexpected error: $e");
      if (e is GenerativeAIException) {
        showErrorDialog(e.message);
      } else {
        showErrorDialog("An unexpected error occurred.");
      }
      setState(() {
        isAnalyzingImageError = true;
      });
    } finally {
      setState(() {
        isAnalyzingImage = false;
      });
    }
  }

  void showErrorDialog(errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error!'),
        content: Text(
          errorMessage,
          style: TextStyle(color: Colors.red.shade900),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> addToStats(
    String id,
    String title,
    int calories,
    int fat,
    int protein,
    int carbs,
    DateTime date,
  ) async {
    final savedDish = StatsData(
      id: id,
      title: title,
      calories: calories,
      fat: fat,
      protein: protein,
      carbs: carbs,
      date: date,
    );

    setState(() {
      db.addStats(savedDish);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Added to Statistics.."),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: isAnalyzingImage
              // Show loading animation when analyzing the image
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingAnimationWidget.hexagonDots(
                      color: Colors.blueAccent.shade400,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text("Analyzing image..."),
                  ],
                )
              : resultAi.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: resultAi.length,
                              itemBuilder: (context, index) {
                                final result = resultAi[index];
                                updateChartData(index);
                                var title =
                                    result['title']?.toString() ?? 'No Title';
                                var description =
                                    result['description']?.toString() ??
                                        'No Description';
                                var calories = result['calories']?.toString() ??
                                    'No Calories';
                                var fatInGrams =
                                    result['fatInGrams']?.toString() ??
                                        'No Fat';
                                var protein = result['protein']?.toString() ??
                                    'No Protein';
                                var carbs =
                                    result['carbs']?.toString() ?? 'No Carbs';

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 10.0),
                                  elevation: 8, // More elevation for depth
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        25.0), // Softer rounded corners
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title Row with Close Button
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 22.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                softWrap: true,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  resultAi.clear();
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.redAccent,
                                                size: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12.0),
                                        // Description Text
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.grey.shade600,
                                            height:
                                                1.4, // Adjust line height for better readability
                                          ),
                                        ),
                                        // const SizedBox(height: 2.0),
                                        // Nutritional Information Section
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "$calories kcal",
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .orangeAccent, // Highlight color
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      "Calories",
                                                      style: TextStyle(
                                                        fontSize: 14.0,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(
                                                  color: Colors.grey,
                                                  thickness: 2,
                                                  indent: 16,
                                                  endIndent: 16,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "${fatInGrams}g",
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .lightBlueAccent,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      "Fat",
                                                      style: TextStyle(
                                                        fontSize: 14.0,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(
                                                  color: Colors.grey,
                                                  thickness: 2,
                                                  indent: 16,
                                                  endIndent: 16,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "${protein}g",
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromARGB(
                                                            255, 89, 202, 147),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      "Protein",
                                                      style: TextStyle(
                                                        fontSize: 14.0,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(
                                                  color: Colors.grey,
                                                  thickness: 2,
                                                  indent: 16,
                                                  endIndent: 16,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "${carbs}g",
                                                      style: const TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromARGB(
                                                            255, 151, 89, 202),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      "Carbs",
                                                      style: TextStyle(
                                                        fontSize: 14.0,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 250,
                                                  child: SfCircularChart(
                                                    series: <CircularSeries>[
                                                      RadialBarSeries<ChartData,
                                                          String>(
                                                        onPointTap: (args) {
                                                          final ChartData
                                                              tappedData =
                                                              chartData[args
                                                                  .pointIndex!];
                                                          setState(() {
                                                            selectedDataTitle =
                                                                tappedData.x;
                                                            selectedDataValue =
                                                                tappedData.y;
                                                          });

                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return AlertDialog(
                                                                title: Text(
                                                                    selectedDataTitle),
                                                                content: Text(
                                                                    '$selectedDataTitle: ${selectedDataValue}g'),
                                                                actions: <Widget>[
                                                                  TextButton(
                                                                    child:
                                                                        const Text(
                                                                            'OK'),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        dataSource: chartData,
                                                        xValueMapper:
                                                            (ChartData data,
                                                                    _) =>
                                                                data.x,
                                                        yValueMapper:
                                                            (ChartData data,
                                                                    _) =>
                                                                data.y,
                                                        dataLabelSettings:
                                                            const DataLabelSettings(
                                                          isVisible: true,
                                                        ),
                                                        pointColorMapper:
                                                            (ChartData data,
                                                                _) {
                                                          switch (data.x) {
                                                            case 'Fat':
                                                              return Colors
                                                                  .lightBlueAccent;
                                                            case 'Protein':
                                                              return const Color
                                                                  .fromARGB(255,
                                                                  89, 202, 147);
                                                            case 'Carbs':
                                                              return const Color
                                                                  .fromARGB(255,
                                                                  151, 89, 202);
                                                            default:
                                                              return Colors
                                                                  .grey;
                                                          }
                                                        },
                                                        cornerStyle: CornerStyle
                                                            .bothCurve,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                FloatingActionButton(
                                                  backgroundColor:
                                                      secondaryColor,
                                                  shape: const CircleBorder(),
                                                  onPressed: () {
                                                    generateRandomNumber();
                                                    addToStats(
                                                        dishId.toString(),
                                                        title,
                                                        int.parse(calories),
                                                        int.parse(fatInGrams),
                                                        int.parse(protein),
                                                        int.parse(carbs),
                                                        dateTime);
                                                  },
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                // Text(
                                                //   "$calories kcal",
                                                //   style: const TextStyle(
                                                //     fontSize: 15.0,
                                                //     fontWeight: FontWeight.bold,
                                                //     color: Colors
                                                //         .orangeAccent, // Highlight color
                                                //   ),
                                                // ),
                                              ],
                                            )
                                          ],
                                        ),
                                        const Align(
                                          alignment: Alignment.topRight,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                  "Click on + to add to Statistics"),
                                              SizedBox(
                                                width: 15,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        if (_image != null)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(25.0),
                                            child: Image.file(
                                              _image!,
                                              fit: BoxFit.cover,
                                              height: 300,
                                              width: double.infinity,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )

                  // Show the initial UI with image selection options
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20.0, horizontal: 10.0),
                          child: Text(
                            "Dish Calories Calculator",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  24, // Increased font size for greater emphasis
                              fontWeight: FontWeight
                                  .w600, // Use a slightly lighter weight for a modern feel
                              color: Colors
                                  .black, // Darker green for a professional look
                              letterSpacing:
                                  1.5, // Increased letter spacing for elegance
                              shadows: [
                                Shadow(
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(
                                      0.2), // Subtle shadow for depth
                                  offset: const Offset(
                                      1.0, 1.0), // Position of the shadow
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          "Select an option below",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Colors.grey, // Subtle gray for secondary text
                            fontStyle: FontStyle.italic, // Stylish touch
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Camera Button
                            GestureDetector(
                              onTap: () => _openCamera(),
                              child: Container(
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade300,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      size: 70,
                                      color: Colors
                                          .blueAccent, // Modern color for the icon
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Camera",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Gallery Button
                            GestureDetector(
                              onTap: () => getImageFromGallery(),
                              child: Container(
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade300,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.image_rounded,
                                      size: 70,
                                      color: Color.fromARGB(255, 89, 202,
                                          147), // Modern color for the icon
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Gallery",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
    );
  }
}
