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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 350,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Select a Category',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: availableCategories.map((category) {
                    final bool isAlreadyAdded = _categories.contains(category);
                    return ListTile(
                      leading: Icon(
                        isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                        color: isAlreadyAdded ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          color: isAlreadyAdded ? Colors.grey : Colors.black,
                          fontWeight: isAlreadyAdded ? FontWeight.w600 : FontWeight.normal,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Delete this preference?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _categories[index],
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _categories.removeAt(index);
                      });
                      _savePreferences();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Preference deleted")),
                      );
                    },
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel, color: Colors.black),
                    label: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'My Categories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _categories), // <-- Return updated preferences!
        ),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _addNewCategory(context),
                icon: const Icon(Icons.add, color: Color.fromARGB(255, 16, 16, 16)),
                label: const Text('Add New Category'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Selected Preferences',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _categories.isEmpty
                  ? Center(
                      child: Text(
                        "No categories added yet.",
                        style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onLongPress: () => _showDeleteDialog(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 65,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(Icons.label_important, color: Colors.red[400]),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _categories[index],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _categories),
              icon: const Icon(Icons.save),
              label: const Text('Save Preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
