import 'package:cookai/database/stats_db.dart';
import 'package:cookai/model/stats_model.dart';
import 'package:cookai/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'model/chart_class.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

enum Filter { lastWeek, lastMonth, selectedDay }

class _ChartData {
  _ChartData(this.x, this.y);

  final String x;
  final double y;
}

class _StatisticsState extends State<Statistics> {
  late StatsDatabase db;
  bool isLoading = false;
  late TooltipBehavior _tooltip;
  Filter selectedFilter = Filter.lastWeek;
  bool isSelectedWeekly = true;
  bool isSelectedMonthly = false;
  bool isFilterVisible = false;
  bool isFilterSelected = false;
  String _selectedDate = "";

  @override
  void initState() {
    super.initState();
    db = StatsDatabase();
    initializeDatabase();
    _tooltip = TooltipBehavior(enable: true);
    // db.getCaloriesPerDay();
  }

  Future<void> initializeDatabase() async {
    try {
      isLoading = true;
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
      db.getCaloriesPerDay();
      db.getWeeklyCaloriesLast30Days();
      db.getLast7DaysCalories();
      db.getMonthlyCaloriesLast30Days();

      print("caloriesperday : ${db.caloriesPerDay}");
      setState(() {});
      print(db.savedDishes);
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yy HH:mm').format(date);
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is DateTime) {
        var date = args.value as DateTime;
        _selectedDate = DateFormat('dd/MM/yy').format(date).toString();
        print("Selected Date: $_selectedDate");
        db.loadDataPerDay(date); // Pass the DateTime directly to loadDataPerDay
      }
      isFilterSelected = true;
    });
  }

  Future<void> deleteAllDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      "Are you sure that you want to delete all the saved dishes?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await db.deleteAllStats();
                            setState(() {});
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                          child: const Text(
                            "Yes",
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "No",
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              isLoading
                  ? Column(children: [
                      const SizedBox(
                        height: 150,
                      ),
                      LoadingAnimationWidget.hexagonDots(
                        color: Colors.blueAccent.shade400,
                        size: 80,
                      ),
                    ])
                  : db.savedDishes.isNotEmpty
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 40,
                                child: SegmentedButton<Filter>(
                                    showSelectedIcon: false,
                                    style: SegmentedButton.styleFrom(
                                      // maximumSize: const Size(double.infinity, 15),

                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: primaryColor,
                                      selectedForegroundColor: Colors.white,
                                      selectedBackgroundColor: primaryColor,
                                      side: BorderSide.none,
                                    ),
                                    segments: const <ButtonSegment<Filter>>[
                                      ButtonSegment<Filter>(
                                        value: Filter.lastWeek,
                                        label: Text(
                                          'Last 7 days',
                                          style: TextStyle(height: -0.6),
                                        ),
                                      ),
                                      ButtonSegment<Filter>(
                                        value: Filter.lastMonth,
                                        label: Text(
                                          'Last 30 days',
                                          style: TextStyle(height: -0.6),
                                        ),
                                      ),
                                      ButtonSegment<Filter>(
                                        value: Filter.selectedDay,
                                        label: Text(
                                          'Select day',
                                          style: TextStyle(height: -0.6),
                                        ),
                                      ),
                                    ],
                                    selected: <Filter>{selectedFilter},
                                    onSelectionChanged:
                                        (Set<Filter> newSelection) {
                                      setState(() {
                                        selectedFilter = newSelection.first;
                                        if (selectedFilter ==
                                            Filter.lastMonth) {
                                          db.getWeeklyCaloriesLast30Days();
                                          db.getMonthlyCaloriesLast30Days();
                                          isSelectedWeekly = false;
                                          isSelectedMonthly = true;
                                          isFilterVisible = false;
                                          isFilterSelected = false;
                                          db.totalDayCalories = 0;
                                          db.selectedDayCalories = [];
                                        } else if (selectedFilter ==
                                            Filter.lastWeek) {
                                          db.getLast7DaysCalories();
                                          isSelectedMonthly = false;
                                          isSelectedWeekly = true;
                                          isFilterVisible = false;
                                          isFilterSelected = false;
                                          db.totalDayCalories = 0;
                                          db.selectedDayCalories = [];
                                        } else if (selectedFilter ==
                                            Filter.selectedDay) {
                                          if (isFilterVisible == false) {
                                            isFilterVisible = true;
                                            isSelectedWeekly = false;
                                            isSelectedMonthly = false;
                                            db.loadDataPerDay(DateTime.now());
                                          } else {
                                            isFilterVisible = false;
                                            isFilterSelected = false;
                                          }
                                          setState(() {});
                                        }
                                      });
                                    }),
                              ),
                            ),
                            isFilterVisible
                                ? SfDateRangePicker(
                                    minDate: db.getFirstDate(),
                                    maxDate: db.getLastDate(),
                                    selectionColor: primaryColor,
                                    todayHighlightColor: primaryColor,
                                    initialSelectedDate: DateTime.now(),
                                    headerStyle:
                                        const DateRangePickerHeaderStyle(
                                      backgroundColor:
                                          Color.fromRGBO(238, 238, 238, 1),
                                    ),
                                    backgroundColor:
                                        const Color.fromRGBO(238, 238, 238, 1),
                                    onSelectionChanged: _onSelectionChanged,
                                    selectionMode:
                                        DateRangePickerSelectionMode.single,
                                  )
                                : Container(),
                            const SizedBox(
                              height: 10,
                            ),
                            isSelectedWeekly
                                ? const Text("Weekly stats per day")
                                : isSelectedMonthly
                                    ? const Text("Montly stats per week")
                                    : isFilterVisible
                                        ? const Text("Selected day stats")
                                        : Container(),
                            SizedBox(
                              height: 250,
                              child: SfCartesianChart(
                                primaryXAxis: const CategoryAxis(
                                  labelIntersectAction:
                                      AxisLabelIntersectAction.trim,
                                ),
                                primaryYAxis: NumericAxis(
                                  minimum: 0,
                                  maximum: isSelectedWeekly
                                      ? db.getMaxCaloriesPerDay()
                                      : isSelectedMonthly
                                          ? db.getMaxCaloriesPerWeek()
                                          : isFilterVisible
                                              ? db.getMaxCaloriesPerSpecificDay()
                                              : db.getMaxCaloriesPerSpecificDay(),
                                  interval: 50,
                                ),
                                tooltipBehavior: _tooltip,
                                series: <CartesianSeries<ChartData, String>>[
                                  ColumnSeries<ChartData, String>(
                                    dataSource: isSelectedWeekly
                                        ? db.sevenDaysdata
                                        : isSelectedMonthly
                                            ? db.caloriesPerWeek
                                            : isFilterSelected
                                                ? db.dishesPerDay
                                                : db.dishesPerDay,
                                    xValueMapper: (ChartData data, _) => data.x,
                                    yValueMapper: (ChartData data, _) => data.y,
                                    name: 'Calories',
                                    // Use the pointColorMapper to assign colors based on the day or index
                                    pointColorMapper: (ChartData data, _) {
                                      // You can define an array of colors
                                      List<Color> colors = [
                                        Colors.blue.shade300,
                                        Colors.green.shade300,
                                        Colors.red.shade300,
                                        Colors.orange.shade300,
                                        Colors.purple.shade300,
                                        Colors.yellow.shade300,
                                        Colors.cyan.shade300,
                                        // Add more colors if you have more days
                                      ];

                                      // Use the index or some property of data to determine the color
                                      int index = isSelectedWeekly
                                          ? db.sevenDaysdata.indexOf(data)
                                          : isSelectedMonthly
                                              ? db.caloriesPerWeek.indexOf(data)
                                              : isFilterVisible
                                                  ? db.dishesPerDay
                                                      .indexOf(data)
                                                  : db.dishesPerDay
                                                      .indexOf(data);
                                      return colors[index %
                                          colors.length]; // Loop through colors
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                    // width: 1,
                                  ),
                                ],
                              ),
                            ),
                            isSelectedWeekly
                                ? Text(
                                    "Weekly Calories: ${db.totalLast7DaysCalories}")
                                : isSelectedMonthly
                                    ? Text(
                                        "Montly Calories : ${db.totalLast30DaysCalories}")
                                    : isFilterVisible
                                        ? Text(
                                            "Total selected day calories : ${db.totalDayCalories}")
                                        : Container(),
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 15, left: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                      onPressed: () {
                                        deleteAllDialog();

                                        setState(() {});
                                      },
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete_forever_rounded),
                                          SizedBox(
                                            width: 7,
                                          ),
                                          Text("Clear all"),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                            ListView.builder(
                              reverse: true,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: isFilterSelected
                                  ? db.savedDishesByDate.length
                                  : db.savedDishes.length,
                              itemBuilder: (context, index) {
                                final data = isFilterSelected
                                    ? db.savedDishesByDate[index]
                                    : db.savedDishes[index];

                                return ExpansionTile(
                                  leading: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await db.deleteSelectedDish(data);
                                      db.getCaloriesPerDay();
                                      db.getLast7DaysCalories();
                                      db.getWeeklyCaloriesLast30Days();
                                      db.savedDishesByDate;
                                      setState(() {});
                                    },
                                  ),
                                  backgroundColor: Colors.white,
                                  collapsedBackgroundColor:
                                      Colors.grey.shade100,
                                  title: Text(
                                      "${formatDate(data.date)} - ${data.title}"),
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                          color: Colors
                                                              .orangeAccent),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                        "${data.calories} kcal"),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                              255,
                                                              89,
                                                              202,
                                                              147)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text("${data.protein} g"),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                              255,
                                                              151,
                                                              89,
                                                              202)),
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
