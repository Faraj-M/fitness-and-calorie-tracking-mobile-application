import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:sqflite/sqflite.dart';
import 'home_screen.dart';
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

class ExerciseObject {
  ExerciseObject({this.exercise, this.cals, this.hour, this.min});

  String? exercise;
  int? cals;
  int? hour;
  int? min;

  ExerciseObject.fromMap(Map<String, dynamic> map) {
    this.exercise = map['exercise'];
    this.cals = map['cals'];
    this.hour = map['hour'];
    this.min = map['min'];
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise': this.exercise,
      'cals': this.cals,
      'hour': this.hour,
      'min': this.min
    };
  }
}

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() =>_AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  late Database database;
  late Future<int> _isManual;
  int day = DateTime.now().weekday - 1;
  bool inputting = false;
  TimeOfDay _time = TimeOfDay.now();

  final _exerciseNameController = TextEditingController();
  final _calorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _isManual = _getSetting('exerciseIsManual');
  }

  Future<void> _initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = Path.join(dbPath, "calorieTracker.db");

    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE IF NOT EXISTS exerciseCurrent(exercise STRING PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
      },
      onOpen: (db) async {
        await db.execute("CREATE TABLE IF NOT EXISTS exerciseCurrent(exercise STRING PRIMARY KEY, cals INTEGER, hour INTEGER, min INTEGER)");
      }
    );
    setState(() {});
  }

  Future<int> _getSetting(String optionRequest) async {
    final db = await database;
    final List<Map<String, Object?>> settingMap = await db.query('settings');
    int returnValue = 0;
    for (final {
      'option': option as String,
      'value': value as int,
    } in settingMap) {
      if (option == optionRequest) {
        returnValue = value;
      }
    }
    return returnValue;
  }

  Future<void> _updateSetting(SettingsObject setting) async {
    final db = await database;

    await db.update(
      'settings',
      setting.toMap(),
      where: 'option = ?',
      whereArgs: [setting.option],
    );
  }

  Future<List<ExerciseObject>> _getExercises(int day) async {

    final List<Map<String, dynamic>> maps = await database.query('exerciseDay$day');

    List<ExerciseObject> exercises = [];
    if (maps.isNotEmpty) {
      for (int i = 0; i < maps.length; i++) {
        exercises.add(ExerciseObject.fromMap(maps[i]));
      }
    }

    return exercises;
  }

  Future<List<ExerciseObject>> _getCurrent() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query('exerciseCurrent');
      return List.generate(maps.length, (i) {
        return ExerciseObject.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting exercises: $e');
      return [];
    }
  }

  Future<void> _resetCurrent() async {
    await database.delete("exerciseCurrent");
    setState(() {});
  }

  Future<void> _setCurrent(int dayIndex) async {
    _resetCurrent();
    await database.execute("SELECT * INTO exerciseCurrent FROM exerciseDay$dayIndex");
    setState(() {});
  }

  Future<void> _insertToCurrent(ExerciseObject exercise) async {
    try {
      await database.insert(
        'exerciseCurrent',
        exercise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      setState(() {
        inputting = false;
      });
      _exerciseNameController.clear();
      _calorieController.clear();
    } catch (e) {
      print('Error inserting exercise: $e');
    }
  }

  Future<void> _deleteFromCurrent(String exercise) async {
    await database.delete(
      'exerciseCurrent',
      where: 'exercise = ?',
      whereArgs: [exercise],
    );
    setState(() {});
  }

  Future<void> _updateSchedule(dayIndex) async {
    await database.execute("SELECT * INTO exerciseDay$dayIndex FROM exerciseCurrent");
    setState(() {});
  }

  Future<void> _insertExercise(ExerciseObject exercise) async {
    await database.insert(
      'exerciseCurrent',
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    setState(() {});
  }

  void _selectTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime != null) {
    setState(() {
      _time = newTime;
    });
    }
  }

  int _getHour() {
    return _time.hour;
  }

  int _getMinute() {
    return _time.minute;
  }

  void _toggleManual(index) {
    setState(() {
      SettingsObject updatedSetting = SettingsObject(option: 'exerciseIsManual', value: index);
      _updateSetting(updatedSetting);
      _isManual = _getSetting('exerciseIsManual');
      if(index == 0) {
        _resetCurrent();
      }
    });
  }

  void _toggleDay(index) {
    setState(() {
      day = index;
      _setCurrent(index);
    });
  }

  void _handleAddExercise() {
    if (_exerciseNameController.text.isEmpty || _calorieController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final exerciseName = _exerciseNameController.text;
    final calories = int.tryParse(_calorieController.text) ?? 0;
    
    ExerciseObject newExercise = ExerciseObject(
      exercise: exerciseName, 
      cals: calories, 
      hour: _getHour(), 
      min: _getMinute()
    );
    
    _insertToCurrent(newExercise).then((_) {
      Navigator.pop(context, {
        'name': exerciseName,
        'calories': '-$calories',
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Exercises')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            FutureBuilder<int> (
                future: _getSetting('exerciseIsManual'),
                builder: (context, snapshot) {
                  return Column(
                    children: [
                      ToggleSwitch(
                        minWidth: MediaQuery.sizeOf(context).width,
                        initialLabelIndex: snapshot.data,
                          totalSwitches: 2,
                          labels: ["Manual", "Scheduled"],
                          onToggle: (index) {
                            _toggleManual(index);
                          }
                      ),
                      SizedBox(height: 10),
                      (snapshot.data == 1)?
                          ToggleSwitch(
                            minWidth: MediaQuery.sizeOf(context).width,
                            initialLabelIndex: day,
                            totalSwitches: 7,
                            labels: ["M", "T", "W", "Th", "F", "Sat", "Sun"],
                            onToggle: (index) {
                              _toggleDay(index);
                            }
                          )
                          :
                          SizedBox(height: 10),
                    ],
                  );
                }
            ),
            SizedBox(height: 10),
            inputting?
                Column(
                  children: [
                    TextField(
                      controller: _exerciseNameController,
                      decoration: InputDecoration(
                        labelText: 'Exercise Name',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    TextField(
                      controller: _calorieController,
                      decoration: InputDecoration(
                        labelText: 'Calories Burned',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                    ElevatedButton(
                      onPressed: _selectTime,
                      child: Text("Time")
                    ),
                    SizedBox(height: 5),
                    Text("Selected time: ${_time.format(context)}", 
                         style: TextStyle(color: Colors.white)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _handleAddExercise,
                      child: Text('Add Exercise'),
                    ),
                  ]
                )
                :
                SizedBox(height: 5),
            FutureBuilder<List<ExerciseObject>> (
                future: _getCurrent(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.data!.isEmpty) {
                    return Center(child: Text("Add some exercises.", style: TextStyle(color: Colors.white)));
                  }

                  return Container(
                    height: 200, // Set a fixed height for the list
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data?.length,
                        itemBuilder: (context, index) {
                          var exercise = snapshot.data![index];
                          return ListTile(
                            title: Text(
                              exercise.exercise!,
                              style: TextStyle(color: Colors.white)
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${exercise.cals!} calories",
                                      style: TextStyle(color: Colors.white)
                                    ),
                                    Text(
                                      "${exercise.hour!}:${exercise.min!.toString().padLeft(2, '0')}", // Format minutes to always show 2 digits
                                      style: TextStyle(color: Colors.white)
                                    ),
                                  ]
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteFromCurrent(exercise.exercise!);
                                  },
                                )
                              ]
                            )
                          );
                        }
                    ),
                  );
                }
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
          color: Colors.blue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  tooltip: "Add Exercise",
                  icon: const Icon(Icons.add_box),
                  onPressed: (){
                    setState(() {
                      inputting = true;
                    });
                  },
                )
              ),
              SizedBox(width: 125),
              Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: "Save",
                    icon: const Icon(Icons.check_box),
                    onPressed: _handleAddExercise,
                  )
              )
            ],
          )
      ),
      backgroundColor: Colors.black, // Ensure background contrast
    );
  }
}
