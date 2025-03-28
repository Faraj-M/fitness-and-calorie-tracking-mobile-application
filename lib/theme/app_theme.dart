import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
      ),
    );
  }
}
