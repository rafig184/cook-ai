import 'package:cookai/database/stats_db.dart';
import 'package:cookai/model/stats_model.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _ChartData {
  _ChartData(this.x, this.y);

  final String x;
  final double y;
}

class _StatisticsState extends State<Statistics> {
  late StatsDatabase db;

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
    db.savedDishes.sort((a, b) => b.date.compareTo(a.date));
    setState(() {});
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 10.0),
                child: Text(
                  "Dish Calories Statistics",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
              db.savedDishes.isNotEmpty
                  ? Column(
                      children: [
                        TextButton(
                            onPressed: () async {
                              await db.deleteAllRecipes();
                              setState(() {});
                            },
                            child: const Text("Clear all")),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: db.savedDishes.length,
                          itemBuilder: (context, index) {
                            final data = db.savedDishes[index];

                            return ExpansionTile(
                              leading: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await db.deleteSelectedDish(data);
                                  setState(() {});
                                },
                              ),
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.grey.shade100,
                              title: Text("${data.date} - ${data.title}"),
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "Calories:",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.orangeAccent),
                                                ),
                                                const SizedBox(width: 8),
                                                Text("${data.calories} kcal"),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "Fat:",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .lightBlueAccent),
                                                ),
                                                const SizedBox(width: 8),
                                                Text("${data.fat} g"),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "Protein:",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 89, 202, 147)),
                                                ),
                                                const SizedBox(width: 8),
                                                Text("${data.protein} g"),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "Carbs:",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 151, 89, 202)),
                                                ),
                                                const SizedBox(width: 8),
                                                Text("${data.carbs} g"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            );
                          },
                        ),
                      ],
                    )
                  : const Text("No saved dishes"),
            ],
          ),
        ),
      ),
    );
  }
}
