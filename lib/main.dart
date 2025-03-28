import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'package:sqflite/sqflite.dart';

// Initialize the notifications plugin
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialization with Error Handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  // Notification Settings Initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await notificationsPlugin.initialize(initializationSettings);

  // Request notification permissions
  await _requestNotificationPermissions();

  runApp(CalorieTrackingApp());
}

Future<void> _requestNotificationPermissions() async {
  final status = await Permission.notification.status;

  if (!status.isGranted) {
    final result = await Permission.notification.request();
    if (result.isGranted) {
      print("Notification permissions granted.");
    } else {
      print("Notification permissions denied.");
    }
  } else {
    print("Notification permissions are already granted.");
  }
}

class CalorieTrackingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      theme: AppTheme.lightTheme,
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
