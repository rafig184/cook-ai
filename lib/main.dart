import 'package:cookai/controller/states_controller.dart';
import 'package:cookai/database/adapter.dart';
import 'package:cookai/database/stats_adapter.dart';
import 'package:cookai/model/favorites_model.dart';
import 'package:cookai/model/stats_model.dart';
import 'package:cookai/splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(FavoriteDataAdapter());
  Hive.registerAdapter(StatsDataAdapter());
  // await Hive.openBox('mybox');
  await Hive.openBox<FavoriteData>('mybox');
  await Hive.openBox<StatsData>('mybox1');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  StatesController testController = Get.put(StatesController());
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CookingAi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        fontFamily: 'OpenSans',
      ),
      home: const SplashScreen(),
    );
  }
}
