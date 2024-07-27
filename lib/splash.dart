import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cookai/homepage.dart';
import 'package:cookai/utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(Duration(seconds: 4));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => Homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: backgroundColor,
        // Center the content vertically and horizontally
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/logosmall.png', // Adjust the path to your logo image
                width: 250, // Set the width of the image
                height: 250, // Set the height of the image
                fit: BoxFit.contain,
              ),
              const SizedBox(
                  height:
                      60), // Add some space between the image and the loader
              LoadingAnimationWidget.hexagonDots(
                color: primaryColor,
                size: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
