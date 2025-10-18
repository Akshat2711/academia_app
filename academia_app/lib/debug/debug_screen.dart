import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsDebugScreen extends StatefulWidget {
  const SharedPrefsDebugScreen({super.key});

  @override
  State<SharedPrefsDebugScreen> createState() => _SharedPrefsDebugScreenState();
}

class _SharedPrefsDebugScreenState extends State<SharedPrefsDebugScreen> {
  Map<String, Object?> _prefsData = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, Object?> data = {};
    for (var key in keys) {
      data[key] = prefs.get(key);
    }
    setState(() {
      _prefsData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the color scheme
    const Color primaryBlack = Colors.black;
    const Color accentRed = Color(0xFFE50000); // A bright, deep red
    const Color cardBlack = Color.fromARGB(255, 15, 15, 15); // Slightly lighter black for card background
    const Color valueWhite = Colors.white70;

    return Scaffold(
      backgroundColor: primaryBlack, // Set background to black
      appBar: AppBar(
        title: const Text(
          'SharedPreferences Debug',
          style: TextStyle(color: accentRed), // Title in red
        ),
        backgroundColor: primaryBlack,
        elevation: 0, // Flat app bar
        iconTheme: const IconThemeData(color: accentRed), // Back button in red
      ),
      body: _prefsData.isEmpty
          ? const Center(
              child: Text(
                'No data stored',
                style: TextStyle(color: valueWhite),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: _prefsData.entries.map((e) {
                return Card(
                  // Use a slightly lighter black for the card to give contrast
                  color: cardBlack, 
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: accentRed, width: 1), // Red border for emphasis
                  ),
                  child: ListTile(
                    title: Text(
                      e.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentRed, // Key in red
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        e.value.toString(),
                        style: const TextStyle(
                          color: valueWhite, // Value in white/grey
                          fontFamily: 'monospace', // Use a monospaced font for data if possible
                          fontSize: 14,
                        ),
                      ),
                    ),
                    dense: true,
                  ),
                );
              }).toList(),
            ),
    );
  }
}