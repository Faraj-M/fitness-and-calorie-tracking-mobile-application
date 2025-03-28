import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import for Firestore
import 'dart:convert';
import 'add_meal_screen.dart';
import 'add_exercise_screen.dart';
import 'settings_screen.dart';
import '../widgets/calorie_tracker_circle.dart';
import '../widgets/meals_list.dart';
import '../widgets/exercises_list.dart';
import 'past_days_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class SettingsObject {
  SettingsObject({this.option, this.value});

  String? option;
  int? value;

  SettingsObject.fromMap(Map<String, dynamic> map) {
    this.option = map['option'];
    this.value = map['value'];
  }

  Map<String, dynamic> toMap() {
    return {
      'option': this.option,       // Returns a map with 'id'
      'value': this.value,   // Returns a map with 'name'
    };
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> dynamicMeals = [];
  List<Map<String, String>> dynamicExercises = [];
  int _calorieGoal = 3000; // Default goal
  int _caloriesGained = 0; // Total calories gained
  int _caloriesBurned = 0; // Total calories burned
  DateTime selectedDate = DateTime.now();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore
  late Database database;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = Path.join(dbPath, "calorieTracker.db");

    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        SettingsObject exerciseIsManual = SettingsObject(option: 'exerciseIsManual', value: 0);
        await db.execute("CREATE TABLE settings(option TEXT PRIMARY KEY, value INTEGER)");
        await db.execute("CREATE TABLE exerciseDay0(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseDay1(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseDay2(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseDay3(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseDay4(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseDay5(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseDay6(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.execute("CREATE TABLE exerciseCurrent(exercise TEXT PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
        await db.insert(
          'settings',
          exerciseIsManual.toMap()
        );
        setState(() {});
      }
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calorieGoal = prefs.getInt('calorieGoal') ?? 3000;
      final mealsData = prefs.getStringList('meals') ?? [];
      dynamicMeals = mealsData.map((meal) {
        final parts = meal.split('|');
        return {'name': parts[0], 'calories': parts[1]};
      }).toList();
      final exercisesData = prefs.getStringList('exercises') ?? [];
      dynamicExercises = exercisesData.map((exercise) {
        final parts = exercise.split('|');
        return {'name': parts[0], 'calories': parts[1]};
      }).toList();
      _updateCalories();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('calorieGoal', _calorieGoal);
    final mealsData =
        dynamicMeals.map((meal) => '${meal['name']}|${meal['calories']}').toList();
    prefs.setStringList('meals', mealsData);
    final exercisesData =
        dynamicExercises.map((exercise) => '${exercise['name']}|${exercise['calories']}').toList();
    prefs.setStringList('exercises', exercisesData);
  }

  void _updateCalories() {
  setState(() {
    _caloriesGained = dynamicMeals.fold(
        0, (sum, meal) => sum + double.parse(meal['calories']!.replaceAll('+', '')).toInt());
    _caloriesBurned = dynamicExercises.fold(
        0, (sum, exercise) => sum + double.parse(exercise['calories']!.replaceAll('-', '')).toInt());
  });
}


  void _addMeal(Map<String, String> meal) {
    setState(() {
      dynamicMeals.add(meal);
      _updateCalories();
    });
    _saveData();
    _manageDataStorage();
    _showSnackBar('Meal added!');
  }

  void _deleteMeal(String mealName) {
    setState(() {
      dynamicMeals.removeWhere((meal) => meal['name'] == mealName);
      _updateCalories();
    });
    _saveData();
    _manageDataStorage();
  }

  void _addExercise(Map<String, String> exercise) {
    setState(() {
      dynamicExercises.add(exercise);
      _updateCalories();
    });
    _saveData();
    _manageDataStorage();
    _showSnackBar('Exercise added!');
  }

  void _deleteExercise(String exerciseName) {
    setState(() {
      dynamicExercises.removeWhere((exercise) => exercise['name'] == exerciseName);
      _updateCalories();
    });
    _saveData();
    _manageDataStorage();
  }

  Future<void> _manageDataStorage() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];
    
    final todayData = {
      'meals': dynamicMeals,
      'exercises': dynamicExercises,
      'totalCalories': _caloriesGained - _caloriesBurned,
      'date': selectedDate.toIso8601String(),
    };

    int existingIndex = history.indexWhere((dayJson) {
      final day = jsonDecode(dayJson);
      final dayDate = DateTime.parse(day['date']);
      return dayDate.year == selectedDate.year && 
             dayDate.month == selectedDate.month && 
             dayDate.day == selectedDate.day;
    });

    if (existingIndex != -1) {
      history[existingIndex] = jsonEncode(todayData);
    } else {
      history.add(jsonEncode(todayData));
    }

    history.sort((a, b) {
      final dateA = DateTime.parse(jsonDecode(a)['date']);
      final dateB = DateTime.parse(jsonDecode(b)['date']);
      return dateB.compareTo(dateA);
    });

    while (history.length > 2) {
      final oldestDayJson = history.removeLast();
      final Map<String, dynamic> oldestDay = jsonDecode(oldestDayJson);
      await _saveDayToCloud(oldestDay);
    }

    await prefs.setStringList('history', history);
  }

  Future<void> _newDay() async {
  if (dynamicMeals.isEmpty && dynamicExercises.isEmpty) {
    _showSnackBar('Lists are empty. Add meals or exercises first!');
    return; // Exit the function if everything is empty
  }

  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList('history') ?? [];
  final todayData = {
    'meals': dynamicMeals,
    'exercises': dynamicExercises,
    'totalCalories': _caloriesGained - _caloriesBurned,
    'date': DateTime.now().toIso8601String(),
  };
  history.add(jsonEncode(todayData));

  // Push oldest days to Firestore while keeping references for display
  while (history.length > 2) {
    final oldestDayJson = history.removeAt(0);
    final Map<String, dynamic> oldestDay = jsonDecode(oldestDayJson);
    await _saveDayToCloud(oldestDay);
  }

  prefs.setStringList('history', history);

  setState(() {
    dynamicMeals.clear();
    dynamicExercises.clear();
    _caloriesGained = 0;
    _caloriesBurned = 0;
  });
  _saveData();
  _showSnackBar('New day started!');
}

Future<List<Map<String, dynamic>>> _fetchCloudDays() async {
  try {
    final querySnapshot = await _firestore.collection('past_days').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  } catch (e) {
    print('Error fetching cloud days: $e');
    return [];
  }
}

  Future<void> _saveDayToCloud(Map<String, dynamic> dayData) async {
    try {
      await _firestore.collection('past_days').add(dayData);
      print('Day successfully saved to the cloud.');
    } catch (e) {
      print('Error saving day to the cloud: $e');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('This will clear all meals, exercises, and calories.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Clear All'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('history') ?? [];
      
      // Remove the current day's data from history
      history.removeWhere((dayJson) {
        final day = jsonDecode(dayJson);
        final dayDate = DateTime.parse(day['date']);
        return dayDate.year == selectedDate.year && 
               dayDate.month == selectedDate.month && 
               dayDate.day == selectedDate.day;
      });

      // Save updated history
      await prefs.setStringList('history', history);

      setState(() {
        dynamicMeals.clear();
        dynamicExercises.clear();
        _caloriesGained = 0;
        _caloriesBurned = 0;
      });
      _saveData();
      _showSnackBar('All data cleared!');
    }
  }

  void _loadDay(Map<String, dynamic> day) {
    setState(() {
      // Convert dynamic data to String
      dynamicMeals = (day['meals'] as List<dynamic>)
          .map((meal) => {
                'name': meal['name'].toString(),
                'calories': meal['calories'].toString(),
              })
          .toList();

      dynamicExercises = (day['exercises'] as List<dynamic>)
          .map((exercise) => {
                'name': exercise['name'].toString(),
                'calories': exercise['calories'].toString(),
              })
          .toList();

      _caloriesGained = dynamicMeals.fold(
          0, (sum, meal) => sum + int.parse(meal['calories']!.replaceAll('+', '')));
      _caloriesBurned = dynamicExercises.fold(
          0, (sum, exercise) => sum + int.parse(exercise['calories']!.replaceAll('-', '')));
    });
    _saveData();
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(initialGoal: _calorieGoal),
      ),
    );

    if (result != null && result is int) {
      setState(() {
        _calorieGoal = result;
      });
      _saveData();
      _showSnackBar('Calorie goal updated!');
    }
  }

Future<void> _navigateToPastDays() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList('history') ?? [];
  final localDays = history.map((day) {
    final dayData = jsonDecode(day) as Map<String, dynamic>;
    dayData['isLocal'] = true; // Mark as local
    return dayData;
  }).toList();

  final cloudDays = await _fetchCloudDays();
  for (var day in cloudDays) {
    day['isLocal'] = false; // Mark as cloud
  }

  final allDays = [...localDays, ...cloudDays];

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PastDaysScreen(
        days: allDays,
        onLoadDay: (day) {
          _loadDay(day);
          setState(() {
            selectedDate = DateTime.parse(day['date']);
          });
        },
        onDeleteDay: (day) async {
          final isLocal = day['isLocal'] == true;

          // Delete logic for local or cloud
          if (isLocal) {
            // Delete from local
            List<String> updatedHistory = history.where((dayJson) {
              final currentDay = jsonDecode(dayJson);
              return currentDay['date'] != day['date'];
            }).toList();
            await prefs.setStringList('history', updatedHistory);
          } else {
            // Delete from cloud
            try {
              final querySnapshot = await _firestore
                  .collection('past_days')
                  .where('date', isEqualTo: day['date'])
                  .get();

              for (var doc in querySnapshot.docs) {
                await doc.reference.delete();
              }
            } catch (e) {
              print('Error deleting from cloud: $e');
            }
          }

          setState(() {
            allDays.remove(day);
          });
        },
        onSaveToLocal: (day) async {
          // Save cloud day to local
          List<String> updatedHistory = List.from(history)
            ..add(jsonEncode(day));
          await prefs.setStringList('history', updatedHistory);

          // Delete from cloud
          try {
            final querySnapshot = await _firestore
                .collection('past_days')
                .where('date', isEqualTo: day['date'])
                .get();

            for (var doc in querySnapshot.docs) {
              await doc.reference.delete();
            }
          } catch (e) {
            print('Error deleting from cloud: $e');
          }

          setState(() {
            day['isLocal'] = true;
            allDays.remove(day);
            allDays.add(day);
          });
        },
        onSaveToCloud: (day) async {
          // Save local day to cloud
          try {
            await _firestore.collection('past_days').add(day);

            // Delete from local
            List<String> updatedHistory = history.where((dayJson) {
              final currentDay = jsonDecode(dayJson);
              return currentDay['date'] != day['date'];
            }).toList();
            await prefs.setStringList('history', updatedHistory);
          } catch (e) {
            print('Error saving to cloud: $e');
          }

          setState(() {
            day['isLocal'] = false;
            allDays.remove(day);
            allDays.add(day);
          });
        },
        onSaveSpacePreset: () async {
          // Move all local days to the cloud
          for (var day in localDays) {
            try {
              await _firestore.collection('past_days').add(day);
              print('Day saved to cloud: ${day['date']}');
            } catch (e) {
              print('Error saving day to cloud: $e');
            }
          }

          // Clear all local history
          await prefs.setStringList('history', []);

          setState(() {
            allDays.removeWhere((day) => day['isLocal'] == true);
          });
        },
        onDownloadPastWeek: () async {
          // Download the past 7 days from the cloud
          final recentDays = cloudDays
              .where((day) =>
                  DateTime.parse(day['date'])
                      .isAfter(DateTime.now().subtract(Duration(days: 7))))
              .toList();

          for (var day in recentDays) {
            // Move to local
            List<String> updatedHistory = List.from(history)
              ..add(jsonEncode(day));
            await prefs.setStringList('history', updatedHistory);

            // Delete from cloud
            try {
              final querySnapshot = await _firestore
                  .collection('past_days')
                  .where('date', isEqualTo: day['date'])
                  .get();

              for (var doc in querySnapshot.docs) {
                await doc.reference.delete();
              }
            } catch (e) {
              print('Error deleting from cloud: $e');
            }

            day['isLocal'] = true;
          }

          setState(() {
            allDays.removeWhere((day) => !day['isLocal']);
          });
        },
      ),
    ),
  );

  if (result != null && result['shouldRefresh'] == true) {
    setState(() {
      selectedDate = DateTime.parse(result['date']);
    });
  }
}



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _changeDate(int days) async {
    final newDate = selectedDate.add(Duration(days: days));
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history') ?? [];
    
    // Convert all dates to start of day for comparison
    final newDateStart = DateTime(newDate.year, newDate.month, newDate.day);
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Don't allow future dates
    if (newDateStart.isAfter(todayStart)) {
      _showSnackBar('Cannot view future dates');
      return;
    }

    setState(() {
      selectedDate = newDate;
    });

    // Load data for the selected date
    final localDays = history.map((day) => jsonDecode(day) as Map<String, dynamic>).toList();
    final cloudDays = await _fetchCloudDays();
    final allDays = [...localDays, ...cloudDays];

    // Find data for selected date
    final dayData = allDays.firstWhere(
      (day) {
        final dayDate = DateTime.parse(day['date']);
        return dayDate.year == selectedDate.year && 
               dayDate.month == selectedDate.month && 
               dayDate.day == selectedDate.day;
      },
      orElse: () => {'meals': [], 'exercises': [], 'totalCalories': 0},
    );

    if (dayData.isNotEmpty) {
      _loadDay(dayData);
    } else {
      // If viewing today, keep current data
      if (selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day) {
        return;
      }
      // Otherwise, clear the data
      setState(() {
        dynamicMeals.clear();
        dynamicExercises.clear();
        _caloriesGained = 0;
        _caloriesBurned = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int netCalories = _caloriesGained - _caloriesBurned;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: _navigateToSettings,
              child: Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 40), // Space for status bar
              Text(
                'Goal: $_calorieGoal',
                style: TextStyle(
                  color: Color(0xFFE3C004),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Transform.scale(
                scale: 0.8, // Make the circle 80% of its original size
                child: CalorieTrackerCircle(
                  calorieGoal: _calorieGoal,
                  caloriesNet: netCalories,
                ),
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  IconButton(
                    icon: Icon(Icons.chevron_left, color: Color(0xFF00D1FF)),
                    onPressed: () => _changeDate(-1),

                  ),
                  Text(
                    '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                    style: TextStyle(
                      color: Color(0xFF00D1FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: Color(0xFF00D1FF)),
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                    child: MealsList(
                      meals: dynamicMeals,
                      onAddMeal: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddMealScreen()),
                        );
                        if (result != null) {
                          _addMeal({
                            'name': result['name'].toString(),
                            'calories': result['calories'].toString(),
                          });
                        }
                      },
                      onDeleteMeal: _deleteMeal,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(color: Colors.white, width: 2.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ExercisesList(
                        exercises: dynamicExercises,
                        onAddExercise: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddExerciseScreen()),
                          );
                          if (result != null) {
                            _addExercise(result);
                          }
                        },
                        onDeleteExercise: _deleteExercise,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(color: Colors.white, width: 2.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearAllData,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          side: MaterialStateProperty.all(
                            BorderSide(color: Colors.white, width: 1.0),
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16), // Space between buttons
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateToPastDays,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          side: MaterialStateProperty.all(
                            BorderSide(color: Colors.white, width: 1.0),
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        child: Text(
                          'View Past Days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

