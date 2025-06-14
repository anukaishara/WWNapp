import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  List<String> _categories = [];
  List<String> selectedPreferences = [];

  final List<String> availableCategories = [
    'Local-Top',
    'Local-Business',
    'Local-Sports',
    'Local-Entertainment',
    'Local-Technology',
    'Foreign-Top',
    'Foreign-Business',
    'Foreign-Sports',
    'Foreign-Entertainment',
    'Foreign-Technology',
    'Foreign-Politics',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPreferences = prefs.getStringList('userPreferences') ?? [];
      _categories = List.from(selectedPreferences);
    });
  }

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('userPreferences', _categories);
  }

  void _addNewCategory(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select a Category'),
          children: availableCategories.map((category) {
            final bool isAlreadyAdded = _categories.contains(category);
            return ListTile(
              title: Text(
                category,
                style: TextStyle(
                  color: isAlreadyAdded ? Colors.grey : Colors.black,
                ),
              ),
              enabled: !isAlreadyAdded,
              onTap: () {
                if (!isAlreadyAdded) {
                  setState(() {
                    _categories.add(category);
                  });
                  _savePreferences();
                }
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showDeleteDialog(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  'Delete the preference?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                      setState(() {
                        _categories.removeAt(index);
                      });
                      _savePreferences();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Preference deleted")),
                      );
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context); // Just close the bottom sheet
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'My Categories',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () {
                    _addNewCategory(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add new Categories'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Selected Preferences:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _categories.isEmpty
                  ? const Center(
                      child: Text(
                        "No categories added yet.",
                        style: TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showDeleteDialog(index),
                          child: SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _categories[index],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
