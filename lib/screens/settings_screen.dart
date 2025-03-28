import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

class SettingsScreen extends StatefulWidget {
  final int initialGoal;

  SettingsScreen({required this.initialGoal});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _goalController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  int _maintenanceCalories = 0;
  int _weightLossCalories = 0;
  int _weightGainCalories = 0;
  TimeOfDay? selectedTime;
  int _savedMaintenanceCalories = 0;
  int _savedWeightLossCalories = 0;
  int _savedWeightGainCalories = 0;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _goalController = TextEditingController(text: widget.initialGoal.toString());
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _heightController.text = prefs.getString('height') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
      _savedMaintenanceCalories = prefs.getInt('maintenanceCalories') ?? 0;
      _savedWeightLossCalories = prefs.getInt('weightLossCalories') ?? 0;
      _savedWeightGainCalories = prefs.getInt('weightGainCalories') ?? 0;
    });

    _loadNotificationTime();
  }

  Future<void> _loadNotificationTime() async {
    final doc = await _firestore.collection('timers').doc('dailyReminder').get();
    if (doc.exists) {
      final hour = doc['hour'] as int;
      final minute = doc['minute'] as int;
      setState(() {
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _saveTimerToCloud(TimeOfDay targetTime) async {
    try {
      await _firestore.collection('timers').doc('dailyReminder').set({
        'hour': targetTime.hour,
        'minute': targetTime.minute,
      });
      print('Timer saved to cloud: ${targetTime.format(context)}');
    } catch (e) {
      print('Failed to save timer to cloud: $e');
    }
  }

  Future<void> _saveValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('height', _heightController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setInt('maintenanceCalories', _maintenanceCalories);
    await prefs.setInt('weightLossCalories', _weightLossCalories);
    await prefs.setInt('weightGainCalories', _weightGainCalories);
  }

  Future<void> scheduleDelayedNotification(TimeOfDay targetTime) async {
    final now = DateTime.now();
    final targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      targetTime.hour,
      targetTime.minute,
    );

    final delay = targetDateTime.isBefore(now)
        ? targetDateTime.add(Duration(days: 1)).difference(now).inSeconds
        : targetDateTime.difference(now).inSeconds;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily notification to log meals and exercises',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await Future.delayed(Duration(seconds: delay), () async {
      while (true) {
        await notificationsPlugin.show(
          1,
          'Daily Reminder',
          'Don\'t forget to log your meals and exercises!',
          platformChannelSpecifics,
        );
        print('Notification sent!');
        await Future.delayed(Duration(hours: 24));
      }
    });
  }

  void _calculateCalories() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;

    final bmr = (10 * weight) + (6.25 * height) - 5;

    setState(() {
      _maintenanceCalories = bmr.round();
      _weightLossCalories = (bmr * 0.8).round();
      _weightGainCalories = (bmr * 1.2).round();
      
      _savedMaintenanceCalories = _maintenanceCalories;
      _savedWeightLossCalories = _weightLossCalories;
      _savedWeightGainCalories = _weightGainCalories;
    });

    _saveValues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculate Recommended Calories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        labelStyle: TextStyle(color: Colors.white70),
                        constraints: BoxConstraints(maxHeight: 60),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(color: Colors.white70),
                        constraints: BoxConstraints(maxHeight: 60),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculateCalories,
                child: Text('Calculate'),
              ),
              SizedBox(height: 24),
              if (_savedMaintenanceCalories > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weight Loss',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '$_savedWeightLossCalories cal',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maintenance',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '$_savedMaintenanceCalories cal',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weight Gain',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '$_savedWeightGainCalories cal',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 32),
              Text(
                'Set Daily Calorie Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Calorie Goal',
                  labelStyle: TextStyle(color: Colors.white70),
                  constraints: BoxConstraints(maxHeight: 60),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a calorie goal';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      int.parse(_goalController.text),
                    );
                  }
                },
                child: Text('Save Goal'),
              ),
              SizedBox(height: 32),
              Text(
                'Set Notification Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final targetTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (targetTime != null) {
                    setState(() {
                      selectedTime = targetTime;
                    });
                    await _saveTimerToCloud(targetTime);
                    scheduleDelayedNotification(targetTime);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notification set for ${targetTime.format(context)}',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Set Reminder'),
              ),
              if (selectedTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Daily reminder set for ${selectedTime!.format(context)}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
