import 'package:flutter/material.dart';

class PastDaysScreen extends StatefulWidget {
  final List<Map<String, dynamic>> days;
  final Function(Map<String, dynamic>) onLoadDay;
  final Function(Map<String, dynamic>) onDeleteDay;
  final Function(Map<String, dynamic>) onSaveToLocal;
  final Function(Map<String, dynamic>) onSaveToCloud;
  final Function() onSaveSpacePreset;
  final Function() onDownloadPastWeek;

  const PastDaysScreen({
    Key? key,
    required this.days,
    required this.onLoadDay,
    required this.onDeleteDay,
    required this.onSaveToLocal,
    required this.onSaveToCloud,
    required this.onSaveSpacePreset,
    required this.onDownloadPastWeek,
  }) : super(key: key);

  @override
  State<PastDaysScreen> createState() => _PastDaysScreenState();
}

class _PastDaysScreenState extends State<PastDaysScreen> {
  late List<Map<String, dynamic>> displayedDays;

 @override
void initState() {
  super.initState();
  displayedDays = List.from(widget.days);

  // sort chronologically by default
  displayedDays.sort((a, b) {
    final dateA = DateTime.parse(a['date']);
    final dateB = DateTime.parse(b['date']);
    return dateB.compareTo(dateA); // descending order
  });
}


  int _calculateLocalStorageUsage() {
    // Simulated size calculation for local days (e.g., 1MB per day)
    int localDaysCount = displayedDays.where((day) => day['isLocal'] == true).length;
    return localDaysCount * 1; // 1MB per day
  }

  void _sortDaysAscending() {
    setState(() {
      displayedDays.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateA.compareTo(dateB);
      });
    });
  }

  void _sortDaysDescending() {
    setState(() {
      displayedDays.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });
    });
  }

  void _sortByDownloaded() {
    setState(() {
      displayedDays.sort((a, b) {
        if (a['isLocal'] == b['isLocal']) {
          final dateA = DateTime.parse(a['date']);
          final dateB = DateTime.parse(b['date']);
          return dateA.compareTo(dateB);
        }
        return a['isLocal'] == true ? -1 : 1; // Local days first
      });
    });
  }

  void _showDeleteConfirmation(Map<String, dynamic> day) {
    final date = DateTime.parse(day['date']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Day'),
        content: Text('Are you sure you want to delete this day?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteDay(day);
              setState(() {
                displayedDays.removeWhere((d) => d['date'] == day['date']);
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Days'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Ascending') {
                _sortDaysAscending();
              } else if (value == 'Descending') {
                _sortDaysDescending();
              } else if (value == 'Downloaded') {
                _sortByDownloaded();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Ascending',
                child: Text('Sort by Date (Ascending)'),
              ),
              PopupMenuItem(
                value: 'Descending',
                child: Text('Sort by Date (Descending)'),
              ),
              PopupMenuItem(
                value: 'Downloaded',
                child: Text('Sort by Downloaded'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: displayedDays.length,
              itemBuilder: (context, index) {
                final day = displayedDays[index];
                final date = DateTime.parse(day['date']);
                final isLocal = day['isLocal'] == true; // Determine if the day is local

                return ListTile(
                  title: Text(
                    '${date.month}/${date.day}/${date.year}',
                    style: TextStyle(
                      color: isLocal ? Colors.purple : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Total Calories: ${day['totalCalories']}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isLocal ? Icons.cloud : Icons.download),
                        color: isLocal ? Colors.blue : Colors.purple,
                        onPressed: () {
                          if (isLocal) {
                            widget.onSaveToCloud(day);
                          } else {
                            widget.onSaveToLocal(day);
                          }
                          setState(() {
                            displayedDays[index]['isLocal'] = !isLocal;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(day),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: () {
                          widget.onLoadDay(day);
                          Navigator.pop(
                              context, {'date': day['date'], 'shouldRefresh': true});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            color: Colors.black54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '- Purple: Days saved locally.\n- Blue: Days saved on the cloud.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '${_calculateLocalStorageUsage()}MB used',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await widget.onSaveSpacePreset();
                        setState(() {
                          displayedDays.forEach((day) => day['isLocal'] = false);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Save Space Preset',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await widget.onDownloadPastWeek();
                        setState(() {
                          displayedDays.forEach((day) {
                            final date = DateTime.parse(day['date']);
                            if (date.isAfter(DateTime.now().subtract(Duration(days: 7)))) {
                              day['isLocal'] = true;
                            }
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Download Past Week',
                        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
