import 'package:flutter/material.dart';

class MealsList extends StatelessWidget {
  final List<Map<String, String>> meals;
  final VoidCallback onAddMeal;
  final Function(String) onDeleteMeal;
  final ButtonStyle? style;

  const MealsList({
    Key? key,
    required this.meals,
    required this.onAddMeal,
    required this.onDeleteMeal,
    this.style,
  }) : super(key: key);

  void _showDeleteDialog(BuildContext context, String mealName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Meal'),
        content: Text('Are you sure you want to delete $mealName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close dialog
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              onDeleteMeal(mealName); // Trigger delete
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedMeals = [...meals];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.all(8.0),
      height: 200,
      child: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: onAddMeal,
              style: style?.copyWith(
                minimumSize: MaterialStateProperty.all(Size(120, 36)),
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ) ?? ButtonStyle(),
              child: Text('+ Add Meal'),
            ),
            ...combinedMeals.map((meal) {
              return GestureDetector(
                onLongPress: () => _showDeleteDialog(context, meal['name']!),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                  title: Text(meal['name']!, style: TextStyle(color: Colors.white)),
                  trailing: Text(meal['calories']!, style: TextStyle(color: Colors.white)),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
