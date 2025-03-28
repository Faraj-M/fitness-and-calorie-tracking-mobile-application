import 'package:flutter/material.dart';

class ExercisesList extends StatelessWidget {
  final List<Map<String, String>> exercises;
  final VoidCallback onAddExercise;
  final Function(String) onDeleteExercise;
  final ButtonStyle? style;

  const ExercisesList({
    Key? key,
    required this.exercises,
    required this.onAddExercise,
    required this.onDeleteExercise,
    this.style,
  }) : super(key: key);

  void _showDeleteDialog(BuildContext context, String exerciseName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Exercise'),
        content: Text('Are you sure you want to delete $exerciseName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteExercise(exerciseName);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedExercises = [...exercises];

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
              onPressed: onAddExercise,
              style: style?.copyWith(
                minimumSize: MaterialStateProperty.all(Size(120, 36)),
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ) ?? ButtonStyle(),
              child: Text('+ Add Exercise'),
            ),
            ...combinedExercises.map((exercise) {
              return GestureDetector(
                onLongPress: () => _showDeleteDialog(context, exercise['name']!),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                  title: Text(exercise['name']!, style: TextStyle(color: Colors.white)),
                  trailing: Text(exercise['calories']!, style: TextStyle(color: Colors.white)),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
