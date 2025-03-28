import 'package:flutter/material.dart';

// Displays the calorie progress circle with current calories and goal
class CalorieTrackerCircle extends StatelessWidget {
  final int calorieGoal;
  final int caloriesNet;

  CalorieTrackerCircle({required this.calorieGoal, required this.caloriesNet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator showing calorie progress
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: (caloriesNet / calorieGoal).clamp(0.0, 1.0),
              strokeWidth: 20,
              color: Color(0xFF0FFE6F),
              backgroundColor: Colors.grey.shade800,
            ),
          ),
          // Display calories and label
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$caloriesNet',
                style: TextStyle(
                  color: Color(0xFF00D1FF),
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total Calories',
                style: TextStyle(
                  color: Color(0xFFE38004),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
