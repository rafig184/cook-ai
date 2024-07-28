import 'dart:convert';
import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/saved_recipes.dart';
import 'package:cookai/searchPage.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[SearchPage(), SavedRecipes()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _openHiveBox();
    });
  }

  Future<void> _openHiveBox() async {
    if (!Hive.isBoxOpen('mybox')) {
      await Hive.openBox<FavoriteData>('mybox');
    }
  }

  @override
  void initState() {
    super.initState();
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
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                decoration: const BoxDecoration(
                  color: backgroundColor,
                ),
                child: Image.asset(
                  "images/logosmall.png",
                )),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text(
                "Home",
                textAlign: TextAlign.right,
              ),
              onTap: () {
                _onItemTapped(0);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text(
                "Saved Recipes",
                textAlign: TextAlign.right,
              ),
              onTap: () {
                _onItemTapped(1);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
