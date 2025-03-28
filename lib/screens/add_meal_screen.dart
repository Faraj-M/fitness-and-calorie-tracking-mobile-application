import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMealScreen extends StatefulWidget {
  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  List<Map<String, dynamic>> tempFoodList = [];
  int totalCalories = 0;
  bool _isLoading = false;

  final Map<String, double> quickFoods = {
    'Eggs': 74.0,
    'Bananas': 105.0,
    'Apples': 95.0,
    'Oranges': 62.0,
    'Chicken Breast (100g)': 165.0,
    'Broccoli (100g)': 55.0,
    'Rice (1 cup cooked)': 200.0,
    'Oats (1/2 cup)': 150.0,
    'Almonds (1 oz)': 160.0,
    'Milk (1 cup)': 103.0,
    'Cheese (1 slice)': 113.0,
    'Peanut Butter (1 tbsp)': 90.0,
  };

  void _showQuickFoodsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) => ListView(
        children: quickFoods.entries.map((entry) {
          final food = entry.key;
          final calories = entry.value;
          String description = '';

          if (food == 'Chicken Breast (100g)') {
            description = 'A whole chicken breast is ~125g';
          } else if (food == 'Almonds (1 oz)') {
            description = '1 oz (~28g) is a small handful ~23 almonds';
          }

          return ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    food,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                if (description.isNotEmpty)
                  Flexible(
                    child: Text(
                      description,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              _showQuantityPicker(food, calories);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showQuantityPicker(String food, double caloriesPerUnit) {
    int selectedQuantity = 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Select quantity for $food',
          style: TextStyle(color: Colors.white),
        ),
        content: Container(
          height: 150,
          child: ListWheelScrollView(
            itemExtent: 50,
            diameterRatio: 1.2,
            physics: FixedExtentScrollPhysics(),
            children: List.generate(
              50,
              (index) => Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            onSelectedItemChanged: (index) {
              selectedQuantity = index + 1;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: Colors.purple)),
          ),
          TextButton(
            onPressed: () {
              final totalCaloriesForFood = caloriesPerUnit * selectedQuantity;
              setState(() {
                tempFoodList.add({
                  'name': '$selectedQuantity x $food',
                  'calories': totalCaloriesForFood.round()
                });
                totalCalories += totalCaloriesForFood.round();
              });
              Navigator.pop(context);
            },
            child: Text('Add', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCalories(String mealName) async {
    const String apiUrl = 'https://api.calorieninjas.com/v1/nutrition?query=';
    const String apiKey = 'zvJIFvPTqY8SPAUWnobgXQ==gFGUvJ4A9BRq2EqY'; // Replace with your actual API key

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiUrl$mealName'),
        headers: {'X-Api-Key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'].isNotEmpty) {
          final double calories = data['items'][0]['calories'] ?? 0.0;
          _caloriesController.text = calories.round().toString();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calories calculated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No calorie information found for "$mealName".')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch calorie information.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetFoods() {
    setState(() {
      tempFoodList.clear();
      totalCalories = 0;
    });
  }

  void _addFoodManually() {
    final mealName = _mealNameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());
    if (mealName.isNotEmpty && calories != null) {
      setState(() {
        tempFoodList.add({'name': mealName, 'calories': calories});
        totalCalories += calories;
      });
      _mealNameController.clear();
      _caloriesController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid meal name and calories.')),
      );
    }
  }

void _addMeal() async {
  String mealName = "Meal ${tempFoodList.length + 1}";

  _mealNameController.text = mealName;

  String? enteredName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Name your meal"),
      content: TextField(
        controller: _mealNameController,
        decoration: InputDecoration(hintText: "Enter meal name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _mealNameController.text),
          child: Text("Save"),
        ),
      ],
    ),
  );

  if (enteredName != null && enteredName.isNotEmpty) {
    Navigator.pop(
        context, {'name': enteredName, 'calories': totalCalories});
    _resetFoods();
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Meal')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Enter the meal name to calculate calories automatically or input manually.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),

              // Quick Foods Button and Description
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _showQuickFoodsMenu,
                    child: Text('Quick Foods'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Foods that are easy to count can quickly be added.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // "?" Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.help_outline, color: Colors.purple),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Example Inputs'),
                      content: Text(
                        'Try the following examples:\n\n'
                        '- chicken and rice\n'
                        '- Grilled chicken breast\n'
                        '- 14oz rib with mashed potatoes\n\n'
                        'Clicking "fetch" will search through CalorieNinjas\' API!',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Got it!'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Meal Name and Fetch Calories
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mealNameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Name of food(s)',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final mealName = _mealNameController.text.trim();
                      if (mealName.isNotEmpty) {
                        _fetchCalories(mealName);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a meal name.')),
                        );
                      }
                    },
                    child: Text('Fetch'),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Calories Input and Add Food Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Calories',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addFoodManually,
                    child: Text('Add Food'),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Food List
              Expanded(
                child: ListView.builder(
                  itemCount: tempFoodList.length,
                  itemBuilder: (context, index) {
                    final food = tempFoodList[index];
                    return ListTile(
                      title: Text(
                        food['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        '${food['calories']} cal',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),

              // Total Calories and Actions
              Column(
                children: [
                  Text(
                    'Total: $totalCalories cal',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _resetFoods,
                        child: Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: _addMeal,
                        child: Text('Add Meal'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
