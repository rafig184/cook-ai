import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/saved_recipes.dart';
import 'package:cookai/searchPage.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: backgroundColor,
        title: Image.asset("images/logosmall2.png", width: 90),
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
                  "images/logosmall2.png",
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
              leading: const Icon(Icons.favorite),
              title: const Text(
                "Saved Recipes",
                textAlign: TextAlign.right,
              ),
              onTap: () {
                _onItemTapped(1);
                Navigator.of(context).pop();
              },
            ),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 400),
                Text("Version 1.0.2"),
                Text("Developed by RGDev Ⓒ 2024"),
              ],
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
