import 'dart:convert';
import 'dart:io';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

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
          'what is the dish that you see in the picture and how many calories it containes?.in JSON format, without adding "```json" at the beginning or the first and last {}. Always in this format: [{"title": "title", "description": "description", "calories": "calories", "fatPrecentage": "fatPrecentage", "protein": "protein"}], calories fatPrecentage and protein must be a number . if the image doesnt contain food or there is something with the quality return the word "Something went wrong" and then the reason for the error.';
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
                    color: primaryColor,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text("Analyzing image..."),
                ],
              )
            : resultAi.isNotEmpty
                // Show the results when analysis is complete and data is available
                ? Expanded(
                    child: ListView.builder(
                      itemCount: resultAi.length,
                      itemBuilder: (context, index) {
                        final result = resultAi[index];
                        var title = result['title']?.toString() ?? 'No Title';
                        var description = result['description']?.toString() ??
                            'No Description';
                        var calories =
                            result['calories']?.toString() ?? 'No Calories';
                        var fatPrecentage =
                            result['fatPrecentage']?.toString() ?? 'No Fat';
                        var protein =
                            result['protein']?.toString() ?? 'No protein';

                        return Card(
                          margin: const EdgeInsets.all(10.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    IconButton(
                                      // iconSize: 80,
                                      onPressed: () {
                                        setState(() {
                                          resultAi.clear();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10.0),
                                Text(description),
                                const SizedBox(height: 15.0),
                                Text(
                                  "Calories : $calories",
                                  style: const TextStyle(
                                    fontSize: 17.0,
                                    // fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15.0),
                                Text(
                                  "Fat Precentage : $fatPrecentage%",
                                  style: const TextStyle(
                                    fontSize: 17.0,
                                    // fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15.0),
                                Text(
                                  "Protein : $protein g",
                                  style: const TextStyle(
                                    fontSize: 17.0,
                                    // fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15.0),
                                if (_image != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        20.0), // Adjust the radius as needed
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                      height: 300, // Adjust the height
                                      width: double
                                          .infinity, // Make it take full width
                                    ),
                                  )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                // Show the initial UI with image selection options
                : Column(
                    children: [
                      const Text(
                        "Calculate your dish calories using a picture",
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            IconButton(
                              iconSize: 80,
                              onPressed: () => _openCamera(),
                              icon: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            // const SizedBox(height: 5),
                            const Text("Camera"),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            IconButton(
                              iconSize: 80,
                              onPressed: () => getImageFromGallery(),
                              icon: Icon(
                                Icons.image_rounded,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            // const SizedBox(height: 5),
                            const Text("Gallery"),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
