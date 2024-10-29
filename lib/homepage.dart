import 'package:cookai/calories_calc.dart';
import 'package:cookai/controller/states_controller.dart';
import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/saved_recipes.dart';
import 'package:cookai/searchPage.dart';
import 'package:cookai/statistics.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  StatesController statesController = Get.put(StatesController());

  static List<Widget> _widgetOptions = <Widget>[
    SearchPage(),
    SavedRecipes(),
    CaloriesCalcPage(),
    Statistics(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _openHiveBox();
      _openHiveBox1();
    });
  }

  Future<void> _openHiveBox() async {
    if (!Hive.isBoxOpen('mybox')) {
      await Hive.openBox<FavoriteData>('mybox');
    }
  }

  Future<void> _openHiveBox1() async {
    if (!Hive.isBoxOpen('mybox1')) {
      await Hive.openBox<FavoriteData>('mybox1');
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
      extendBody: true,
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
              leading: const Icon(Icons.calculate),
              title: const Text(
                "Calories calculator",
                textAlign: TextAlign.right,
              ),
              onTap: () {
                _onItemTapped(2);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text(
                "Favorite Recipes",
                textAlign: TextAlign.right,
              ),
              onTap: () {
                _onItemTapped(1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_thresholding_rounded),
              title: const Text(
                "Statistics",
                textAlign: TextAlign.right,
              ),
              onTap: () {
                _onItemTapped(3);
                Navigator.of(context).pop();
              },
            ),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 300),
                Text("Version 1.0.3"),
                Text("Developed by RGDev Ⓒ 2024"),
              ],
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: StylishBottomBar(
        option: AnimatedBarOptions(
          // iconSize: 20,
          barAnimation: BarAnimation.blink,
          iconStyle: IconStyle.Default,

          opacity: 0.3,
        ),
        // option: DotBarOptions(
        //   dotStyle: DotStyle.tile,
        //   inkColor: secondaryColor,

        // ),
        items: [
          BottomBarItem(
            icon: const Icon(
              Icons.house_outlined,
            ),
            selectedIcon: const Icon(Icons.house),
            selectedColor: secondaryColor,
            unSelectedColor: Colors.grey,
            title: const Text(
              'Home',
              style: TextStyle(fontWeight: FontWeight.w200),
            ),
            // badgePadding: const EdgeInsets.only(left: 50, right: 50),
          ),
          BottomBarItem(
            icon: const Icon(
              Icons.favorite_border,
            ),
            selectedIcon: const Icon(Icons.favorite),
            selectedColor: secondaryColor,
            unSelectedColor: Colors.grey,
            title: const Text(
              'Favorites',
              style: TextStyle(fontWeight: FontWeight.w200),
            ),
            // badgePadding: const EdgeInsets.only(left: 50, right: 50),
          ),
          BottomBarItem(
            icon: const Icon(
              Icons.calculate_outlined,
            ),
            selectedIcon: const Icon(
              Icons.calculate,
            ),
            selectedColor: secondaryColor,
            title: const Text(
              'Calculator',
              style: TextStyle(fontWeight: FontWeight.w200),
            ),
          ),
          BottomBarItem(
            icon: const Icon(
              Icons.data_thresholding_outlined,
            ),
            selectedIcon: const Icon(
              Icons.data_thresholding_rounded,
            ),
            selectedColor: secondaryColor,
            title: const Text(
              'Stats',
              style: TextStyle(fontWeight: FontWeight.w200),
            ),
          ),
        ],
        hasNotch: true,
        fabLocation: StylishBarFabLocation.end,
        currentIndex: _selectedIndex,
        notchStyle: NotchStyle.circle,
        onTap: (index) {
          if (index == _selectedIndex) return;

          setState(() {
            _selectedIndex = index;
            statesController.cameraButtonChangeFalse();
            _onItemTapped(index);
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _onItemTapped(0);
            statesController.cameraButtonChangeTrue();
          });
        },
        backgroundColor: secondaryColor,
        shape: const CircleBorder(),
        child: const Icon(
          CupertinoIcons.camera_fill,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
